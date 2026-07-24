const express = require('express');
const router = express.Router();
const Checklist = require('../models/Checklist');

router.get('/checklists/:type', async (req, res) => {
    try {
        const type = req.params.type;
        let checklist = await Checklist.findOne({ type });
        
        // Mock data seeding if not found
        if (!checklist) {
            if (type === 'buying-resale') {
                checklist = new Checklist({
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

module.exports = router;
