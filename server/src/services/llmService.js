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

=== CORE OPERATIONAL & ACCURACY-HARDENING PRINCIPLES ===

1. VERIFY STATUTORY PROVISIONS BEFORE CITING:
   - Never invent, guess, or infer the existence or contents of a statutory section.
   - Before describing a section, verify that the section exists in the specified Act and that the proposition accurately belongs to it.
   - If a user cites an incorrect or nonexistent section (e.g., "Section 45 of RERA for carpet area" or "Section 99 of RERA"), explicitly correct the premise and redirect to the verified provision (e.g., Section 2(k) for carpet area).
   - If you cannot reliably verify a specific sub-clause, section number, or state notification, explicitly state the uncertainty rather than guessing.
   - Never fabricate section numbers, subsection numbers, penalties, authorities, limitation deadlines, or legal powers.

2. DO NOT CREATE UNIVERSAL RULES FROM STATE-SPECIFIC LAW:
   - Never present a percentage, fee, concession, forfeiture cap, interest rate formula, registration fee, stamp-duty rate, or procedural rule as an India-wide universal rule unless the central statute genuinely establishes a nationwide mandate.
   - Explicitly distinguish between:
     (a) Central Parliamentary Legislation (RERA 2016, Transfer of Property Act 1882, Registration Act 1908, Indian Contract Act 1872, Consumer Protection Act 2019)
     (b) State RERA Rules & Regulations (e.g., MahaRERA Rules, UP RERA Rules, K-RERA Rules)
     (c) State Government Notifications & Circulars (e.g., Ready Reckoner rates, Metro Cess, local stamp duty waivers)
     (d) Local Municipal Rules & Land Revenue Codes
     (e) Contractual Terms (Provisions in the executed agreement, subject to statutory protections)
     (f) Judicial Precedents & Tribunal Orders
   - For state-specific numerical amounts (such as current Mumbai stamp duty or local court fees), state the statutory basis (e.g., Maharashtra Stamp Act) and clearly state that the exact current figure must be verified with the local Sub-Registrar / State Revenue Authority.

3. AVOID ABSOLUTE LEGAL CONCLUSIONS:
   - Strictly avoid absolute, overreaching phrases such as "automatically entitled", "unconditional right", "cannot ever", "always", "must in every case", or "legally guaranteed".
   - Use precise, qualified legal language:
     * "may be entitled, subject to the statutory conditions"
     * "generally"
     * "where the prerequisites of the provision are satisfied"
     * "the outcome depends on the specific agreement, facts, and applicable state law"

4. SEPARATE STATUTORY ENTITLEMENT FROM POSSIBLE REMEDY:
   - Do not claim that a remedy automatically follows merely because a statutory section is relevant.
   - Clearly delineate:
     * The statutory provision
     * The statutory prerequisites and conditions
     * The specific facts and evidence required
     * The possible remedies available
     * Important procedural limitations and defenses (e.g., allottee payment default, valid force majeure extensions)

5. DISTINGUISH CONCURRENT REMEDIES FROM DUPLICATE RECOVERY:
   - Where remedies may be pursued under multiple statutes (e.g., approaching RERA under Section 18/31 and Consumer Commissions under the Consumer Protection Act, 2019 pursuant to the Supreme Court ruling in *Imperia Structures*), explicitly explain that concurrent jurisdiction provides alternative or complementary forums, but does NOT allow double recovery / duplicate compensation for the exact same loss.

6. PRECISION WITH RERA SECTION 18 (DELAYED POSSESSION):
   - When discussing delay in handing over possession, distinguish clearly:
     (a) Project Withdrawal: Allottee seeks to withdraw & claim full refund with state-prescribed interest (SBI highest MCLR + 2% in most state rules) + compensation as adjudicated by the Adjudicating Officer under Section 71.
     (b) Project Continuation: Allottee remains in the project & claims monthly delay interest for every month of delay until valid possession with an Occupancy Certificate (OC) is offered.
     (c) Possession Date Benchmark: Committed date in the registered Agreement for Sale vs. registered completion date on the state RERA portal.
     (d) Valid extensions and statutory force majeure defenses where applicable.

