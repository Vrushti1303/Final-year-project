const { GoogleGenerativeAI } = require('@google/generative-ai');

const getGenerativeModel = () => {
    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'your_gemini_api_key_here') {
        throw new Error("GEMINI_API_KEY is not configured.");
    }
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    return genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
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

exports.chat = async (message) => {
    const model = getGenerativeModel();
    const prompt = `
        You are an expert Indian Real Estate legal advisor and contract drafter.
        Answer the following query or draft the requested document based on RERA and Indian property laws.
        Keep it clear and legally sound.
        
        User Query:
        ${message}
    `;
    const result = await model.generateContent(prompt);
    return result.response.text();
};
