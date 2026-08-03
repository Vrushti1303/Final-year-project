const { GoogleGenerativeAI } = require('@google/generative-ai');

const getGenerativeModel = (modelName = "gemini-3.6-flash") => {
    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'your_gemini_api_key_here') {
        throw new Error("GEMINI_API_KEY is not configured.");
    }
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    return genAI.getGenerativeModel({ model: modelName });
}

exports.analyzeContract = async (text) => {
    const model = getGenerativeModel();
    const prompt = `
        You are a legal expert in Indian property laws, specifically RERA. 
        Analyze the following real estate contract text.
        Identify clauses and categorize them into:
        - "Green": Standard clauses that are safe and normal.
        - "Yellow": Missing protections or slightly ambiguous terms.
        - "Red": Risky terms, anti-buyer, or violating RERA.

        Return ONLY a JSON response in the following format, with no markdown formatting or backticks:
        {
          "analysis": [
            {
              "text": "The exact clause text",
              "category": "Green | Yellow | Red",
              "reason": "Brief reason for the categorization"
            }
          ]
        }
        
        Contract Text:
        ${text}
    `;

    const result = await model.generateContent(prompt);
    let responseText = result.response.text();
    responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
    return JSON.parse(responseText);
};

exports.explainSnippet = async (context, snippet) => {
    const model = getGenerativeModel();
    const prompt = `
        You are a helpful legal assistant for ordinary people (buyers/tenants).
        Context: The full document is provided below.
        Snippet: The user tapped on a specific snippet.
        Task: Explain the specific snippet in 2-3 sentences using simple, everyday language. Do not use legal jargon.

        Full Document Context:
        ${context}

        Snippet to explain:
        ${snippet}
    `;

    const result = await model.generateContent(prompt);
    return result.response.text();
};

const mongoose = require('mongoose');
const LawSnippet = require('../models/LawSnippet');
const ChatCache = require('../models/ChatCache');

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function withRetry(fn, retries = 3, baseDelay = 2000) {
    for (let i = 0; i < retries; i++) {
        try {
            return await fn();
        } catch (error) {
            const isRateLimit = error.status === 429 || (error.message && (error.message.includes('429') || error.message.includes('Quota exceeded') || error.message.includes('Too Many Requests')));
            if (isRateLimit && i < retries - 1) {
                const delay = baseDelay * Math.pow(2, i);
                console.warn(`Rate limit hit. Retrying in ${delay}ms...`);
                await sleep(delay);
                continue;
            }
            if (isRateLimit) {
                const rateLimitError = new Error('Rate limit reached. Please wait a moment.');
                rateLimitError.status = 429;
                throw rateLimitError;
            }
            throw error;
        }
    }
}

