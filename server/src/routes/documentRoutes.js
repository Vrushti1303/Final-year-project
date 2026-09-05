const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const llmService = require('../services/llmService');
const Document = require('../models/Document');

function getUserIdFromReq(req) {
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
        try {
            const token = authHeader.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_super_secret_jwt_key_here');
            if (decoded && decoded.userId) return decoded.userId;
        } catch (e) {
            // ignore token error, fallback
        }
    }
    return (req.body && req.body.userId) ? req.body.userId : 'usr_ms7rjm9vn6ins'; // Default to Vrushti Patel's userId
}

router.post('/scan', async (req, res) => {
    try {
        const { text, title: customTitle } = req.body;
        if (!text) {
            return res.status(400).json({ error: 'Text is required' });
        }
        const analysis = await llmService.analyzeContract(text);
        const userId = getUserIdFromReq(req);

        // Derive overall risk level
        const items = analysis.analysis || [];
        let riskLevel = 'Low Risk';
        if (items.some(i => (i.category || '').toLowerCase() === 'red')) {
            riskLevel = 'High Risk';
        } else if (items.some(i => (i.category || '').toLowerCase() === 'yellow')) {
            riskLevel = 'Medium Risk';
        }

        // Derive document title
        let title = customTitle;
        if (!title || !title.trim()) {
            const firstLine = text.trim().split('\n')[0].replace(/[#*_-]/g, '').trim();
            title = firstLine.length > 50 ? firstLine.substring(0, 47) + '...' : (firstLine || 'Property Agreement');
        }

        // Calculate doc size
        const bytes = Buffer.byteLength(text, 'utf8');
        const docSize = bytes >= 1048576 
            ? `${(bytes / 1048576).toFixed(1)} MB` 
            : `${Math.max(1, Math.round(bytes / 1024))} KB`;

        // Save to MongoDB
        let savedDoc = null;
        try {
            const newDoc = new Document({
                userId,
                title,
                originalText: text,
                riskLevel,
                docSize,
                analysis: items,
                createdAt: new Date()
            });
            savedDoc = await newDoc.save();
        } catch (dbErr) {
            console.warn('Failed to save document to DB (continuing with analysis response):', dbErr.message);
        }

        res.json({
            analysis: items,
            document: savedDoc,
            documentId: savedDoc ? savedDoc._id : null
        });
    } catch (error) {
        console.error('Error analyzing document:', error);
        if (error.status === 429) {
            return res.status(429).json({ error: 'Rate limit reached. Please wait a moment before trying again.' });
        }
        res.status(500).json({ error: 'Failed to analyze document', details: error.message });
    }
});

router.get('/documents', async (req, res) => {
    try {
        const userId = getUserIdFromReq(req);
        // Find docs for current user, or fallback to recent docs in system if user has none
        let docs = await Document.find({ userId }).sort({ createdAt: -1 }).limit(10);
        if (docs.length === 0) {
            docs = await Document.find({}).sort({ createdAt: -1 }).limit(10);
        }
        res.json(docs);
    } catch (error) {
        console.error('Error fetching documents:', error);
        res.status(500).json({ error: 'Failed to fetch documents', details: error.message });
    }
});

router.get('/documents/:id', async (req, res) => {
    try {
        const doc = await Document.findById(req.params.id);
        if (!doc) {
            return res.status(404).json({ error: 'Document not found' });
        }
        res.json(doc);
    } catch (error) {
        console.error('Error fetching document:', error);
        res.status(500).json({ error: 'Failed to fetch document', details: error.message });
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
