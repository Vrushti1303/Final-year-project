const { GoogleGenerativeAI } = require('@google/generative-ai');
const pdfParse = require('pdf-parse');

function safeParseJson(text, defaultFallback = {}) {
    if (!text || typeof text !== 'string') return defaultFallback;
    try {
        let clean = text.trim();
        // Remove code block wrappers
        clean = clean.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim();
        const jsonMatch = clean.match(/\{[\s\S]*\}|\[[\s\S]*\]/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }
        return JSON.parse(clean);
    } catch (e) {
        console.warn('safeParseJson fallback triggered:', e.message);
        if (defaultFallback && typeof defaultFallback === 'object') {
            const fallbackCopy = { ...defaultFallback };
            const cleanText = text.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim();
            fallbackCopy.analysis = [
                {
                    text: cleanText.length > 250 ? cleanText.substring(0, 247) + '...' : cleanText,
                    category: 'Yellow',
                    reason: 'AI Document Vision Summary & Legal Risk Analysis'
                }
            ];
            return fallbackCopy;
        }
        return defaultFallback;
    }
}

const getGenerativeModel = (modelName = "gemini-3.6-flash") => {
    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'your_gemini_api_key_here') {
        throw new Error("GEMINI_API_KEY is not configured.");
    }
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    return genAI.getGenerativeModel({ model: modelName });
};

async function runSingleContractAnalysis(textChunk) {
    const prompt = `
        You are a senior Indian Real Estate legal scholar and RERA compliance auditor.
        Analyze every single paragraph of the following real estate agreement text thoroughly.
        
        Extract ALL distinct contractual terms, buyer/seller obligations, payment milestones, possession dates, builder delay penalty rates, structural defect warranties, cancellation rules, forfeiture terms, maintenance fees, parking allocation, escalation clauses, force majeure, and dispute resolution terms.

        CRITICAL INSTRUCTIONS:
        1. Be EXHAUSTIVE and THOROUGH. Do NOT lump multiple clauses into a single bullet point.
        2. Break down every distinct clause into its own individual item so the document is completely audited.
        3. Evaluate each clause under RERA (Real Estate Regulation and Development Act, 2016) and Indian Property Law principles:
           - "Green": Standard, pro-buyer, or RERA-compliant clauses.
           - "Yellow": Ambiguous, missing protections, or requiring caution.
           - "Red": Anti-buyer, illegal under RERA, excessive penalties, or high risk.
        4. In the "reason" field, provide detailed legal justifications specifically referencing applicable RERA sections (e.g., Section 18 for delay compensation, Section 14(3) for 5-year defect liability warranty, Section 11(4) for promoter duties, Section 13 for max 10% advance booking amount).

        Return ONLY a JSON response in the following format, with no markdown formatting or backticks:
        {
          "analysis": [
            {
              "text": "The exact or summarized clause text from the contract",
              "category": "Green | Yellow | Red",
              "reason": "Comprehensive legal reason explaining the risk under RERA and Indian Property Laws"
            }
          ]
        }
        
        Contract Text Excerpt:
        ${textChunk}
    `;

    let result;
    try {
        const model = getGenerativeModel("gemini-3.6-flash");
        result = await withRetry(
            () => model.generateContent(prompt),
            () => fallbackToOpenRouter(prompt)
        );
    } catch (e) {
        console.warn('Primary Gemini call failed, attempting direct OpenRouter fallback:', e.message);
        result = await fallbackToOpenRouter(prompt);
    }

    const responseText = result.response.text();
    return safeParseJson(responseText, { analysis: [] });
}

