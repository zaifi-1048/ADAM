const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const { GoogleGenerativeAI } = require("@google/generative-ai");

setGlobalOptions({ maxInstances: 10 });
const genAI = new GoogleGenerativeAI("AIzaSyCg4qI-uBbGjE6EOd5D835pUmZ33gLK_G8");

exports.chat = onRequest(async (request, response) => {
    // Allow cross-origin requests
    response.set("Access-Control-Allow-Origin", "*");
    response.set("Access-Control-Allow-Methods", "POST");
    response.set("Access-Control-Allow-Headers", "Content-Type");

    if (request.method === "OPTIONS") {
        response.status(204).send("");
        return;
    }

    try {
        const { message, history } = request.body;

        if (!message) {
            response.status(400).json({ error: "Message is required" });
            return;
        }

        logger.info("Chat request received", { message });

        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

        const chat = model.startChat({
            history: history || [],
            generationConfig: {
                maxOutputTokens: 1000,
            },
        });

        const result = await chat.sendMessage(message);
        const text = result.response.text();

        logger.info("Gemini response", { text });

        response.status(200).json({
            response: text,
            success: true
        });

    } catch (error) {
        logger.error("Error calling Gemini", error);
        response.status(500).json({
            error: "Failed to get AI response",
            details: error.message
        });
    }
});
