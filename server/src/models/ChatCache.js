const mongoose = require('mongoose');

const chatCacheSchema = new mongoose.Schema({
    query: {
        type: String,
        required: true,
        unique: true
    },
    reply: {
        type: String,
        required: true
    },
    suggestions: {
        type: [String],
        default: []
    },
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 604800 // 7 days in seconds
    }
});

module.exports = mongoose.model('ChatCache', chatCacheSchema);
