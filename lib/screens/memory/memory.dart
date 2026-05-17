import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();

  late TabController _viewTabController;
  late TabController _filterTabController;

  String _searchQuery = '';
  String _selectedFilter = 'All';
  int _viewIndex = 0;

  final Set<String> _expandedGroups = {
    'Today',
    'Yesterday',
    'This Week',
    'Older',
  };
  final List<String> _filters = ['All', 'Chat', 'Voice', 'Translation'];

  // FIX 4: Include all possible types + empty type
  static const List<String> _validTypes = ['chat', 'voice', 'translation'];

  String? _selectedNodeId;
  late AnimationController _nodeAnimCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 2, vsync: this);
    _viewTabController.addListener(() {
      if (!_viewTabController.indexIsChanging) {
        setState(() => _viewIndex = _viewTabController.index);
      }
    });
    _filterTabController = TabController(length: _filters.length, vsync: this);
    _filterTabController.addListener(() {
      if (!_filterTabController.indexIsChanging) {
        setState(() => _selectedFilter = _filters[_filterTabController.index]);
      }
    });
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
    _nodeAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    _filterTabController.dispose();
    _searchController.dispose();
    _nodeAnimCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'voice':
        return Icons.mic_none_rounded;
      case 'translation':
        return Icons.translate_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'voice':
        return const Color(0xFF8B5CF6);
      case 'translation':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF4FD8EB);
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'voice':
        return 'Voice';
      case 'translation':
        return 'Translation';
      default:
        return 'Chat';
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getGroupLabel(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return 'This Week';
    return 'Older';
  }

  // FIX 1: Use doc.id consistently, not data['id']
  String _getDocId(QueryDocumentSnapshot doc) => doc.id;

  // FIX 4: Accept docs with any type or missing type as 'chat'
  String _normalizeType(Map<String, dynamic> data) {
    final t = data['type'] as String? ?? '';
    if (_validTypes.contains(t)) return t;
    return 'chat'; // default unknown types to chat
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> all) {
    // FIX 4: Don't discard docs with missing/unknown type
    var docs = List<QueryDocumentSnapshot>.from(all);

    docs.sort((a, b) {
      final aTs = (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
      final bTs = (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return bTs.compareTo(aTs);
    });

    if (_selectedFilter != 'All') {
      docs = docs.where((d) {
        final t = _normalizeType(d.data() as Map<String, dynamic>);
        return t == _selectedFilter.toLowerCase();
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      docs = docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final title = (data['title'] as String? ?? '').toLowerCase();
        final preview = (data['lastMessage'] as String? ?? '').toLowerCase();
        return title.contains(_searchQuery) || preview.contains(_searchQuery);
      }).toList();
    }

    return docs;
  }

  // ── Delete ──
  Future<void> _deleteSession(String sessionId) async {
    if (_uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Memory',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Remove this session from memory? This cannot be undone.',
          style: TextStyle(color: Colors.white54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final msgs = await _db
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .get();
      final batch = _db.batch();
      for (final doc in msgs.docs) batch.delete(doc.reference);
      batch.delete(
        _db.collection('users').doc(_uid).collection('sessions').doc(sessionId),
      );
      await batch.commit();
      if (mounted)
        setState(() {
          if (_selectedNodeId == sessionId) _selectedNodeId = null;
        });
      Get.snackbar(
        'Deleted',
        'Memory removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not delete.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _clearAllMemories() async {
    if (_uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear All Memories',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete ALL sessions.',
          style: TextStyle(color: Colors.white54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final sessions = await _db
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .get();
      final batch = _db.batch();
      for (final session in sessions.docs) {
        final msgs = await session.reference.collection('messages').get();
        for (final msg in msgs.docs) batch.delete(msg.reference);
        batch.delete(session.reference);
      }
      await batch.commit();
      if (mounted) setState(() => _selectedNodeId = null);
      Get.snackbar(
        'Cleared',
        'All memories wiped',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not clear memories.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accentCyan = Color(0xFF4FD8EB);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A0E1A), Color(0xFF000000)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    // FIX 5: goHome instead of Get.back() to avoid popping dashboard
                    IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          try {
                            final ctrl = Get.find<dynamic>(tag: 'dashboard');
                            ctrl.selectedIndex.value = 0;
                          } catch (_) {}
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ADAM's Memory",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "Chat  ·  Voice  ·  Translation",
                            style: GoogleFonts.jetBrainsMono(
                              color: accentCyan,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearAllMemories,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_sweep,
                              color: Colors.redAccent,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Clear All',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Stats ──
              if (_uid != null)
                StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('users')
                      .doc(_uid)
                      .collection('sessions')
                      .snapshots(),
                  builder: (_, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    // FIX 4: Count all docs, not just known types
                    final chatCount = docs
                        .where(
                          (d) =>
                              _normalizeType(
                                d.data() as Map<String, dynamic>,
                              ) ==
                              'chat',
                        )
                        .length;
                    final voiceCount = docs
                        .where(
                          (d) =>
                              _normalizeType(
                                d.data() as Map<String, dynamic>,
                              ) ==
                              'voice',
                        )
                        .length;
                    final transCount = docs
                        .where(
                          (d) =>
                              _normalizeType(
                                d.data() as Map<String, dynamic>,
                              ) ==
                              'translation',
                        )
                        .length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _statCard(
                            Icons.chat_bubble_outline_rounded,
                            '$chatCount',
                            'Chats',
                            accentCyan,
                          ),
                          const SizedBox(width: 8),
                          _statCard(
                            Icons.mic_none_rounded,
                            '$voiceCount',
                            'Voice',
                            const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 8),
                          _statCard(
                            Icons.translate_rounded,
                            '$transCount',
                            'Translate',
                            const Color(0xFF22C55E),
                          ),
                          const SizedBox(width: 8),
                          _statCard(
                            Icons.storage_rounded,
                            '${docs.length}',
                            'Total',
                            Colors.orangeAccent,
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 10),

              // ── View Toggle ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _viewTabController,
                    indicator: BoxDecoration(
                      color: accentCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentCyan.withOpacity(0.5)),
                    ),
                    labelColor: accentCyan,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hub_rounded, size: 14),
                            SizedBox(width: 6),
                            Text('Universe'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_tree_rounded, size: 14),
                            SizedBox(width: 6),
                            Text('Timeline'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Search + Filter (Timeline only) ──
              if (_viewIndex == 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(
                            Icons.search_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search memories...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.clear,
                                color: Colors.white38,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _filterTabController,
                      indicator: BoxDecoration(
                        color: accentCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentCyan.withOpacity(0.5)),
                      ),
                      labelColor: accentCyan,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
                      dividerColor: Colors.transparent,
                      tabs: _filters.map((f) => Tab(text: f)).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── Content ──
              Expanded(
                child: _uid == null
                    ? const Center(
                        child: Text(
                          'Not logged in',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('users')
                            .doc(_uid)
                            .collection('sessions')
                            .snapshots(),
                        builder: (_, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4FD8EB),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.white54),
                              ),
                            );
                          }
                          final allDocs = snapshot.data?.docs ?? [];
                          final docs = _filterDocs(allDocs);

                          if (docs.isEmpty) return _buildEmptyState();

                          return _viewIndex == 0
                              ? _buildUniverseView(allDocs, docs)
                              : _buildTimelineView(docs);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // ── UNIVERSE VIEW ──
  // ══════════════════════════════════════════════
  Widget _buildUniverseView(
    List<QueryDocumentSnapshot> allDocs,
    List<QueryDocumentSnapshot> _,
  ) {
    if (allDocs.isEmpty) return _buildEmptyState();

    Map<String, dynamic>? selectedData;
    String? selectedDocId;
    if (_selectedNodeId != null) {
      // FIX 1: match by doc.id directly
      try {
        final match = allDocs.firstWhere((d) => d.id == _selectedNodeId);
        selectedData = match.data() as Map<String, dynamic>;
        selectedDocId = match.id;
      } catch (_) {}
    }

    return Column(
      children: [
        Expanded(
          flex: selectedData != null ? 6 : 10,
          child: AnimatedBuilder(
            animation: Listenable.merge([_nodeAnimCtrl, _pulseCtrl]),
            builder: (_, __) => Stack(
              children: [
                CustomPaint(
                  // FIX 2: Pass animValue snapshot to painter
                  painter: _UniversePainter(
                    docs: allDocs,
                    selectedId: _selectedNodeId,
                    animValue: _nodeAnimCtrl.value,
                    pulseValue: _pulseAnim.value,
                  ),
                  child: const SizedBox.expand(),
                ),
                // FIX 2: Tap detector uses same animValue
                _UniverseTapDetector(
                  docs: allDocs,
                  animValue: _nodeAnimCtrl.value,
                  onTap: (id) => setState(
                    () => _selectedNodeId = _selectedNodeId == id ? null : id,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF4FD8EB), 'Chat'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF8B5CF6), 'Voice'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF22C55E), 'Translation'),
            ],
          ),
        ),

        // Selected node card
        if (selectedData != null && selectedDocId != null)
          _buildNodeDetailCard(selectedData, selectedDocId),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildNodeDetailCard(Map<String, dynamic> data, String sessionId) {
    final type = _normalizeType(data);
    // FIX 3: Better title fallback
    final title = (data['title'] as String? ?? '').isNotEmpty
        ? data['title'] as String
        : (data['lastMessage'] as String? ?? '').isNotEmpty
        ? (data['lastMessage'] as String).length > 40
              ? '${(data['lastMessage'] as String).substring(0, 40)}...'
              : data['lastMessage'] as String
        : 'Session ${sessionId.substring(0, 6)}';
    // FIX 6: Read messageCount OR fallback to messages subcollection
    final msgCount =
        data['messageCount'] as int? ?? data['messages_count'] as int? ?? 0;
    final updatedAt = data['updatedAt'] as Timestamp?;
    final date = updatedAt != null ? _formatDate(updatedAt.toDate()) : '';
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);
    final label = _getTypeLabel(type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _deleteSession(sessionId),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          if (msgCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.message_outlined,
                  color: color.withOpacity(0.5),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '$msgCount message${msgCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (type == 'voice') {
                Get.toNamed('/voice', arguments: {'sessionId': sessionId});
              } else if (type == 'translation') {
                Get.toNamed(
                  '/translation',
                  arguments: {'sessionId': sessionId},
                );
              } else {
                Get.toNamed('/chat', arguments: {'sessionId': sessionId});
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    type == 'translation'
                        ? 'Open Translation'
                        : 'Continue Session',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // ── TIMELINE VIEW ──
  // ══════════════════════════════════════════════
  Widget _buildTimelineView(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};
    const groupOrder = ['Today', 'Yesterday', 'This Week', 'Older'];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['updatedAt'] as Timestamp?;
      final date = ts != null ? ts.toDate() : DateTime.now();
      grouped.putIfAbsent(_getGroupLabel(date), () => []).add(doc);
    }

    if (grouped.isEmpty) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      children: groupOrder.where((g) => grouped.containsKey(g)).map((group) {
        final groupDocs = grouped[group]!;
        final isExpanded = _expandedGroups.contains(group);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() {
                isExpanded
                    ? _expandedGroups.remove(group)
                    : _expandedGroups.add(group);
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6, top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.folder_outlined,
                      color: Colors.white38,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      group,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${groupDocs.length}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              ...groupDocs.asMap().entries.map((entry) {
                final doc = entry.value;
                final isLast = entry.key == groupDocs.length - 1;
                // FIX 1: use doc.id
                final sessionId = doc.id;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 24,
                        child: CustomPaint(
                          painter: _TreeLinePainter(isLast: isLast),
                        ),
                      ),
                      Expanded(
                        child: _buildMemoryItem(
                          doc.data() as Map<String, dynamic>,
                          sessionId,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 4),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMemoryItem(Map<String, dynamic> data, String sessionId) {
    final type = _normalizeType(data);
    // FIX 3: Better title fallback
    final rawTitle = data['title'] as String? ?? '';
    final lastMsg = data['lastMessage'] as String? ?? '';
    final title = rawTitle.isNotEmpty
        ? rawTitle
        : lastMsg.isNotEmpty
        ? (lastMsg.length > 35 ? '${lastMsg.substring(0, 35)}...' : lastMsg)
        : 'Session ${sessionId.substring(0, 6)}';
    // FIX 6: messageCount fallback
    final msgCount =
        data['messageCount'] as int? ?? data['messages_count'] as int? ?? 0;
    final updatedAt = data['updatedAt'] as Timestamp?;
    final date = updatedAt != null ? _formatDate(updatedAt.toDate()) : '';
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);
    final label = _getTypeLabel(type);

    return Dismissible(
      key: Key('tl_$sessionId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await _deleteSession(sessionId);
        return false;
      },
      child: GestureDetector(
        onTap: () {
          if (type == 'voice') {
            Get.toNamed('/voice', arguments: {'sessionId': sessionId});
          } else if (type == 'translation') {
            Get.toNamed('/translation', arguments: {'sessionId': sessionId});
          } else {
            Get.toNamed('/chat', arguments: {'sessionId': sessionId});
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _deleteSession(sessionId),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white24,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (msgCount > 0) ...[
                    Icon(
                      Icons.message_outlined,
                      color: color.withOpacity(0.4),
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$msgCount msg${msgCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'Open',
                    style: TextStyle(
                      color: color.withOpacity(0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color.withOpacity(0.4),
                    size: 9,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.6), fontSize: 8),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String msg = 'No memories yet';
    String sub = 'Start a session to build memory';
    if (_searchQuery.isNotEmpty) {
      msg = 'No results';
      sub = 'Try a different search term';
    } else if (_selectedFilter != 'All') {
      msg = 'No $_selectedFilter sessions';
      sub = 'Start a ${_selectedFilter.toLowerCase()} session';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storage_rounded, color: Colors.white12, size: 60),
          const SizedBox(height: 16),
          Text(
            msg,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: const TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── Universe Graph Painter ──
// FIX 1 & 2: Use doc.id, remove onNodeTap from painter
// ══════════════════════════════════════════════
class _UniversePainter extends CustomPainter {
  final List<QueryDocumentSnapshot> docs;
  final String? selectedId;
  final double animValue;
  final double pulseValue;

  const _UniversePainter({
    required this.docs,
    required this.selectedId,
    required this.animValue,
    required this.pulseValue,
  });

  Color _colorForType(String type) {
    switch (type) {
      case 'voice':
        return const Color(0xFF8B5CF6);
      case 'translation':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF4FD8EB);
    }
  }

  // FIX 1: Compute positions using doc.id
  static Map<String, Offset> computePositions(
    List<QueryDocumentSnapshot> docs,
    Size size,
    double animValue,
  ) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final positions = <String, Offset>{'__core__': Offset(cx, cy)};

    final chatDocs = docs
        .where((d) => (d.data() as Map)['type'] == 'chat')
        .toList();
    final voiceDocs = docs
        .where((d) => (d.data() as Map)['type'] == 'voice')
        .toList();
    final transDocs = docs
        .where((d) => (d.data() as Map)['type'] == 'translation')
        .toList();
    // Also handle unlabeled
    final otherDocs = docs.where((d) {
      final t = (d.data() as Map)['type'] as String? ?? '';
      return !['chat', 'voice', 'translation'].contains(t);
    }).toList();
    final allChat = [...chatDocs, ...otherDocs];

    void placeGroup(
      List<QueryDocumentSnapshot> group,
      double radius,
      double startAngle,
    ) {
      for (int i = 0; i < group.length; i++) {
        final id = group[i].id; // FIX 1: use doc.id
        final angle =
            startAngle +
            (i / max(group.length, 1)) * 2 * pi +
            animValue * 0.15 * pi;
        final wobble = sin(animValue * 2 * pi + i * 0.8) * 6;
        positions[id] = Offset(
          cx + cos(angle) * (radius + wobble),
          cy + sin(angle) * (radius * 0.72 + wobble),
        );
      }
    }

    placeGroup(allChat, size.width * 0.27, 0);
    placeGroup(voiceDocs, size.width * 0.37, pi / 3);
    placeGroup(transDocs, size.width * 0.43, 2 * pi / 3);
    return positions;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (docs.isEmpty) return;
    final positions = computePositions(docs, size, animValue);
    final corePos = positions['__core__']!;

    // Lines: core → nodes
    for (final doc in docs) {
      final id = doc.id;
      if (!positions.containsKey(id)) continue;
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String? ?? 'chat';
      final color = _colorForType(type);
      canvas.drawLine(
        corePos,
        positions[id]!,
        Paint()
          ..color = color.withOpacity(0.1)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    // Core node
    final coreR = 18.0 + pulseValue * 4;
    canvas.drawCircle(
      corePos,
      coreR + 12,
      Paint()
        ..color = const Color(0xFF4FD8EB).withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawCircle(
      corePos,
      coreR,
      Paint()..color = const Color(0xFF4FD8EB).withOpacity(0.9),
    );
    canvas.drawCircle(
      corePos,
      coreR + 6,
      Paint()
        ..color = const Color(0xFF4FD8EB).withOpacity(0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    final coreTP = TextPainter(
      text: const TextSpan(
        text: 'ADAM',
        style: TextStyle(
          color: Colors.black,
          fontSize: 6,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    coreTP.paint(canvas, corePos - Offset(coreTP.width / 2, coreTP.height / 2));

    // Session nodes
    for (final doc in docs) {
      final id = doc.id;
      if (!positions.containsKey(id)) continue;
      final pos = positions[id]!;
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String? ?? 'chat';
      final title = data['title'] as String? ?? '';
      final color = _colorForType(type);
      final isSelected = selectedId == id;
      final nodeR = isSelected ? 15.0 + pulseValue * 3 : 11.0;

      if (isSelected) {
        canvas.drawCircle(
          pos,
          nodeR + 10,
          Paint()
            ..color = color.withOpacity(0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      canvas.drawCircle(
        pos,
        nodeR,
        Paint()..color = isSelected ? color : color.withOpacity(0.75),
      );
      canvas.drawCircle(
        pos,
        nodeR,
        Paint()
          ..color = isSelected
              ? Colors.white.withOpacity(0.7)
              : color.withOpacity(0.35)
          ..strokeWidth = isSelected ? 2 : 1
          ..style = PaintingStyle.stroke,
      );

      final shortTitle = title.length > 9 ? '${title.substring(0, 9)}…' : title;
      final tp = TextPainter(
        text: TextSpan(
          text: shortTitle.isEmpty ? id.substring(0, 4) : shortTitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 7.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      tp.paint(canvas, pos + Offset(-tp.width / 2, nodeR + 3));
    }
  }

  @override
  bool shouldRepaint(_UniversePainter old) =>
      old.animValue != animValue ||
      old.selectedId != selectedId ||
      old.pulseValue != pulseValue;

  @override
  bool? hitTest(Offset position) => true;
}

// FIX 2: Tap detector uses same computePositions — no drift
class _UniverseTapDetector extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final double animValue;
  final Function(String) onTap;

  const _UniverseTapDetector({
    required this.docs,
    required this.animValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final size = context.size;
        if (size == null) return;
        // FIX 2: Use same function as painter
        final positions = _UniversePainter.computePositions(
          docs,
          size,
          animValue,
        );
        for (final entry in positions.entries) {
          if (entry.key == '__core__') continue;
          if ((details.localPosition - entry.value).distance <= 22) {
            onTap(entry.key); // entry.key is doc.id
            return;
          }
        }
      },
      child: const SizedBox.expand(),
    );
  }
}

class _TreeLinePainter extends CustomPainter {
  final bool isLast;
  const _TreeLinePainter({required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, isLast ? size.height / 2 : size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TreeLinePainter old) => old.isLast != isLast;
}

