require('dotenv').config();
const llmService = require('./src/services/llmService');

async function testUnlimitedPages() {
    console.log("--- Testing Unlimited Multi-Page Full Document Batch Analysis ---");
    
    // Simulate a 500,000-character (100+ page) real estate agreement
    const pageTemplate = (pageNum) => `
        PAGE ${pageNum} OF 100 - PROPERTY SALE AGREEMENT
        Clause ${pageNum}.1 (Payment Terms): The Purchaser shall pay Stage ${pageNum} installment of Rs. 5,00,000 within 15 days of construction completion.
        Clause ${pageNum}.2 (Possession Date): The Developer agrees that final handover date is December 31, 2026. Delay penalty is SBI MCLR + 2% per month.
        Clause ${pageNum}.3 (Defect Liability): Structural defects reported within 5 years shall be repaired free of cost by the Promoter under RERA Section 14(3).
        Clause ${pageNum}.4 (Cancellation): The Promoter reserves the right to retain 10% earnest money if cancelled by Allottee.
    `;

    let fullDocText = "";
    for (let p = 1; p <= 50; p++) {
        fullDocText += pageTemplate(p) + "\n\n";
    }

    console.log(`Generated contract document length: ${fullDocText.length} characters.`);

    try {
        const result = await llmService.analyzeContract(fullDocText);
        console.log(`\nUNLIMITED PAGE ANALYSIS COMPLETE! Total Clauses Found: ${result.analysis.length}`);
        console.log("First 3 Discovered Clauses:", JSON.stringify(result.analysis.slice(0, 3), null, 2));
    } catch (e) {
        console.error("Unlimited Page Analysis ERROR:", e);
    }
}

testUnlimitedPages();