exports.chat = async (historyArray) => {
    try {
        const latestMessage = historyArray[historyArray.length - 1].text;

        // Check cache first
        const cachedResponse = await ChatCache.findOne({ query: latestMessage });
        if (cachedResponse) {
            console.log('Serving from cache for query:', latestMessage);
            return {
                reply: cachedResponse.reply,
                suggestions: cachedResponse.suggestions
            };
        }

        // 1. Generate an embedding for the user's latest question
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
        const embeddingModel = genAI.getGenerativeModel({ model: "gemini-embedding-2" });
        const embeddingResult = await withRetry(() => embeddingModel.embedContent(latestMessage));
        const queryVector = embeddingResult.embedding.values;

        // 2. Search MongoDB for the most relevant laws using Vector Search
        const searchResults = await LawSnippet.aggregate([
            {
                "$vectorSearch": {
                    "index": "vector_index",
                    "path": "embedding",
                    "queryVector": queryVector,
                    "numCandidates": 10,
                    "limit": 3
                }
            },
            {
                "$project": {
                    "text": 1,
                    "source": 1,
                    "score": { "$meta": "vectorSearchScore" }
                }
            }
        ]);

        // 3. Extract the text of the laws we found
        let contextLaws = searchResults.map(doc => doc.text).join('\n\n');
        if (!contextLaws) {
            contextLaws = "No specific laws found in the database. Rely on general knowledge.";
        }

        const systemInstruction = `
            You are an expert Indian Real Estate legal advisor and contract drafter. Your persona is Professional, Clear, Friendly, and Neutral. Avoid unnecessary legal jargon, explaining terms in simple language whenever possible.
            Answer based on RERA and Indian property laws.
            Use the provided legal context to ensure accuracy.

            CRITICAL GUIDELINES FOR YOUR RESPONSE:
            1. Direct Answers: If the user asks an informational question (e.g., "What is RERA?"), answer directly immediately. Do NOT give a history lesson (e.g., do not say "Prior to RERA..."). Start strong.
            2. Concise Explanations: Avoid returning very long paragraphs. Structure informational responses with an "Overview" (2-3 sentences), followed by "Key Points" as bullet points, and end with "Would you like to know more?".
            3. Guided Drafting Mode (Auto-Detection): If the user asks to create, draft, or write a document (e.g., "I want to sell my flat", "Draft a rent agreement"), you MUST NOT immediately generate the complete legal agreement. Instead:
               - Briefly explain what the document is (2-3 sentences max).
               - Inform the user that you need some information before preparing the draft.
               - Switch into an interview mode, asking ONLY ONE question at a time to collect information.
               - For an Agreement to Sell, collect sequentially: Property type, State, Property address, Seller details, Buyer details, Sale consideration, Advance amount, Possession date, Parking details, Loan/Mortgage status, Society details, Special conditions.
               - Only generate the final draft when ALL required information has been collected.
            4. Improve Agreement Generation: When generating the final draft, use proper headings, clearly numbered clauses, professional formatting, and placeholders only where info is unavailable. At the top of the draft, include: "AI-Generated Draft Agreement\\n\\nThis draft is generated based on the information provided by the user and should be reviewed before execution."
            5. Avoid Legal Overconfidence: Never say "This agreement is legally valid/perfect." Instead say: "This is an AI-generated draft based on the information you provided. Property laws vary by state and individual circumstances. Please review the draft carefully before signing."
            6. Improve Legal References: Use the heading "Applicable Laws" and list acts (e.g., Transfer of Property Act, 1882; Real Estate (Regulation and Development) Act, 2016; Registration Act, 1908; Indian Stamp Act (or applicable State Stamp Act)). Only show specific section numbers if the user explicitly asks.
            7. Interest Rates: Use: "The applicable interest rate is prescribed under the respective State RERA Rules and is generally linked to an SBI benchmark plus an additional percentage as specified by law."
            8. Dispute Redressal: Use: "Homebuyers may file complaints before the State RERA Authority. Depending on the nature of the dispute, remedies may also be available before Consumer Commissions or other competent courts, subject to applicable law."
            9. Agreement to Sell vs Sale Deed: Clarify the distinction: "An Agreement to Sell creates contractual obligations between the parties, whereas a Sale Deed actually transfers ownership of the property."
            10. Mandatory Contract Clauses: Include: Representations and warranties, Indemnity, Force majeure, Governing law and jurisdiction, Notice clause, Entire agreement clause, Amendment clause, and Severability.
            11. Execution Block: Include: Signed by: Vendor, Purchaser, Witness 1, Witness 2, Date, Place.
            12. State-Specific Disclaimer: Include: "Stamp duty, registration requirements, and certain procedural formalities vary by State and should be verified under the applicable State laws."
            13. Follow-up Suggestions: Generate contextual suggestion chips based on the conversation state (e.g., "What documents should the seller provide?", "Explain the indemnity clause.").

            CRITICAL INSTRUCTION: You MUST return your response as a valid JSON object with the following structure:
            {
                "reply": "Your markdown-formatted text response here.",
                "suggestions": ["Follow-up option 1", "Follow-up option 2", "Follow-up option 3"]
            }
            Do NOT include markdown backticks around the JSON. Return ONLY the JSON object.
        `;

        const model = genAI.getGenerativeModel({
            model: "gemini-3.6-flash",
            systemInstruction: systemInstruction
        });

        const formattedHistory = historyArray.slice(0, -1).map(msg => ({
            role: msg.role === 'user' ? 'user' : 'model',
            parts: [{ text: msg.text }]
        }));

        const chatSession = model.startChat({ history: formattedHistory });

        const prompt = `
            --- Legal Context (From our Database) ---
            ${contextLaws}
            -----------------------------------------

            User Query:
            ${latestMessage}
        `;

        const result = await withRetry(() => chatSession.sendMessage(prompt));
        let rawText = result.response.text().trim();
        rawText = rawText.replace(/^```json/i, '').replace(/```$/, '').trim();
        const finalResponse = JSON.parse(rawText);
        
        // Save to cache
        try {
            const newCache = new ChatCache({
                query: latestMessage,
                reply: finalResponse.reply,
                suggestions: finalResponse.suggestions
            });
            await newCache.save();
        } catch (cacheErr) {
            console.warn('Failed to save to cache:', cacheErr.message);
        }

        return finalResponse;
    } catch (e) {
        console.error("AI API failed (either embedding or generation):", e.message);
        if (e.status === 429) {
            throw e; // Pass 429 up to routes
        }
        return {
            reply: "I apologize, but our AI servers are currently experiencing extremely high demand. Generating or drafting complex contracts takes significant resources, and we are unable to fulfill this request at this exact moment. Please try again in a few minutes!",
            suggestions: []
        };
    }
};
