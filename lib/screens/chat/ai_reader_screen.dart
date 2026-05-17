import 'dart:convert';
import 'package:ai_voice_chat/config/api_keys.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class AiReaderScreen extends StatefulWidget {
  const AiReaderScreen({super.key});
  @override
  State<AiReaderScreen> createState() => _AiReaderScreenState();
}

class _AiReaderScreenState extends State<AiReaderScreen> {
  static const String _groqApiKey = openAiKey;
  static const String _groqUrl =
      'https://api.openai.com/v1/chat/completions';

  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextRecognizer _textRecognizer = TextRecognizer();

  File? _selectedFile;
  String _fileName = '';
  String _fileType = '';
  String _extractedText = '';
  String _summary = '';
  bool _isSummarizing = false;
  bool _isAnswering = false;
  bool _isExtracting = false;
  String _statusText = '';

  final List<Map<String, String>> _chatHistory = [];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        final file = File(result.files.first.path!);
        setState(() {
          _selectedFile = file;
          _fileName = result.files.first.name;
          _fileType = 'pdf';
          _extractedText = '';
          _summary = '';
          _chatHistory.clear();
          _statusText = 'PDF loaded! Extracting text...';
        });
        await _extractTextFromPdf(file);
      }
    } catch (e) {
      setState(() => _statusText = 'Error picking file: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1C2229),
          title: const Text(
            'Select Image Source',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImageSource.camera),
              child: const Text(
                'Camera',
                style: TextStyle(color: Color(0xFF4FD8EB)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
              child: const Text(
                'Gallery',
                style: TextStyle(color: Color(0xFF4FD8EB)),
              ),
            ),
          ],
        ),
      );
      if (source == null) return;
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _fileName = pickedFile.name;
          _fileType = 'image';
          _extractedText = '';
          _summary = '';
          _chatHistory.clear();
          _statusText = 'Image loaded! Extracting text via OCR...';
        });
        await _extractTextFromImage(File(pickedFile.path));
      }
    } catch (e) {
      setState(() => _statusText = 'Error picking image: $e');
    }
  }

  Future<void> _extractTextFromPdf(File file) async {
    setState(() {
      _isExtracting = true;
      _statusText = 'Reading PDF...';
    });
    try {
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      setState(() => _statusText = 'Processing $pageCount pages...');
      final StringBuffer buffer = StringBuffer();
      for (int i = 0; i < pageCount && i < 15; i++) {
        setState(() => _statusText = 'Reading page ${i + 1} of $pageCount...');
        try {
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          final String pageText = extractor.extractText(
            startPageIndex: i,
            endPageIndex: i,
          );
          if (pageText.trim().isNotEmpty) {
            buffer.writeln('--- Page ${i + 1} ---');
            buffer.writeln(pageText.trim());
            buffer.writeln();
          }
        } catch (pageError) {
          debugPrint('Error on page ${i + 1}: $pageError');
        }
      }
      document.dispose();
      final String fullText = buffer.toString().trim();
      setState(() {
        _extractedText = fullText.length > 10000
            ? fullText.substring(0, 10000)
            : fullText;
        _isExtracting = false;
        _statusText = _extractedText.isNotEmpty
            ? 'Text extracted ✅ ${_extractedText.split(' ').length} words found. Tap Summarize!'
            : 'No digital text found. Try Upload Image instead.';
      });
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _statusText = 'Error reading PDF: $e';
      });
    }
  }

  Future<void> _extractTextFromImage(File imageFile) async {
    setState(() {
      _isExtracting = true;
      _statusText = 'Running OCR on image...';
    });
    try {
      final recognizedText = await _textRecognizer.processImage(
        InputImage.fromFile(imageFile),
      );
      setState(() {
        _extractedText = recognizedText.text.trim();
        _isExtracting = false;
        _statusText = _extractedText.isNotEmpty
            ? 'Text extracted via OCR ✅ ${_extractedText.split(' ').length} words found. Tap Summarize!'
            : 'No text found in image. Please try a clearer image.';
      });
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _statusText = 'OCR Error: $e';
      });
    }
  }

  Future<void> _summarize() async {
    if (_selectedFile == null) return;
    setState(() {
      _isSummarizing = true;
      _summary = '';
      _statusText = 'Analyzing with ADAM AI...';
    });
    try {
      final userMessage = _extractedText.isNotEmpty
          ? 'Please analyze and summarize the following document content thoroughly. Provide a well-structured summary with:\n1. **Main Topic/Purpose** - What is this document about?\n2. **Key Points** - List the most important information\n3. **Important Details** - Any specific data, dates, names mentioned\n4. **Conclusion** - Overall takeaway\n\nDocument: "$_fileName"\n\nContent:\n\n$_extractedText'
          : 'I have a document named "$_fileName" ($_fileType file) but could not extract its text content. Please let the user know and suggest alternatives.';
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are ADAM, an expert AI document analyzer. Analyze documents thoroughly and provide clear, accurate, structured summaries based ONLY on the actual content provided. Format your response with proper headings and bullet points.',
            },
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 1500,
          'temperature': 0.2,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summaryText = data['choices'][0]['message']['content'] as String;
        _chatHistory.clear();
        _chatHistory.add({
          'role': 'system',
          'content':
              'You are ADAM, analyzing document "$_fileName". Here is the EXACT document content:\n\n$_extractedText\n\nAnswer ALL questions based ONLY on this document content. If something is not in the document, say so clearly.',
        });
        setState(() {
          _summary = summaryText.trim();
          _isSummarizing = false;
          _statusText = 'Summary complete ✅';
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients)
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
        });
      } else {
        setState(() {
          _isSummarizing = false;
          _statusText = 'Failed to summarize. Try again!';
        });
      }
    } catch (e) {
      setState(() {
        _isSummarizing = false;
        _statusText = 'Error: Check your internet connection';
      });
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _selectedFile == null) return;
    setState(() {
      _isAnswering = true;
      _statusText = 'Finding answer...';
    });
    _chatHistory.add({'role': 'user', 'content': question});
    _questionController.clear();
    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': List<Map<String, dynamic>>.from(_chatHistory),
          'max_tokens': 800,
          'temperature': 0.2,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _chatHistory.add({
          'role': 'assistant',
          'content': (data['choices'][0]['message']['content'] as String)
              .trim(),
        });
        setState(() {
          _isAnswering = false;
          _statusText = 'Answer ready ✅';
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients)
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
        });
      } else {
        _chatHistory.removeLast();
        setState(() {
          _isAnswering = false;
          _statusText = 'Failed to get answer. Try again!';
        });
      }
    } catch (e) {
      _chatHistory.removeLast();
      setState(() {
        _isAnswering = false;
        _statusText = 'Error: Check your internet connection';
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color accentCyan = Color(0xFF4FD8EB);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Text(
                          "AI Reader",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Text(
                        "Upload • Analyze • Ask",
                        style: GoogleFonts.jetBrainsMono(
                          color: accentCyan,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Upload buttons ──
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickFile,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: accentCyan.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: accentCyan.withOpacity(0.4),
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      color: Color(0xFF4FD8EB),
                                      size: 28,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "Upload PDF",
                                      style: TextStyle(
                                        color: Color(0xFF4FD8EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Digital & Scanned",
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purpleAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.purpleAccent.withOpacity(0.4),
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      color: Colors.purpleAccent,
                                      size: 28,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "Upload Image",
                                      style: TextStyle(
                                        color: Colors.purpleAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "OCR Text Extraction",
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── File info ──
                      if (_selectedFile != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _fileType == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : Icons.image,
                                color: _fileType == 'pdf'
                                    ? accentCyan
                                    : Colors.purpleAccent,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fileName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _fileType.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isExtracting)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF4FD8EB),
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: _isSummarizing ? null : _summarize,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentCyan,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: _isSummarizing
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            "Summarize",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // ── Image preview ──
                      if (_selectedFile != null && _fileType == 'image') ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _selectedFile!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],

                      // ── Extracted text info ──
                      if (_extractedText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_extractedText.split(' ').length} words extracted successfully',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Status ──
                      if (_statusText.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _statusText,
                          style: TextStyle(
                            color: _statusText.contains('✅')
                                ? Colors.greenAccent
                                : _statusText.contains('Error') ||
                                      _statusText.contains('Failed') ||
                                      _statusText.contains('No ')
                                ? Colors.redAccent
                                : Colors.orange,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      // ── Summary ──
                      if (_summary.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accentCyan.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentCyan.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.summarize,
                                    color: Color(0xFF4FD8EB),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Document Summary",
                                    style: GoogleFonts.inter(
                                      color: accentCyan,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _summary,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Q&A history ──
                      if (_chatHistory.length > 1) ...[
                        const SizedBox(height: 16),
                        Text(
                          "Q&A",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._chatHistory.where((m) => m['role'] != 'system').map(
                          (msg) {
                            final isUser = msg['role'] == 'user';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? accentCyan.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isUser
                                      ? accentCyan.withOpacity(0.3)
                                      : Colors.white12,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isUser
                                        ? Icons.person
                                        : Icons.smart_toy_outlined,
                                    color: isUser ? accentCyan : Colors.white54,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      msg['content'] ?? '',
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // ── Question input ──
              if (_summary.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _questionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ask a question about the document...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _askQuestion(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isAnswering ? null : _askQuestion,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4FD8EB),
                            shape: BoxShape.circle,
                          ),
                          child: _isAnswering
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.black,
                                  size: 18,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

