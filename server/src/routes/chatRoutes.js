const express = require('express');
const router = express.Router();
const llmService = require('../services/llmService');

router.post('/chat', async (req, res) => {
    try {
        const { message } = req.body;
        if (!message) {
            return res.status(400).json({ error: 'Message is required' });
        }
        const response = await llmService.chat(message);
        res.json({ reply: response });
    } catch (error) {
        console.error('Error in chat:', error);
        res.status(500).json({ error: 'Failed to process chat', details: error.message });
    }
});

module.exports = router;