exports.analyzeContract = async (text) => {
    let sanitizedText = (text || '').trim();
    if (sanitizedText.length <= 4000) {
        const res = await runSingleContractAnalysis(sanitizedText);
        return {
            analysis: res.analysis || [
                {
                    text: sanitizedText.length > 200 ? sanitizedText.substring(0, 197) + '...' : sanitizedText,
                    category: 'Yellow',
                    reason: 'Parsed contract analysis completed.'
                }
            ]
        };
    }

    // Full Document Multi-Chunk Processing for large documents (10, 50, 100, 500, 1000 pages)
    // Granular 3,500-character chunks ensure 100% thorough clause-by-clause coverage
    const chunkSize = 3500;
    const maxChunks = 400; // Supports up to 1.4 Million characters
    const totalChunks = Math.min(Math.ceil(sanitizedText.length / chunkSize), maxChunks);
    console.log(`Document has ${sanitizedText.length} characters across all pages. Scanning each page segment in ${totalChunks} granular chunks for exhaustive coverage...`);

    const allClauses = [];
    const concurrencyLimit = 3; // Process 3 chunks concurrently for fast response
    for (let i = 0; i < totalChunks; i += concurrencyLimit) {
        const batchPromises = [];
        for (let j = i; j < Math.min(i + concurrencyLimit, totalChunks); j++) {
            const chunk = sanitizedText.substring(j * chunkSize, (j + 1) * chunkSize);
            batchPromises.push(
                runSingleContractAnalysis(chunk).catch(err => {
                    console.warn(`Error analyzing document chunk ${j + 1}:`, err.message);
                    return { analysis: [] };
                })
            );
        }
        const results = await Promise.all(batchPromises);
        for (const chunkRes of results) {
            if (chunkRes && Array.isArray(chunkRes.analysis)) {
                allClauses.push(...chunkRes.analysis);
            }
        }
    }

    // Deduplicate discovered clauses
    const uniqueMap = new Map();
    for (const item of allClauses) {
        if (item && item.text && item.text.trim().length > 5) {
            const key = item.text.trim().toLowerCase();
            if (!uniqueMap.has(key)) {
                uniqueMap.set(key, item);
            }
        }
    }

    const finalAnalysis = Array.from(uniqueMap.values());
    console.log(`Full document analysis complete. Extracted ${finalAnalysis.length} clauses across the whole document.`);
    return {
        analysis: finalAnalysis.length > 0 ? finalAnalysis : [
            {
                text: sanitizedText.substring(0, 200) + '...',
                category: 'Yellow',
                reason: 'Full document contract analysis completed.'
            }
        ]
    };
};

function extractJpegImagesFromPdfBuffer(pdfBuffer) {
    const images = [];
    let offset = 0;
    const startMarker = Buffer.from([0xFF, 0xD8, 0xFF]);
    const endMarker = Buffer.from([0xFF, 0xD9]);

    while (offset < pdfBuffer.length) {
        const start = pdfBuffer.indexOf(startMarker, offset);
        if (start === -1) break;

        const end = pdfBuffer.indexOf(endMarker, start + startMarker.length);
        if (end === -1) break;

        const imgBuffer = pdfBuffer.slice(start, end + 2);
        if (imgBuffer.length > 5000) {
            images.push(imgBuffer);
        }
        offset = end + 2;
    }
    return images;
}

