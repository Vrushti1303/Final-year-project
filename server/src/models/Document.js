const mongoose = require('mongoose');

const documentSchema = new mongoose.Schema({
    userId: { type: String, required: true, index: true },
    title: { type: String, required: true },
    originalText: { type: String, required: true },
    sourceType: { type: String, default: 'PDF Document' }, // 'PDF Document', 'Photo Scan', 'Text Description'
    mimeType: { type: String, default: 'text/plain' },
    fileData: { type: String, default: null }, // Base64 string of original uploaded file/photo
    fileName: { type: String, default: '' },
    riskLevel: { 
        type: String, 
        enum: ['Low Risk', 'Medium Risk', 'High Risk'], 
        default: 'Low Risk' 
    },
    docSize: { type: String, default: '1.2 MB' },
    analysis: [{
        text: String,
        category: String, // 'Green', 'Yellow', 'Red'
        reason: String
    }],
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Document', documentSchema);
