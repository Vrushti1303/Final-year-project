require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function run() {
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    // Actually, there isn't a listModels on genAI in the node SDK directly, wait there is:
    // But usually you just hit the REST API to see it.
    console.log("Checking if model is text-embedding-004");
}
run();
