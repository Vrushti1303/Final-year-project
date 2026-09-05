const express = require('express');
const router = express.Router();
const StampDuty = require('../models/StampDuty');
const jwt = require('jsonwebtoken');

function getUserIdFromReq(req) {
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
        try {
            const token = authHeader.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_super_secret_jwt_key_here');
            if (decoded && decoded.userId) return decoded.userId;
        } catch (e) {
            // ignore token error
        }
    }
    return (req.body && req.body.userId) ? req.body.userId : 'usr_ms7rjm9vn6ins';
}

// POST /api/stamp-duty - Save a calculation record to MongoDB
router.post('/stamp-duty', async (req, res) => {
    try {
        const userId = getUserIdFromReq(req);
        const {
            propertyType,
            state,
            agreementValue,
            circleRate,
            applicableMarketValue,
            gender,
            firstTimeBuyer,
            stampDutyRate,
            stampDutyAmount,
            registrationRate,
            registrationAmount,
            totalPayable
        } = req.body;

        const record = new StampDuty({
            userId,
            propertyType,
            state,
            agreementValue,
            circleRate: circleRate || 0,
            applicableMarketValue,
            gender,
            firstTimeBuyer,
            stampDutyRate,
            stampDutyAmount,
            registrationRate,
            registrationAmount,
            totalPayable,
            createdAt: new Date()
        });

        const savedRecord = await record.save();
        res.status(201).json({ message: 'Calculation saved to database', calculation: savedRecord });
    } catch (error) {
        console.error('Error saving stamp duty calculation:', error);
        res.status(500).json({ error: 'Failed to save calculation', details: error.message });
    }
});

// GET /api/stamp-duty - Fetch past calculation history for the user from MongoDB
router.get('/stamp-duty', async (req, res) => {
    try {
        const userId = getUserIdFromReq(req);
        const history = await StampDuty.find({ userId }).sort({ createdAt: -1 }).limit(10);
        res.json(history);
    } catch (error) {
        console.error('Error fetching stamp duty history:', error);
        res.status(500).json({ error: 'Failed to fetch stamp duty history', details: error.message });
    }
});

module.exports = router;
