require('dotenv').config();
const mongoose = require('mongoose');
const llmService = require('../src/services/llmService');

const testCases = [
    {
        name: "1. False Premise & RERA Section 18",
        query: "Under RERA, am I automatically entitled to ₹10,000 for every month of delay by the builder?"
    },
    {
        name: "2. Carpet Area Definition (RERA Section 2(k))",
        query: "How is carpet area defined under RERA? Does it include balconies and external walls?"
    },
    {
        name: "3. RERA Project Registration Exemptions (Section 3(2))",
        query: "When is a real estate project exempt from RERA registration?"
    },
    {
        name: "4. Agreement for Sale vs Sale Deed (TPA Section 54)",
        query: "Does signing an Agreement for Sale make me the legal owner of the flat before the Sale Deed is registered?"
    },
    {
        name: "5. Compulsory Registration (Registration Act Section 17)",
        query: "Is it legally mandatory to register a property sale agreement and a 2-year lease under the Registration Act?"
    },
    {
        name: "6. State-Specific Maharashtra Stamp Duty",
        query: "What is the exact fixed stamp duty percentage for buying a resale flat in Mumbai, Maharashtra?"
    },
    {
        name: "7. Deliberately Fabricated Section Trap",
        query: "Under Section 99 of RERA, can a builder forfeit 50% of the flat price if the loan is delayed?"
    }
];

async function runTests() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log("Connected to MongoDB for Legal AI Verification Tests\n");

        for (const tc of testCases) {
            console.log(`==================================================`);
            console.log(`TEST: ${tc.name}`);
            console.log(`QUERY: "${tc.query}"`);
            console.log(`--------------------------------------------------`);

            const startTime = Date.now();
            const res = await llmService.chat([
                { role: 'user', text: tc.query }
            ]);
            const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);

            console.log(`Response received in ${elapsed}s:\n`);
            console.log(res.reply);
            console.log(`\nSuggestions:`, res.suggestions);
            console.log(`==================================================\n`);
        }

        await mongoose.disconnect();
        console.log("All legal QA tests completed successfully.");
    } catch (e) {
        console.error("Test execution failed:", e);
        process.exit(1);
    }
}

runTests();