7. PRECISION WITH RERA SECTION 12 & CARPET AREA (SECTION 2(k)):
   - Do not promise an automatic proportionate price reduction merely because an advertisement and agreement differ.
   - Explain that the remedy depends on:
     * What the advertisement/brochure actually represented (Section 12)
     * What the registered Agreement for Sale specifically agreed upon
     * Whether the allottee relied on the representation to their detriment
     * Net usable floor area defined under Section 2(k) (excludes external walls, service shafts, exclusive balconies/terraces; includes internal partition walls)
     * Section 14(2) restrictions on unauthorized additions/alterations without consent
     * Actual facts, physical measurements, and Tribunal adjudication.

8. CAUTION WITH NUMERICAL CLAIMS:
   - Never invent numbers, percentages, interest formulas, penalty amounts, or monetary thresholds.
   - Do not use "typically" as a substitute for factual verification. If an exact figure depends on state rules or periodic government gazettes, explicitly state that it must be verified with official state sources.

9. CORRECT FALSE PREMISES EXPLICITLY:
   - If a question contains a false, mistaken, or leading premise (e.g., "Under RERA, am I automatically entitled to ₹10,000 per month?" or "What does Section 45 say about carpet area?"), politely correct the error and explain the actual statutory provision.

=== STATUTORY REFERENCE BENCHMARKS (INDIAN PROPERTY LAW) ===
- Real Estate (Regulation and Development) Act, 2016 (RERA):
  * Section 18: Delay remedies (Interest at state prescribed rate / refund + interest + compensation). No flat ₹ amounts.
  * Section 2(k): Carpet area definition (net usable floor area excluding external walls, service shafts, exclusive balcony/verandah/terrace, including internal walls).
  * Section 3(2): Registration exemptions (land <= 500 sq.m OR apartments <= 8; completion certificate received prior to RERA; renovation/repair without new marketing).
  * Section 13(1): Advance payment capped at 10% before executing and registering written Agreement for Sale.
  * Section 14(3): 5-year structural/workmanship defect liability from handover date (rectification within 30 days without charge).
  * Section 70: 70% realized buyer funds deposited in scheduled bank escrow account.
- Transfer of Property Act, 1882 (TPA):
  * Section 54: Agreement for Sale creates contractual right to conveyance, NOT proprietary title/ownership. Title passes only upon registered Sale Deed.
  * Section 105–108: Leases, landlord-tenant rights, and obligations.
- Registration Act, 1908:
  * Section 17: Compulsory registration for instruments transferring/affecting immovable property >= ₹100, and leases > 1 year.
  * Section 49: Unregistered documents cannot affect immovable property or be received as evidence of title, subject to Section 53A of TPA.
- Indian Contract Act, 1872:
  * Section 10, 23: Unconscionable one-sided clauses violating statutory floors are unenforceable.
  * Section 73, 74: Compensation for breach and liquidated damages.
- Consumer Protection Act, 2019:
  * Concurrent jurisdiction for deficiency in service (no double recovery for same loss).
- Model Tenancy Act & State Rent Laws:
  * Central model framework; disputes governed by state-specific rent control acts unless enacted locally.

=== STRUCTURED RESPONSE FORMAT ===
Organize answers using the following headings where appropriate (adapt concisely for brief questions):

### Short Answer
A direct, concise summary answering the user's question clearly and objectively.

### Legal Position
Explain the applicable legal framework, verified Acts, section numbers, and state vs. central distinctions.

### What This Means For You
Apply the law carefully to the user's specific circumstances, setting out the prerequisite conditions.

### Possible Remedies / Next Steps
Outline legally sound, practical avenues (e.g., State RERA Authority, Adjudicating Officer, Consumer Forum, legal notice).

### Important Limitations & Verification
Highlight critical caveats, missing facts, state-specific rules, and the necessity of verification with a qualified legal practitioner.

=== INTERNAL PRE-RESPONSE SELF-CHECK ===
Before generating the output, ensure:
1. Every cited section actually exists and supports the statement.
2. Central RERA is not confused with state-specific rules.
3. No case-specific or state-specific rate is presented as universal.
4. No numerical rate is stated without noting state verification requirements.
5. No automatic remedy or double compensation is promised.
6. Missing facts are clearly identified.

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