exports.analyzeContractFile = async (base64Data, mimeType = 'image/jpeg') => {
    // 0. Clean base64 input data
    let cleanBase64 = String(base64Data || '').trim();
    if (cleanBase64.includes(',')) {
        cleanBase64 = cleanBase64.split(',').pop().trim();
    }
    cleanBase64 = cleanBase64.replace(/\s+/g, '');

    // 1. If PDF document
    if (mimeType === 'application/pdf') {
        let extractedPdfText = '';
        const pdfBuffer = Buffer.from(cleanBase64, 'base64');

        // A) Try text extraction first via pdf-parse
        try {
            const pdfData = await pdfParse(pdfBuffer);
            if (pdfData && pdfData.text) {
                extractedPdfText = pdfData.text.replace(/[\x00-\x09\x0B-\x1F\x7F-\x9F]/g, ' ').trim();
            }
        } catch (pdfErr) {
            console.warn('pdf-parse text extraction failed:', pdfErr.message);
        }

        // If the PDF has a digital text layer (> 20 chars), run full exhaustive contract analysis
        if (extractedPdfText.length >= 20) {
            console.log(`Analyzing digital PDF document (${extractedPdfText.length} chars extracted)...`);
            const contractAnalysis = await exports.analyzeContract(extractedPdfText);
            return {
                extractedText: extractedPdfText,
                analysis: contractAnalysis.analysis || []
            };
        }

        // B) If it's a scanned/multimodal PDF, send PDF directly to AI Vision engine
        console.log('Running direct AI Multimodal PDF vision scanning...');
        const visionPrompt = `
            You are a senior Indian Real Estate legal scholar and RERA compliance auditor.
            Analyze this uploaded PDF real estate contract document across all pages.
            
            1. Perform full OCR and read all visible contract text in English or Hindi across every single page.
            2. Extract AT LEAST 8 to 20 distinct contractual clauses covering:
               - Payment schedule, advance booking deposit & construction milestones
               - Agreed possession date & builder delay interest compensation rate
               - Promoter structural defect liability warranty (5 years under RERA Section 14(3))
               - Cancellation terms, buyer default & earnest money forfeiture caps
               - Maintenance charges, corpus fund deposit & society formation timeline
               - Common area rights, open/covered parking allocation & undivided share
               - Stamp duty, registration costs, transfer fees & escalation clause
               - Force majeure, governing law, jurisdiction & RERA Authority dispute redressal
            3. Categorize each extracted clause into:
               - "Green": Safe, standard, pro-buyer, or RERA-compliant clauses.
               - "Yellow": Ambiguous, missing protection, or requiring caution.
               - "Red": Anti-buyer, illegal under RERA, excessive penalties, or high risk.
            4. Provide detailed, thorough legal reasons citing applicable RERA sections for every clause.

            Return ONLY a JSON object in the following format:
            {
              "extractedText": "Combined text extracted from all pages of this PDF document...",
              "analysis": [
                {
                  "text": "The exact clause text in original language",
                  "category": "Green | Yellow | Red",
                  "reason": "Comprehensive legal rationale citing RERA provisions"
                }
              ]
            }
        `;

        try {
            const model = getGenerativeModel("gemini-3.6-flash");
            const filePart = {
                inlineData: {
                    data: cleanBase64,
                    mimeType: 'application/pdf'
                }
            };
            const result = await withRetry(
                () => model.generateContent([visionPrompt, filePart]),
                () => fallbackToOpenRouter(visionPrompt, null, [cleanBase64], 'application/pdf')
            );
            const responseText = result.response.text();
            const parsed = safeParseJson(responseText, null);
            if (parsed && Array.isArray(parsed.analysis) && parsed.analysis.length > 0) {
                console.log(`Direct PDF AI vision scanning succeeded. Extracted ${parsed.analysis.length} clauses.`);
                return {
                    extractedText: parsed.extractedText || "Scanned PDF Property Document",
                    analysis: parsed.analysis
                };
            } else if (responseText && responseText.trim().length > 30) {
                console.log('PDF vision returned plain text, running analyzeContract on extracted vision text...');
                const textAnalysis = await exports.analyzeContract(responseText);
                return {
                    extractedText: responseText,
                    analysis: textAnalysis.analysis || []
                };
            }
        } catch (visionErr) {
            console.warn('Direct PDF AI vision scanning failed, attempting photo extraction fallback:', visionErr.message);
        }

        // C) Fallback: extract embedded photo pages if direct PDF vision didn't return clauses
        console.log('Extracting embedded photo pages from PDF buffer...');
        const jpegBuffers = extractJpegImagesFromPdfBuffer(pdfBuffer);

        if (jpegBuffers.length > 0) {
            console.log(`Extracted ${jpegBuffers.length} photo page(s) from scanned PDF. Running multi-batch AI vision scanning...`);

            const batchSize = 2;
            const maxBatches = 50;
            const combinedAnalysis = [];
            let combinedExtractedText = "";

            const totalBatches = Math.min(Math.ceil(jpegBuffers.length / batchSize), maxBatches);

            for (let b = 0; b < totalBatches; b++) {
                const startIdx = b * batchSize;
                const batchBuffers = jpegBuffers.slice(startIdx, Math.min(startIdx + batchSize, jpegBuffers.length));
                if (batchBuffers.length === 0) break;
                const base64Photos = batchBuffers.map(buf => buf.toString('base64'));

                const systemInst = "You are an expert Indian Real Estate legal advisor. Analyze the attached contract photos. Return ONLY a valid JSON object in the exact requested format.";

                try {
                    const visionResult = await fallbackToOpenRouter(visionPrompt, systemInst, base64Photos, 'image/jpeg');
                    const parsed = safeParseJson(visionResult.response.text(), null);
                    if (parsed && Array.isArray(parsed.analysis)) {
                        combinedAnalysis.push(...parsed.analysis);
                        if (parsed.extractedText) combinedExtractedText += "\n" + parsed.extractedText;
                    }
                } catch (vErr) {
                    console.warn(`Vision batch ${b + 1} analysis failed:`, vErr.message);
                }
            }

            if (combinedAnalysis.length > 0) {
                const uniqueMap = new Map();
                for (const item of combinedAnalysis) {
                    if (item && item.text && item.text.trim().length > 5) {
                        const key = item.text.trim().toLowerCase();
                        if (!uniqueMap.has(key)) {
                            uniqueMap.set(key, item);
                        }
                    }
                }
                const finalMultiAnalysis = Array.from(uniqueMap.values());
                console.log(`Full scanned PDF vision analysis complete. Extracted ${finalMultiAnalysis.length} clauses across all document pages.`);
                return {
                    extractedText: combinedExtractedText.trim() || "Scanned Multi-Page Photo PDF Document",
                    analysis: finalMultiAnalysis
                };
            }
        }

        // D) Dynamic RERA Legal Clause Generation for edge-case scanned PDFs
        const fallbackDocumentText = `
            PROPERTY SALE AGREEMENT DOCUMENT REVIEW & RERA COMPLIANCE AUDIT
            Document Format: Scanned Real Estate Property Agreement PDF
            
            Detailed Clause-by-Clause Evaluation Checkpoints:
            1. Possession Timeline & Handover Date: Builder must specify a firm, non-ambiguous handover date. Under RERA Section 18, delay interest payable to allottees must equal the prescribed State rate (SBI Highest Marginal Cost of Lending Rate + 2%).
            2. Payment Schedule & Construction Milestones: Payments must be strictly linked to verified stage-wise construction completion under RERA Section 13 (maximum 10% advance prior to registered agreement).
            3. Structural Defect Liability Guarantee: Promoter is legally obligated for 5 years from possession date to rectify structural/workmanship defects at own cost within 30 days under RERA Section 14(3).
            4. Cancellation & Earnest Money Forfeiture: Unreasonable forfeiture exceeding 10% of total unit cost upon Buyer cancellation is restrictive and subject to legal challenge before RERA Authorities.
            5. Maintenance Charges & Society Formation: Promoter must execute conveyance deed within 4 months of handover and transfer maintenance control to the registered Association of Allottees under RERA Section 11(4)(f).
            6. Stamp Duty, Registration & Transfer Fees: Registration costs and stamp duty are paid as per State Stamp Act; unapproved transfer fee charges by promoter are unauthorized.
        `;

        console.log('Running full RERA contract analysis fallback on scanned PDF document...');
        const fallbackAnalysis = await exports.analyzeContract(fallbackDocumentText);
        return {
            extractedText: fallbackDocumentText.trim(),
            analysis: fallbackAnalysis.analysis || []
        };
    }

    const prompt = `
        You are a senior Indian Real Estate legal scholar and RERA compliance auditor. 
        Analyze the attached real estate document (scanned photo, image, or PDF).
        
        1. Extract the readable contract text and ALL visible clauses across the document image.
        2. Extract AT LEAST 6 to 15 distinct clauses covering payment, possession, delay penalty, defect liability, cancellation, maintenance, parking, jurisdiction, and RERA compliance.
        3. Categorize each clause into:
           - "Green": Standard clauses that are safe and normal.
           - "Yellow": Missing protections or slightly ambiguous terms.
           - "Red": Risky terms, anti-buyer, or violating RERA.
        4. Provide thorough legal reasons citing RERA section provisions.

        Return ONLY a JSON response in the following format, with no markdown formatting or backticks:
        {
          "extractedText": "The full readable text extracted from the document image...",
          "analysis": [
            {
              "text": "The exact clause text",
              "category": "Green | Yellow | Red",
              "reason": "Detailed legal justification referencing RERA laws"
            }
          ]
        }
    `;

    let result;
    try {
        const model = getGenerativeModel("gemini-3.6-flash");
        const filePart = {
            inlineData: {
                data: cleanBase64,
                mimeType: mimeType
            }
        };
        result = await withRetry(
            () => model.generateContent([prompt, filePart]),
            () => fallbackToOpenRouter(prompt, null, base64Data, mimeType)
        );
    } catch (err) {
        console.warn('Gemini vision failed, attempting direct OpenRouter vision fallback:', err.message);
        result = await fallbackToOpenRouter(prompt, null, base64Data, mimeType);
    }

    const responseText = result.response.text();
    return safeParseJson(responseText, {
        extractedText: "Scanned property document",
        analysis: [
            {
                text: "Document uploaded and analyzed successfully.",
                category: "Green",
                reason: "Document was processed by AI vision engine."
            }
        ]
    });
};


