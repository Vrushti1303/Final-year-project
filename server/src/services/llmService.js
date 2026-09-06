const { GoogleGenerativeAI } = require('@google/generative-ai');
const pdfParse = require('pdf-parse');
const mongoose = require('mongoose');
const LawSnippet = require('../models/LawSnippet');
const ChatCache = require('../models/ChatCache');

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

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

function normalizeQuery(q) {
    if (!q || typeof q !== 'string') return '';
    return q.trim().toLowerCase().replace(/[?!.,;:'"()]/g, '').replace(/\s+/g, ' ');
}

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
        const compactHistory = prompt.length > 8 ? prompt.slice(-8) : prompt;
        messages = messages.concat(compactHistory.map(msg => ({
            role: msg.role === 'user' ? 'user' : 'assistant',
            content: msg.text || ''
        })));
    } else {
        messages.push({ role: "user", content: prompt });
    }

    const candidateModels = base64Data 
        ? ["openai/gpt-4o-mini", "google/gemini-2.5-flash", "meta-llama/llama-3.3-70b-instruct"]
        : [
            "openai/gpt-4o-mini",
            "deepseek/deepseek-chat",
            "meta-llama/llama-3.3-70b-instruct",
            "mistralai/mistral-small-24b-instruct-2501"
        ];

    let lastError = null;

    for (const modelName of candidateModels) {
        try {
            const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
                method: "POST",
                headers: {
                    "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
                    "HTTP-Referer": "http://localhost:3000",
                    "X-Title": "LawBuddy",
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    model: modelName,
                    max_tokens: 2500,
                    messages: messages
                })
            });

            if (!response.ok) {
                const errText = await response.text();
                console.warn(`Model ${modelName} failed (${response.status}), trying next candidate...`);
                lastError = new Error(`Status ${response.status}: ${errText}`);
                continue;
            }

            const data = await response.json();
            const resultText = data.choices && data.choices[0] && data.choices[0].message ? data.choices[0].message.content : '';
            if (resultText && resultText.trim().length > 0) {
                return {
                    response: {
                        text: () => resultText
                    }
                };
            }
        } catch (modelErr) {
            console.warn(`Error calling model ${modelName}:`, modelErr.message);
            lastError = modelErr;
        }
    }

    throw lastError || new Error('All OpenRouter candidate models failed');
}

