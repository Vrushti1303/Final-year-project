require('dotenv').config();
const mongoose = require('mongoose');
const Document = require('../src/models/Document');

async function seed() {
    try {
        await mongoose.connect(process.env.MONGODB_URI, { family: 4 });
        console.log('Connected to MongoDB.');

        const userId = 'usr_ms7rjm9vn6ins'; // Vrushti Patel

        const count = await Document.countDocuments({ userId });
        if (count > 0) {
            console.log(`User already has ${count} documents. Skipping seed.`);
            process.exit(0);
        }

        console.log('Seeding initial documents for user:', userId);

        const sampleDocs = [
            {
                userId,
                title: 'Sale Agreement – Unit 101',
                originalText: `AGREEMENT FOR SALE
This Agreement for Sale is executed on 15 August 2026 by and between:
Promoter: Apex Realty Ventures Pvt Ltd, RERA Reg No. PRM/KA/RERA/1251/310/PR/200122/003180.
Allottee: Vrushti Patel, resident of Mumbai.
Subject Property: Apartment Unit No. 101, Tower A, Grand Palms Residency.
1. The Promoter confirms receipt of 10% advance booking amount in compliance with Section 13(1) of RERA Act 2016.
2. The balance consideration shall be payable in construction-linked milestone installments.
3. Possession shall be delivered on or before 31 December 2026. In case of delay, statutory interest shall be payable at SBI MCLR + 2%.
4. The allottee shall have undisputed title warranty and clear occupancy certificate prior to handover.`,
                riskLevel: 'Low Risk',
                docSize: '1.4 MB',
                analysis: [
                    {
                        text: "Promoter confirms receipt of 10% advance booking amount in compliance with Section 13(1) of RERA Act 2016.",
                        category: "Green",
                        reason: "Complies with statutory 10% limit on advance collections prior to formal sale agreement execution."
                    },
                    {
                        text: "In case of delay, statutory interest shall be payable at SBI MCLR + 2%.",
                        category: "Green",
                        reason: "Standard RERA compensation mandate for handover delay protection."
                    },
                    {
                        text: "The allottee shall have undisputed title warranty and clear occupancy certificate prior to handover.",
                        category: "Green",
                        reason: "Explicit title warranty ensures legal protection against promoter encumbrances."
                    }
                ],
                createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) // 2 days ago
            },
            {
                userId,
                title: 'Builder Agreement – Unit 102',
                originalText: `BUILDER BUYER AGREEMENT
Property: Commercial Complex Unit 102, Sector 62.
1. The developer reserves a 6-month grace period for construction delays due to material supply constraints.
2. Price escalation clause: Any increase in steel and cement costs exceeding 15% shall be passed on to the buyer.
3. Carpet area is subject to a +/- 3% architectural variation at the time of final measurement.`,
                riskLevel: 'Medium Risk',
                docSize: '2.8 MB',
                analysis: [
                    {
                        text: "The developer reserves a 6-month grace period for construction delays due to material supply constraints.",
                        category: "Yellow",
                        reason: "Grace period exceeds typical RERA allowable norms; may delay legal possession remedies."
                    },
                    {
                        text: "Any increase in steel and cement costs exceeding 15% shall be passed on to the buyer.",
                        category: "Yellow",
                        reason: "Cost escalation clause shifts financial market volatility onto the purchaser."
                    },
                    {
                        text: "Carpet area is subject to a +/- 3% architectural variation at the time of final measurement.",
                        category: "Yellow",
                        reason: "Carpet area variation should be linked to proportional consideration adjustments."
                    }
                ],
                createdAt: new Date(Date.now() - 3 * 60 * 60 * 1000) // 3 hours ago
            },
            {
                userId,
                title: 'Lease Agreement – Unit 103',
                originalText: `RESIDENTIAL LEASE AGREEMENT
Premises: Apartment 103, Skyline Heights.
1. The lessor may terminate this tenancy with 7 days written notice without assigning cause.
2. The security deposit of 6 months rent is strictly non-refundable in the event of early termination by tenant.
3. The tenant indemnifies the lessor against all structural wear, tear, and municipal levy revisions.`,
                riskLevel: 'High Risk',
                docSize: '840 KB',
                analysis: [
                    {
                        text: "The lessor may terminate this tenancy with 7 days written notice without assigning cause.",
                        category: "Red",
                        reason: "Unilateral short-notice termination severely compromises tenant security of tenure."
                    },
                    {
                        text: "The security deposit of 6 months rent is strictly non-refundable in the event of early termination by tenant.",
                        category: "Red",
                        reason: "Unreasonable deposit forfeiture clause; penal in nature and likely unenforceable."
                    },
                    {
                        text: "The tenant indemnifies the lessor against all structural wear, tear, and municipal levy revisions.",
                        category: "Red",
                        reason: "Shifts structural maintenance and statutory property tax obligations onto the lessee."
                    }
                ],
                createdAt: new Date(Date.now() - 26 * 60 * 60 * 1000) // Yesterday
            }
        ];

        await Document.insertMany(sampleDocs);
        console.log('Seeded 3 real analyzed documents successfully.');
    } catch (err) {
        console.error('Error seeding documents:', err);
    } finally {
        await mongoose.disconnect();
    }
}

seed();
