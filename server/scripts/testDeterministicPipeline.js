require('dotenv').config();
const mongoose = require('mongoose');
const llmService = require('../src/services/llmService');
const Document = require('../src/models/Document');

const SAMPLE_CONTRACT_1 = `
AGREEMENT FOR SALE

Clause 1: Booking Amount and Payment Milestones
The Purchaser has paid a sum of INR 5,00,000 (Rupees Five Lakhs only) representing 10% of the total purchase price as earnest booking advance. The balance purchase consideration shall be paid in installments linked to construction milestones as stipulated in Schedule B.

Clause 2: Possession Date and Delay Compensation
The Developer undertakes to complete construction and handover vacant possession of the Apartment on or before December 31, 2026. In the event of delay in handing over possession beyond the agreed period, the Developer shall pay interest at the rate of State Bank of India highest marginal cost of lending rate (MCLR) plus 2% per annum for every month of delay until actual handover under Section 18 of RERA.

Clause 3: Defect Liability Warranty
Any structural defect or any other defect in workmanship, quality, or provision of services noticed within a period of 5 (five) years from the date of handing over possession shall be rectified by the Promoter at its own cost within thirty days as mandated under Section 14(3) of the Real Estate (Regulation and Development) Act, 2016.

Clause 4: Cancellation and Forfeiture Clause
If the Purchaser fails to make timely payment of any installment for more than 60 days, the Developer reserves the unilateral right to cancel this allotment and forfeit 100% of all amounts deposited by the Purchaser without any opportunity for hearing or refund.

Clause 5: Common Areas and Open Parking Allocation
The Promoter retains absolute ownership rights over open parking spaces and all common terrace areas, and reserves the unilateral right to sell open parking spaces independently to non-residents.
`;

const SAMPLE_CONTRACT_2 = `
LEASE AGREEMENT

1. Term and Rent
The Landlord hereby lets and the Tenant takes the residential premises for a term of 11 months commencing from October 1, 2026 at a monthly rent of INR 35,000 payable in advance on or before the 5th of each calendar month.

2. Security Deposit
The Tenant has deposited an interest-free refundable security deposit of INR 1,00,000 with the Landlord, which shall be refunded within 7 days of peaceful vacation of the premises after adjusting any unpaid utility dues or structural damages.

3. Maintenance and Utilities
The Tenant shall pay actual electricity and water consumption charges according to meter readings directly to the respective authorities.
`;