async function withRetry(fn, fallbackFn = null, retries = 2, baseDelay = 1000) {
    let lastError = null;
    for (let i = 0; i < retries; i++) {
        try {
            return await fn();
        } catch (error) {
            lastError = error;
            console.warn(`Primary AI attempt ${i + 1} failed:`, error.message);
            
            if (fallbackFn && process.env.OPENROUTER_API_KEY) {
                try {
                    console.log('Switching to OpenRouter fallback...');
                    return await fallbackFn();
                } catch (fallbackError) {
                    console.error('OpenRouter fallback failed:', fallbackError.message);
                }
            }

            if (i < retries - 1) {
                await sleep(baseDelay * (i + 1));
            }
        }
    }
    throw lastError || new Error('AI Generation failed');
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

    const result = await withRetry(
        () => {
            const model = getGenerativeModel("gemini-3.6-flash");
            return model.generateContent(prompt);
        },
        () => fallbackToOpenRouter(prompt)
    );

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

    const chunkSize = 3500;
    const maxChunks = 400;
    const totalChunks = Math.min(Math.ceil(sanitizedText.length / chunkSize), maxChunks);
    console.log(`Document has ${sanitizedText.length} characters across all pages. Scanning each page segment in ${totalChunks} granular chunks for exhaustive coverage...`);

    const allClauses = [];
    const concurrencyLimit = 3;
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
    let cleanBase64 = String(base64Data || '').trim();
    if (cleanBase64.includes(',')) {
        cleanBase64 = cleanBase64.split(',').pop().trim();
    }
    cleanBase64 = cleanBase64.replace(/\s+/g, '');

    if (mimeType === 'application/pdf') {
        let extractedPdfText = '';
        const pdfBuffer = Buffer.from(cleanBase64, 'base64');

        try {
            const pdfData = await pdfParse(pdfBuffer);
            if (pdfData && pdfData.text) {
                extractedPdfText = pdfData.text.replace(/[\x00-\x09\x0B-\x1F\x7F-\x9F]/g, ' ').trim();
            }
        } catch (pdfErr) {
            console.warn('pdf-parse text extraction failed:', pdfErr.message);
        }

        if (extractedPdfText.length >= 20) {
            console.log(`Analyzing digital PDF document (${extractedPdfText.length} chars extracted)...`);
            const contractAnalysis = await exports.analyzeContract(extractedPdfText);
            return {
                extractedText: extractedPdfText,
                analysis: contractAnalysis.analysis || []
            };
        }

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
    }

    const visionPrompt = `
        You are a senior Indian Real Estate legal scholar and RERA compliance auditor.
        Read and audit the attached property contract page/image carefully.
        Extract ALL individual clauses, identify risks under RERA, categorize into Green/Yellow/Red, and provide legal reasoning.
        Return ONLY a JSON object:
        {
          "extractedText": "All text seen in the image...",
          "analysis": [
            {
              "text": "Exact clause text",
              "category": "Green | Yellow | Red",
              "reason": "Detailed legal reasoning"
            }
          ]
        }
    `;

    const result = await withRetry(
        () => {
            const model = getGenerativeModel("gemini-3.6-flash");
            const filePart = {
                inlineData: {
                    data: cleanBase64,
                    mimeType: mimeType
                }
            };
            return model.generateContent([visionPrompt, filePart]);
        },
        () => fallbackToOpenRouter(visionPrompt, null, cleanBase64, mimeType)
    );

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

    const result = await withRetry(
        () => {
            const model = getGenerativeModel();
            return model.generateContent(prompt);
        },
        () => fallbackToOpenRouter(prompt)
    );
    return result.response.text();
};

