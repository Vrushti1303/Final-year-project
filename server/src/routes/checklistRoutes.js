const express = require('express');
const router = express.Router();
const Checklist = require('../models/Checklist');
const { requireAuth } = require('../middleware/authMiddleware');
const llmService = require('../services/llmService');

router.get('/checklists', requireAuth, async (req, res) => {
    try {
        const userId = req.user.userId;
        const checklists = await Checklist.find({ userId }).sort({ _id: -1 });
        res.json(checklists);
    } catch (error) {
        console.error('Error fetching checklists:', error);
        res.status(500).json({ error: 'Failed to fetch checklists', details: error.message });
    }
});

router.get('/checklists/:type', requireAuth, async (req, res) => {
    try {
        const type = req.params.type;
        const userId = req.user.userId;
        let checklist = await Checklist.findOne({ type, userId });
        
        // If not found, return 404. We no longer seed dummy data.
        if (!checklist) {
             return res.status(404).json({ error: 'Checklist not found' });
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

router.post('/checklists/:type/items', requireAuth, async (req, res) => {
    try {
        const { type } = req.params;
        const { title } = req.body;
        const userId = req.user.userId;

        if (!title) {
            return res.status(400).json({ error: 'Title is required' });
        }

        const checklist = await Checklist.findOne({ type, userId });
        if (!checklist) {
            return res.status(404).json({ error: 'Checklist not found' });
        }

        const newItem = {
            id: Date.now().toString(),
            title: title,
            isCompleted: false
        };

        checklist.items.push(newItem);
        await checklist.save();

        res.json({ message: 'Item added successfully', checklist });
    } catch (error) {
        console.error('Error adding checklist item:', error);
        res.status(500).json({ error: 'Failed to add checklist item', details: error.message });
    }
});

router.post('/checklists/generate', requireAuth, async (req, res) => {
    try {
        const { prompt } = req.body;
        const userId = req.user.userId;

        if (!prompt) {
            return res.status(400).json({ error: 'Prompt is required' });
        }

        const items = await llmService.generateChecklist(prompt);
        
        // Ensure items have isCompleted: false
        const cleanItems = items.map(item => ({
            id: item.id.toString(),
            title: item.title,
            isCompleted: false
        }));

        const newType = 'custom_' + Date.now();
        const checklist = new Checklist({
            userId,
            type: newType,
            title: prompt.substring(0, 40) + (prompt.length > 40 ? '...' : ''),
            items: cleanItems
        });

        await checklist.save();
        res.json(checklist);
    } catch (error) {
        console.error('Error generating checklist:', error);
        res.status(500).json({ error: 'Failed to generate checklist', details: error.message });
    }
});

module.exports = router;