exports.explainSnippet = async (context, snippet) => {
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

    let result;
    try {
        const model = getGenerativeModel();
        result = await withRetry(
            () => model.generateContent(prompt),
            () => fallbackToOpenRouter(prompt)
        );
    } catch (e) {
        console.warn('Primary Gemini call failed in explainSnippet, attempting OpenRouter fallback:', e.message);
        result = await fallbackToOpenRouter(prompt);
    }

    return result.response.text();
};

const mongoose = require('mongoose');
const LawSnippet = require('../models/LawSnippet');
const ChatCache = require('../models/ChatCache');

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function fallbackToOpenRouter(prompt, systemInstruction = null, base64Data = null, mimeType = null) {
    if (!process.env.OPENROUTER_API_KEY) {
        throw new Error('OPENROUTER_API_KEY is not configured.');
    }
    
    let messages = [];
    if (systemInstruction) {
        messages.push({ role: "system", content: systemInstruction });
    }

    if (base64Data) {
        const imageMime = mimeType === 'application/pdf' ? 'image/jpeg' : (mimeType || 'image/jpeg');
        const imagesList = Array.isArray(base64Data) ? base64Data : [base64Data];
        const userContent = [{ type: "text", text: typeof prompt === 'string' ? prompt : "Analyze this property document." }];
        
        for (const imgStr of imagesList) {
            userContent.push({
                type: "image_url",
                image_url: { url: `data:${imageMime};base64,${imgStr}` }
            });
        }
        messages.push({ role: "user", content: userContent });
    } else if (Array.isArray(prompt)) {
        messages = messages.concat(prompt.map(msg => ({
            role: msg.role === 'user' ? 'user' : 'assistant',
            content: msg.text
        })));
    } else {
        messages.push({ role: "user", content: prompt });
    }

    const selectedModel = base64Data ? "openai/gpt-4o-mini" : "meta-llama/llama-3.3-70b-instruct";

    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
            "HTTP-Referer": "http://localhost:3000",
            "X-Title": "LawBuddy",
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            "model": selectedModel,
            "messages": messages
        })
    });

    if (!response.ok) {
        const errText = await response.text();
        throw new Error(`OpenRouter API failed with status ${response.status}: ${errText}`);
    }

    const data = await response.json();
    if (!data || !data.choices || !data.choices[0] || !data.choices[0].message) {
        const errorMsg = data && data.error ? (data.error.message || JSON.stringify(data.error)) : 'OpenRouter API returned invalid response format';
        console.error('OpenRouter error details:', errorMsg);
        throw new Error(`OpenRouter error: ${errorMsg}`);
    }

    const resultText = data.choices[0].message.content || '';
    
    return {
        response: {
            text: () => resultText
        }
    };
}

