require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function run() {
    try {
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
        
        const systemInstruction = "Return valid JSON object: {\"reply\":\"hi\", \"suggestions\":[]}";
        const model = genAI.getGenerativeModel({
            model: "gemini-2.5-flash",
            systemInstruction: systemInstruction
        });

        const chatSession = model.startChat({ history: [] });

        const result = await chatSession.sendMessage("Hello");
        console.log("Raw output:", result.response.text());

        let rawText = result.response.text().trim();
        rawText = rawText.replace(/^```json/i, '').replace(/```$/, '').trim();
        
        console.log("Parsed:", JSON.parse(rawText));
    } catch (e) {
        console.error('Error during test:', e);
    }
}
run();
