const express = require('express');
const router = express.Router();
const Checklist = require('../models/Checklist');
const { requireAuth } = require('../middleware/authMiddleware');
const llmService = require('../services/llmService');

// 1. Fetch all checklists for logged-in user
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

// 2. Fetch single checklist by type
router.get('/checklists/:type', requireAuth, async (req, res) => {
    try {
        const type = req.params.type;
        const userId = req.user.userId;
        let checklist = await Checklist.findOne({ type, userId });
        
        if (!checklist) {
             return res.status(404).json({ error: 'Checklist not found' });
        }
        res.json(checklist);
    } catch (error) {
        console.error('Error fetching checklist:', error);
        res.status(500).json({ error: 'Failed to fetch checklist', details: error.message });
    }
});

// 3. Update single item completion status
router.put('/checklists/:type/items/:itemId', requireAuth, async (req, res) => {
    try {
        const { type, itemId } = req.params;
        const { isCompleted } = req.body;
        const userId = req.user.userId;

        const checklist = await Checklist.findOne({ type, userId });
        if (!checklist) {
            return res.status(404).json({ error: 'Checklist not found' });
        }

        const item = checklist.items.find(i => (i.id && i.id.toString() === itemId.toString()) || (i._id && i._id.toString() === itemId.toString()));
        if (!item) {
            return res.status(404).json({ error: 'Item not found in checklist' });
        }

        item.isCompleted = Boolean(isCompleted);
        await checklist.save();

        res.json({ message: 'Checklist updated successfully', checklist });
    } catch (error) {
        console.error('Error updating checklist item:', error);
        res.status(500).json({ error: 'Failed to update checklist item', details: error.message });
    }
});

// 4. Add new item to a checklist
router.post('/checklists/:type/items', requireAuth, async (req, res) => {
    try {
        const { type } = req.params;
        const { title } = req.body;
        const userId = req.user.userId;

        if (!title || !title.trim()) {
            return res.status(400).json({ error: 'Title is required' });
        }

        const checklist = await Checklist.findOne({ type, userId });
        if (!checklist) {
            return res.status(404).json({ error: 'Checklist not found' });
        }

        const newItem = {
            id: Date.now().toString(),
            title: title.trim(),
            isCompleted: false
        };

        checklist.items.push(newItem);
        await checklist.save();

        res.json({ message: 'Item added successfully', checklist, item: newItem });
    } catch (error) {
        console.error('Error adding checklist item:', error);
        res.status(500).json({ error: 'Failed to add checklist item', details: error.message });
    }
});

// 5. Delete single item from a checklist
router.delete('/checklists/:type/items/:itemId', requireAuth, async (req, res) => {
    try {
        const { type, itemId } = req.params;
        const userId = req.user.userId;

        const checklist = await Checklist.findOne({ type, userId });
        if (!checklist) {
            return res.status(404).json({ error: 'Checklist not found' });
        }

        const initialLength = checklist.items.length;
        checklist.items = checklist.items.filter(
            i => !( (i.id && i.id.toString() === itemId.toString()) || (i._id && i._id.toString() === itemId.toString()) )
        );

        if (checklist.items.length === initialLength) {
            return res.status(404).json({ error: 'Item not found in checklist' });
        }

        await checklist.save();
        res.json({ message: 'Item deleted successfully', checklist });
    } catch (error) {
        console.error('Error deleting checklist item:', error);
        res.status(500).json({ error: 'Failed to delete checklist item', details: error.message });
    }
});

// 6. Delete entire checklist
router.delete('/checklists/:type', requireAuth, async (req, res) => {
    try {
        const { type } = req.params;
        const userId = req.user.userId;

        const result = await Checklist.findOneAndDelete({ type, userId });
        if (!result) {
            return res.status(404).json({ error: 'Checklist not found' });
        }

        res.json({ message: 'Checklist deleted successfully', type });
    } catch (error) {
        console.error('Error deleting checklist:', error);
        res.status(500).json({ error: 'Failed to delete checklist', details: error.message });
    }
});

// 7. Rename checklist title
router.put('/checklists/:type/rename', requireAuth, async (req, res) => {
    try {
        const { type } = req.params;
        const { title } = req.body;
        const userId = req.user.userId;

        if (!title || !title.trim()) {
            return res.status(400).json({ error: 'Title is required' });
        }

        const checklist = await Checklist.findOne({ type, userId });
        if (!checklist) {
            return res.status(404).json({ error: 'Checklist not found' });
        }

        checklist.title = title.trim();
        await checklist.save();

        res.json({ message: 'Checklist renamed successfully', checklist });
    } catch (error) {
        console.error('Error renaming checklist:', error);
        res.status(500).json({ error: 'Failed to rename checklist', details: error.message });
    }
});

// 8. Generate AI Checklist
router.post('/checklists/generate', requireAuth, async (req, res) => {
    try {
        const { prompt } = req.body;
        const userId = req.user.userId;

        if (!prompt || !prompt.trim()) {
            return res.status(400).json({ error: 'Prompt is required' });
        }

        let items;
        try {
            items = await llmService.generateChecklist(prompt);
        } catch (llmErr) {
            console.error('LLM generation error, using fallback legal rules:', llmErr);
            items = [
                { id: "1", title: "Verify Title Deed & 30-Year Chain of Documents" },
                { id: "2", title: "Obtain Encumbrance Certificate (EC) from Sub-Registrar" },
                { id: "3", title: "Check RERA Registration & Approved Sanction Plan" },
                { id: "4", title: "Verify Occupancy Certificate (OC) & Completion Certificate (CC)" },
                { id: "5", title: "Inspect Society NOC & Share Certificate / Khata Transfer" },
                { id: "6", title: "Draft & Execute Registered Agreement for Sale / Conveyance Deed" }
            ];
        }

        const cleanItems = (items || []).map((item, idx) => ({
            id: (item.id || (idx + 1)).toString(),
            title: item.title || 'Legal Due Diligence Task',
            isCompleted: false
        }));

        const newType = 'custom_' + Date.now();
        const checklist = new Checklist({
            userId,
            type: newType,
            title: prompt.trim().substring(0, 45) + (prompt.trim().length > 45 ? '...' : ''),
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