async function runTests() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI, { family: 4 });
        console.log('Connected to MongoDB.');

        const userA = 'test_user_alpha_' + Date.now();
        const userB = 'test_user_beta_' + Date.now();

        console.log('\n========================================');
        console.log('TEST 1: 3 REPEATED SCANS OF EXACT SAME DOCUMENT (USER A)');
        console.log('========================================');

        console.log('\n--- SCAN 1 (User A) ---');
        const scan1 = await llmService.analyzeContractPipeline({
            text: SAMPLE_CONTRACT_1,
            customTitle: 'Sample Agreement 1',
            sourceType: 'Text Description',
            userId: userA
        });

        console.log(`Scan 1 Result:
  cacheHit: ${scan1.cacheHit}
  fileHash: ${scan1.fileHash}
  totalClauseCount: ${scan1.totalClauseCount}
  highRiskCount: ${scan1.highRiskCount}
  cautionCount: ${scan1.cautionCount}
  compliantCount: ${scan1.compliantCount}`);

        console.log('\n--- SCAN 2 (User A - should hit cache) ---');
        const scan2 = await llmService.analyzeContractPipeline({
            text: SAMPLE_CONTRACT_1,
            customTitle: 'Sample Agreement 1',
            sourceType: 'Text Description',
            userId: userA
        });

        console.log(`Scan 2 Result:
  cacheHit: ${scan2.cacheHit}
  fileHash: ${scan2.fileHash}
  totalClauseCount: ${scan2.totalClauseCount}
  highRiskCount: ${scan2.highRiskCount}
  cautionCount: ${scan2.cautionCount}
  compliantCount: ${scan2.compliantCount}`);

        console.log('\n--- SCAN 3 (User A - should hit cache) ---');
        const scan3 = await llmService.analyzeContractPipeline({
            text: SAMPLE_CONTRACT_1,
            customTitle: 'Sample Agreement 1',
            sourceType: 'Text Description',
            userId: userA
        });

        console.log(`Scan 3 Result:
  cacheHit: ${scan3.cacheHit}
  fileHash: ${scan3.fileHash}
  totalClauseCount: ${scan3.totalClauseCount}
  highRiskCount: ${scan3.highRiskCount}
  cautionCount: ${scan3.cautionCount}
  compliantCount: ${scan3.compliantCount}`);

        // Assertions for Test 1
        if (scan1.cacheHit !== false) throw new Error('Scan 1 should not be a cache hit');
        if (scan2.cacheHit !== true) throw new Error('Scan 2 MUST be a cache hit');
        if (scan3.cacheHit !== true) throw new Error('Scan 3 MUST be a cache hit');
        if (scan1.fileHash !== scan2.fileHash || scan2.fileHash !== scan3.fileHash) throw new Error('File hashes do not match');
        if (scan1.totalClauseCount !== scan2.totalClauseCount || scan2.totalClauseCount !== scan3.totalClauseCount) throw new Error('Total clause counts do not match');
        if (scan1.highRiskCount !== scan2.highRiskCount || scan2.highRiskCount !== scan3.highRiskCount) throw new Error('High risk counts do not match');
        if (scan1.cautionCount !== scan2.cautionCount || scan2.cautionCount !== scan3.cautionCount) throw new Error('Caution counts do not match');
        if (scan1.compliantCount !== scan2.compliantCount || scan2.compliantCount !== scan3.compliantCount) throw new Error('Compliant counts do not match');

        console.log('✅ TEST 1 PASSED: Repeated scans produced 100% identical outputs with instant cache hits.');

        console.log('\n========================================');
        console.log('TEST 2: USER ISOLATION (USER B UPLOADS SAME DOCUMENT)');
        console.log('========================================');

        const scanUserB = await llmService.analyzeContractPipeline({
            text: SAMPLE_CONTRACT_1,
            customTitle: 'Sample Agreement 1',
            sourceType: 'Text Description',
            userId: userB
        });

        console.log(`User B Scan Result:
  cacheHit: ${scanUserB.cacheHit}
  userId: ${userB}
  docId: ${scanUserB.documentId}
  userA_docId: ${scan1.documentId}`);

        if (scanUserB.cacheHit !== false) throw new Error('User B first scan should be a cache miss for User B');
        if (String(scanUserB.documentId) === String(scan1.documentId)) throw new Error('User B received User A document ID!');
        if (scanUserB.fileHash !== scan1.fileHash) throw new Error('File hash should be identical for identical content');

        const scanUserB2 = await llmService.analyzeContractPipeline({
            text: SAMPLE_CONTRACT_1,
            customTitle: 'Sample Agreement 1',
            sourceType: 'Text Description',
            userId: userB
        });
        if (scanUserB2.cacheHit !== true) throw new Error('User B second scan MUST be a cache hit for User B');
        if (String(scanUserB2.documentId) !== String(scanUserB.documentId)) throw new Error('User B cache hit returned wrong document ID');

        console.log('✅ TEST 2 PASSED: User isolation is fully respected (userId + fileHash).');

        console.log('\n========================================');
        console.log('TEST 3: DIFFERENT FILE / CONTENT PRODUCES DIFFERENT HASH');
        console.log('========================================');

        const scanDiff = await llmService.analyzeContractPipeline({
            text: SAMPLE_CONTRACT_2,
            customTitle: 'Sample Lease Agreement 2',
            sourceType: 'Text Description',
            userId: userA
        });

        console.log(`Different Doc Scan Result:
  cacheHit: ${scanDiff.cacheHit}
  fileHash: ${scanDiff.fileHash}
  userA_prevHash: ${scan1.fileHash}`);

        if (scanDiff.fileHash === scan1.fileHash) throw new Error('Different files produced identical hash!');
        if (scanDiff.cacheHit !== false) throw new Error('Different file should not hit cache');

        console.log('✅ TEST 3 PASSED: Different documents produce unique hashes and independent analyses.');

        console.log('\n========================================');
        console.log('TEST 4: COUNT CALCULATION ACCURACY AND CLAUSE INTEGRITY');
        console.log('========================================');

        for (const doc of [scan1, scanDiff]) {
            const high = doc.analysis.filter(c => c.riskLevel === 'HIGH_RISK').length;
            const caution = doc.analysis.filter(c => c.riskLevel === 'CAUTION').length;
            const comp = doc.analysis.filter(c => c.riskLevel === 'COMPLIANT').length;
            const total = doc.analysis.length;

            console.log(`Doc ${doc.fileHash.substring(0, 8)}...: High=${high}, Caution=${caution}, Compliant=${comp}, Total=${total}`);
            if (doc.highRiskCount !== high) throw new Error('highRiskCount mismatch');
            if (doc.cautionCount !== caution) throw new Error('cautionCount mismatch');
            if (doc.compliantCount !== comp) throw new Error('compliantCount mismatch');
            if (doc.totalClauseCount !== total) throw new Error('totalClauseCount mismatch');
            if (total !== (high + caution + comp)) throw new Error('Total does not equal sum of parts');

            // Verify clause IDs are structured
            for (let i = 0; i < doc.analysis.length; i++) {
                const expectedId = `CLAUSE-${String(i + 1).padStart(3, '0')}`;
                if (doc.analysis[i].clauseId !== expectedId) {
                    throw new Error(`Clause ID mismatch at index ${i}: expected ${expectedId}, got ${doc.analysis[i].clauseId}`);
                }
            }
        }

        console.log('✅ TEST 4 PASSED: Risk counts and clause IDs are 100% consistent and derived from array.');

        console.log('\n========================================');
        console.log('ALL TESTS PASSED SUCCESSFULLY! 🎉');
        console.log('========================================');

    } catch (e) {
        console.error('❌ Test failed:', e);
        process.exit(1);
    } finally {
        await mongoose.disconnect();
    }
}

runTests();
