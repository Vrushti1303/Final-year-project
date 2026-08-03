const express = require('express');
const router = express.Router();
const Checklist = require('../models/Checklist');
const { requireAuth } = require('../middleware/authMiddleware');

router.get('/checklists/:type', requireAuth, async (req, res) => {
    try {
        const type = req.params.type;
        const userId = req.user.userId;
        let checklist = await Checklist.findOne({ type, userId });
        
        // Data seeding if not found for this user
        if (!checklist) {
            if (type === 'buying-resale') {
                checklist = new Checklist({
                    userId,
                    type: 'buying-resale',
                    title: 'Buying a Resale Flat',
                    items: [
                        { id: '1', title: 'Verify Title Deed (Chain of Documents)', isCompleted: false },
                        { id: '2', title: 'Check Occupancy Certificate (OC)', isCompleted: false },
                        { id: '3', title: 'Ensure No Pending Society Dues', isCompleted: false },
                        { id: '4', title: 'Draft Agreement to Sale', isCompleted: false },
                        { id: '5', title: 'Pay Stamp Duty & Registration', isCompleted: false }
                    ]
                });
                await checklist.save();
            } else {
                 return res.status(404).json({ error: 'Checklist not found' });
            }
        }
        res.json(checklist);
    } catch (error) {
        console.error('Error fetching checklist:', error);
        res.status(500).json({ error: 'Failed to fetch checklist', details: error.message });
    }
});

router.put('/checklists/:type/items/:itemId', requireAuth, async (req, res) => {
    try {
        const { type, itemId } = req.params;
        const { isCompleted } = req.body;
        const userId = req.user.userId;

        const checklist = await Checklist.findOne({ type, userId });
        if (!checklist) {
            return res.status(404).json({ error: 'Checklist not found' });
        }

        const item = checklist.items.find(i => i.id === itemId);
        if (!item) {
            return res.status(404).json({ error: 'Item not found in checklist' });
        }

        item.isCompleted = isCompleted;
        await checklist.save();

        res.json({ message: 'Checklist updated successfully', checklist });
    } catch (error) {
        console.error('Error updating checklist:', error);
        res.status(500).json({ error: 'Failed to update checklist', details: error.message });
    }
});

module.exports = router;
