const express = require('express');
const router = express.Router();
const llmService = require('../services/llmService');

router.post('/scan', async (req, res) => {
    try {
        const { text } = req.body;
        if (!text) {
            return res.status(400).json({ error: 'Text is required' });
        }
        const analysis = await llmService.analyzeContract(text);
        res.json(analysis);
    } catch (error) {
        console.error('Error analyzing document:', error);
        if (error.status === 429) {
            return res.status(429).json({ error: 'Rate limit reached. Please wait a moment before trying again.' });
        }
        res.status(500).json({ error: 'Failed to analyze document', details: error.message });
    }
});

router.post('/explain', async (req, res) => {
    try {
        const { context, snippet } = req.body;
        if (!context || !snippet) {
            return res.status(400).json({ error: 'Context and snippet are required' });
        }
        const explanation = await llmService.explainSnippet(context, snippet);
        res.json({ explanation });
    } catch (error) {
        console.error('Error explaining snippet:', error);
        if (error.status === 429) {
            return res.status(429).json({ error: 'Rate limit reached. Please wait a moment before trying again.' });
        }
        res.status(500).json({ error: 'Failed to explain snippet', details: error.message });
    }
});

module.exports = router;