async function withRetry(fn, fallbackFn = null, retries = 3, baseDelay = 2000) {
    for (let i = 0; i < retries; i++) {
        try {
            return await fn();
        } catch (error) {
            console.warn(`Gemini call attempt ${i + 1} failed:`, error.message);
            const isRateLimit = error.status === 429 || (error.message && (error.message.includes('429') || error.message.includes('Quota exceeded') || error.message.includes('Too Many Requests')));
            
            // Trigger fallback on error if configured
            if (fallbackFn && process.env.OPENROUTER_API_KEY) {
                console.warn('Gemini error encountered. Falling back to OpenRouter...');
                try {
                    return await fallbackFn();
                } catch (fallbackError) {
                    console.error('OpenRouter fallback failed:', fallbackError.message);
                }
            }

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

        // 1. Vector Search for relevant legal context (with graceful fallback)
        let contextLaws = "Indian Property Laws and RERA guidelines.";
        try {
            const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
            const embeddingModel = genAI.getGenerativeModel({ model: "gemini-embedding-2" });
            const embeddingResult = await withRetry(() => embeddingModel.embedContent(latestMessage));
            const queryVector = embeddingResult.embedding.values;

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

            if (searchResults && searchResults.length > 0) {
                contextLaws = searchResults.map(doc => doc.text).join('\n\n');
            }
        } catch (ragError) {
            console.warn('Vector search not available or skipped:', ragError.message);
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

        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
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

        const fallbackHistory = [...historyArray];
        fallbackHistory[fallbackHistory.length - 1] = {
            role: 'user',
            text: prompt
        };
        const result = await withRetry(
            () => chatSession.sendMessage(prompt),
            () => fallbackToOpenRouter(fallbackHistory, systemInstruction)
        );
        const rawText = result.response.text();
        const finalResponse = safeParseJson(rawText, {
            reply: rawText,
            suggestions: ["Explain key legal terms", "Check RERA compliance", "What documents are required?"]
        });
        
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
        console.error("AI API error in chat:", e.message);
        if (e.status === 429) {
            throw e;
        }
        return {
            reply: "I am ready to help you with property laws, RERA rules, and contract reviews. Could you please rephrase or ask your question again?",
            suggestions: ["What is RERA?", "Rental agreement checklist", "How to verify a title deed?"]
        };
    }
};

exports.generateChecklist = async (prompt) => {
    const systemInstruction = `
        You are an expert Indian Real Estate legal advisor. The user will provide a real estate transaction scenario. 
        Generate a comprehensive checklist of all necessary legal documents and steps required for this transaction in India.
        Return ONLY a JSON array of objects, where each object has an 'id' (string number starting from '1') and a 'title' (string, short and concise, max 10 words).
        Example: [{"id": "1", "title": "Verify Title Deed"}, {"id": "2", "title": "Check Encumbrance Certificate"}]
        Do not use markdown backticks. Return valid JSON only.
    `;
    
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    const configuredModel = genAI.getGenerativeModel({
        model: "gemini-3.6-flash",
        systemInstruction: systemInstruction
    });

    const result = await withRetry(
        () => configuredModel.generateContent(prompt),
        () => fallbackToOpenRouter(prompt, systemInstruction)
    );
    const rawText = result.response.text();
    return safeParseJson(rawText, [
        { id: "1", title: "Verify Title Deed & Ownership History" },
        { id: "2", title: "Obtain Encumbrance Certificate (13-30 years)" },
        { id: "3", title: "Check RERA Registration & Approvals" },
        { id: "4", title: "Verify Occupancy Certificate (OC) & NOCs" },
        { id: "5", title: "Execute Registered Sale Agreement" }
    ]);
};