exports.chat = async (historyArray) => {
    try {
        const latestMessage = historyArray[historyArray.length - 1].text;

        const normQuery = normalizeQuery(latestMessage);
        const cachedResponse = await ChatCache.findOne({
            $or: [{ query: latestMessage }, { query: normQuery }]
        });
        if (cachedResponse) {
            console.log('Serving from cache for query:', latestMessage);
            return {
                reply: cachedResponse.reply,
                suggestions: cachedResponse.suggestions
            };
        }

        let contextLaws = "Indian Property Laws and RERA guidelines.";
        try {
            const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
            const embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004" });
            const embeddingResult = await embeddingModel.embedContent(latestMessage);
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
            // vector search optional fallback
        }

        const systemInstruction = `
You are a senior, meticulously accurate Indian Real Estate and Property Law legal specialist. Your foundational mandate is strict statutory accuracy, factual precision, objective legal reasoning, and clear, qualified analysis.

=== FINAL LEGAL ACCURACY, PRECISION & ANTI-HALLUCINATION RULES ===

1. NEVER INVENT LEGAL AUTHORITIES
- Never fabricate or guess:
  * Sections or subsections of Acts
  * Acts, Rules, Regulations, Circulars, Notifications, Government Resolutions or Orders
  * Court judgments or case names
  * Supreme Court, High Court, RERA Authority, Consumer Commission or tribunal decisions
  * Legal deadlines, limitation periods, penalties, fees or interest rates
  * State-specific rules or percentages
  * Forfeiture limits or compensation formulas
  * Government rates, stamp-duty rates or registration charges
- If you are not sufficiently confident that a specific provision or authority exists, do NOT provide a section number or case name as fact.
- If a legal proposition depends on a state-specific rule, identify that it is state-specific and do not substitute a generic national rule.

2. DISTINGUISH STATUTORY TEXT FROM LEGAL INTERPRETATION
Always distinguish between:
A. What the statute expressly says
B. What may follow from applying the statute to the facts
C. A possible legal argument or remedy
D. What requires verification from state rules, regulations, notifications, contractual documents or case law
Never present B, C or D as though it were directly stated in the statute.
Use wording such as:
- "Section X provides..."
- "Depending on the facts..."
- "This may support a claim..."
- "A possible remedy may be..."
- "This would need to be verified under the applicable state/Maharashtra rules..."
- "The exact remedy depends on the Agreement for Sale and surrounding facts..."

3. DO NOT TURN STATUTORY THRESHOLDS INTO RIGHTS
A statutory limit, threshold or condition must never be interpreted as automatically creating a corresponding entitlement.
Examples:
- A 10% advance-payment restriction (Section 13(1)) does NOT automatically create a 10% forfeiture right.
- A statutory interest provision does NOT automatically establish a fixed compensation amount.
- A registration requirement does NOT automatically determine every consequence of non-registration.
- A statutory penalty provision does NOT automatically mean the maximum penalty applies.
Always explain what the provision actually regulates.

4. NO AUTOMATIC REMEDIES
Never tell a user that they are "automatically entitled" to a specific:
- Refund amount
- Compensation amount
- Interest rate
- Monthly payment
- Price reduction
- Forfeiture amount
- Penalty
- Damages
- Cancellation right
unless the applicable law clearly establishes that entitlement on the stated facts.
Instead, identify:
1. The potentially applicable legal provision
2. The conditions that must be satisfied
3. The relevant facts/evidence
4. The possible remedies
5. Any limitations or competing arguments

5. HANDLE INCOMPLETE FACTS EXPLICITLY
Do not fill missing facts with assumptions. When an answer depends materially on missing information, explicitly identify what is missing (e.g., whether the Agreement for Sale was registered, state jurisdiction, exact terminology used, whether allottee is in default).
If the missing fact could materially change the legal outcome, state this clearly.

6. STATE-SPECIFIC LAW MUST BE TREATED AS STATE-SPECIFIC
Indian real-estate law frequently depends on state rules, regulations, notifications and regulatory practice.
Never give a generic national percentage or rule when the question concerns a particular state.
For Maharashtra-related questions:
- Identify when Maharashtra-specific law/rules (MahaRERA Rules, Maharashtra Stamp Act, MOFA where relevant) apply.
- Do not assume that a rule from another state applies in Maharashtra.
- Do not quote a Maharashtra-specific percentage, fee, interest rate or forfeiture limit unless verified.
- If uncertain, clearly state that it requires verification from official state notifications.

7. CASE LAW MUST NOT BE OVERGENERALIZED
When mentioning a judgment:
- Do not imply that a case decided a factual situation it did not decide.
- Do not use a case as authority for a proposition broader than its actual principle.
- Distinguish between the case's specific facts and its broader legal principle.
- Do not say a court or regulator has "repeatedly," "consistently," or "numerously" held something unless genuinely established.
- Never fabricate case citations.

8. SECTION NUMBER VERIFICATION
Before citing a section number:
- Ensure that the section actually exists in the relevant Act.
- Ensure that the section concerns the subject being discussed.
- Note that the central RERA Act (Real Estate Regulation and Development Act, 2016) ends at Section 92.
- If the user gives a nonexistent provision (e.g., "Section 101 of RERA"), explicitly correct the premise: "There is no Section 101 in the central RERA Act; the Act ends at Section 92." Then identify the provision that may actually be relevant.

9. FALSE-PREMISE CORRECTION
If the user's question contains a false legal assumption:
1. Clearly identify the false assumption.
2. Do not answer the hypothetical as though it were legally true.
3. Explain the correct legal position.
4. Identify the provision that actually governs the issue.

10. CONTRACTUAL TERMS VS STATUTORY RIGHTS
Do not assume that a signed contract automatically eliminates statutory rights, or that a statutory right automatically invalidates every contractual term.
Analyze both: Contractual terms -> statutory provisions -> applicable rules/regulations -> factual circumstances -> possible legal effect.

11. RERA PORTAL / DISCLOSURES
Treat information appearing on a State RERA portal carefully. Distinguish portal disclosures, sanctioned plans, promoter declarations, brochures/advertisements, allotment letters, and registered Agreement for Sale.

12. CARPET AREA
Use the statutory definition in Section 2(k) accurately (net usable floor area of an apartment, excluding the area covered by external walls, areas under services shafts, exclusive balcony or verandah area and exclusive open terrace area, but includes the area covered by the internal partition walls).
Distinguish carpet area from built-up/super built-up area.

13. MONETARY CALCULATIONS
Do not manufacture a compensation or refund formula. If an illustrative calculation is provided, clearly label it: "This is only a mathematical illustration, not a statement of legal entitlement."

14. ABSOLUTE LANGUAGE
Avoid absolute statements such as "completely illegal", "automatically entitled", "guaranteed", "definitely", "the court will".
Use precise language: "The stated legal basis appears incorrect", "This does not appear to create an automatic entitlement", "The buyer may have grounds to claim...", "This depends on...", "This should be verified under...".

15. STRUCTURE FOR SCENARIO-BASED LEGAL QUESTIONS
Where applicable, use the following reasoning structure:
### Short Answer
Give the clearest answer possible, with appropriate qualification.
### Legal Position
Identify the relevant law and explain what it actually provides.
### Application to These Facts / What This Means For You
Connect the law to the facts provided.
### What Is Still Unclear
Identify missing facts that could materially change the outcome.
### Possible Remedies / Next Steps
Give realistic options without guaranteeing an outcome.
### Important Limitations
Mention state-specific law, contractual terms, evidence, procedural issues, or other relevant limitations.

16. LEGAL ACCURACY PRIORITY
Always prioritize LEGAL ACCURACY > CONFIDENCE > COMPLETENESS.
When uncertain: Do not guess.
When facts are missing: Do not assume.
When state law matters: Do not generalize.
When citing a section: Verify it actually says what is claimed.
When discussing a remedy: Do not promise an outcome.

17. NO CLAIM OF CERTIFICATION & DISCLAIMER
Never describe the assistant as legally certified or a substitute for a lawyer. Provide informational legal analysis and recommend consulting a qualified legal professional or the local Sub-Registrar / RERA Authority for legal proceedings, official filings, or high-stakes transactions.

=== OUTPUT FORMAT ===
You MUST return your response as a valid JSON object:
{
    "reply": "Your markdown-formatted text response here.",
    "suggestions": ["Contextual follow-up question 1", "Contextual follow-up question 2", "Contextual follow-up question 3"]
}
Do NOT include markdown code block backticks around the JSON. Return ONLY the JSON object.
`;

        const prompt = `
            --- Legal Reference Context ---
            ${contextLaws}
            -------------------------------

            User Query:
            ${latestMessage}
        `;

        const fallbackHistory = [...historyArray];
        fallbackHistory[fallbackHistory.length - 1] = {
            role: 'user',
            text: prompt
        };

        const result = await withRetry(
            () => {
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
                return chatSession.sendMessage(prompt);
            },
            () => fallbackToOpenRouter(fallbackHistory, systemInstruction)
        );

        const rawText = result.response.text();
        const finalResponse = safeParseJson(rawText, {
            reply: rawText,
            suggestions: ["Explain key legal terms", "Check RERA compliance", "What documents are required?"]
        });
        
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
    
    const result = await withRetry(
        () => {
            const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
            const configuredModel = genAI.getGenerativeModel({
                model: "gemini-3.6-flash",
                systemInstruction: systemInstruction
            });
            return configuredModel.generateContent(prompt);
        },
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
