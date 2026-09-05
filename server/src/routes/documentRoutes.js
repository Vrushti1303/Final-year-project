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
        const { text, title: customTitle, sourceType = 'Text Description', base64Data = null, mimeType = 'text/plain' } = req.body;
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

        // Safe DB fileData string (MongoDB 16MB BSON doc cap)
        let dbFileData = base64Data;
        if (dbFileData && dbFileData.length > 3 * 1024 * 1024) {
            dbFileData = dbFileData.substring(0, 3 * 1024 * 1024);
            const remainder = dbFileData.length % 4;
            if (remainder > 0) {
                dbFileData = dbFileData.substring(0, dbFileData.length - remainder);
            }
        }

        // Save to MongoDB with fallback safeguard
        let savedDoc = null;
        try {
            const newDoc = new Document({
                userId,
                title,
                originalText: text,
                sourceType,
                mimeType,
                fileData: dbFileData,
                fileName: title,
                riskLevel,
                docSize,
                analysis: items,
                createdAt: new Date()
            });
            savedDoc = await newDoc.save();
            console.log(`[DB SUCCESS] Saved document "${title}" (ID: ${savedDoc._id}) to Recent Documents.`);
        } catch (dbErr) {
            console.warn('Failed to save document to DB with fileData, retrying without fileData:', dbErr.message);
            try {
                const fallbackDoc = new Document({
                    userId,
                    title,
                    originalText: text.length > 50000 ? text.substring(0, 50000) : text,
                    sourceType,
                    mimeType,
                    fileData: null,
                    fileName: title,
                    riskLevel,
                    docSize,
                    analysis: items,
                    createdAt: new Date()
                });
                savedDoc = await fallbackDoc.save();
                console.log(`[DB FALLBACK SUCCESS] Saved document "${title}" (ID: ${savedDoc._id}) to Recent Documents.`);
            } catch (fallbackErr) {
                console.error('Critical DB save error:', fallbackErr.message);
            }
        }

        res.json({
            analysis: items,
            sourceType,
            fileData: base64Data,
            mimeType,
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

router.post('/scan-file', async (req, res) => {
    try {
        const { base64Data, mimeType, title: customTitle, sourceType: reqSourceType } = req.body;
        if (!base64Data) {
            return res.status(400).json({ error: 'base64Data is required' });
        }

        let computedSourceType = reqSourceType;
        if (!computedSourceType) {
            if ((mimeType || '').toLowerCase().includes('pdf')) {
                computedSourceType = 'PDF Document';
            } else {
                computedSourceType = 'Photo Scan';
            }
        }

        const result = await llmService.analyzeContractFile(base64Data, mimeType || 'image/jpeg');
        const extractedText = result.extractedText || 'Scanned Property Document';
        const items = result.analysis || [];
        const userId = getUserIdFromReq(req);

        // Derive overall risk level
        let riskLevel = 'Low Risk';
        if (items.some(i => (i.category || '').toLowerCase() === 'red')) {
            riskLevel = 'High Risk';
        } else if (items.some(i => (i.category || '').toLowerCase() === 'yellow')) {
            riskLevel = 'Medium Risk';
        }

        // Derive document title
        let title = customTitle;
        if (!title || !title.trim()) {
            const firstLine = extractedText.trim().split('\n')[0].replace(/[#*_-]/g, '').trim();
            title = firstLine.length > 50 ? firstLine.substring(0, 47) + '...' : (firstLine || 'Scanned Property Agreement');
        }

        // Calculate doc size
        const rawBytes = Math.round((base64Data.length * 3) / 4);
        const docSize = rawBytes >= 1048576 
            ? `${(rawBytes / 1048576).toFixed(1)} MB` 
            : `${Math.max(1, Math.round(rawBytes / 1024))} KB`;

        // Safe DB fileData string (MongoDB 16MB BSON doc cap)
        let dbFileData = base64Data;
        if (dbFileData && dbFileData.length > 3 * 1024 * 1024) {
            dbFileData = dbFileData.substring(0, 3 * 1024 * 1024);
            const remainder = dbFileData.length % 4;
            if (remainder > 0) {
                dbFileData = dbFileData.substring(0, dbFileData.length - remainder);
            }
        }

        // Save to MongoDB with fallback safeguard
        let savedDoc = null;
        try {
            const newDoc = new Document({
                userId,
                title,
                originalText: extractedText,
                sourceType: computedSourceType,
                mimeType: mimeType || (computedSourceType === 'PDF Document' ? 'application/pdf' : 'image/jpeg'),
                fileData: dbFileData,
                fileName: title,
                riskLevel,
                docSize,
                analysis: items,
                createdAt: new Date()
            });
            savedDoc = await newDoc.save();
            console.log(`[DB SUCCESS] Saved document file "${title}" (ID: ${savedDoc._id}) to Recent Documents.`);
        } catch (dbErr) {
            console.warn('Failed to save document file to DB with fileData, retrying without fileData:', dbErr.message);
            try {
                const fallbackDoc = new Document({
                    userId,
                    title,
                    originalText: extractedText.length > 50000 ? extractedText.substring(0, 50000) : extractedText,
                    sourceType: computedSourceType,
                    mimeType: mimeType || (computedSourceType === 'PDF Document' ? 'application/pdf' : 'image/jpeg'),
                    fileData: null,
                    fileName: title,
                    riskLevel,
                    docSize,
                    analysis: items,
                    createdAt: new Date()
                });
                savedDoc = await fallbackDoc.save();
                console.log(`[DB FALLBACK SUCCESS] Saved document file "${title}" (ID: ${savedDoc._id}) to Recent Documents.`);
            } catch (fallbackErr) {
                console.error('Critical DB file save error:', fallbackErr.message);
            }
        }

        res.json({
            extractedText,
            analysis: items,
            sourceType: computedSourceType,
            fileData: base64Data,
            mimeType: mimeType || (computedSourceType === 'PDF Document' ? 'application/pdf' : 'image/jpeg'),
            document: savedDoc,
            documentId: savedDoc ? savedDoc._id : null
        });
    } catch (error) {
        console.error('Error analyzing file:', error);
        if (error.status === 429) {
            return res.status(429).json({ error: 'Rate limit reached. Please wait a moment before trying again.' });
        }
        res.status(500).json({ error: 'Failed to analyze file', details: error.message });
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
