const express = require('express');
const router = express.Router();
const llmService = require('../services/llmService');

router.post('/chat', async (req, res) => {
    try {
        const { history } = req.body;
        if (!history || !Array.isArray(history) || history.length === 0) {
            return res.status(400).json({ error: 'History array is required' });
        }
        const response = await llmService.chat(history);
        res.json(response);
    } catch (error) {
        console.error('Error in chat:', error);
        res.status(500).json({ error: 'Failed to process chat', details: error.message });
    }
});

module.exports = router;
