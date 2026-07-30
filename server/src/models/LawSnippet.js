const mongoose = require('mongoose');

const lawSnippetSchema = new mongoose.Schema({
    text: {
        type: String,
        required: true,
    },
    source: {
        type: String,
        default: 'General Property Law',
    },
    embedding: {
        type: [Number],
        required: true,
    }
});

module.exports = mongoose.model('LawSnippet', lawSnippetSchema);
