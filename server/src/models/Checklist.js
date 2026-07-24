const mongoose = require('mongoose');

const checklistItemSchema = new mongoose.Schema({
    id: String,
    title: String,
    isCompleted: { type: Boolean, default: false }
});

const checklistSchema = new mongoose.Schema({
    type: { type: String, required: true, unique: true }, // e.g., 'buying-resale'
    title: { type: String, required: true },
    items: [checklistItemSchema]
});

module.exports = mongoose.model('Checklist', checklistSchema);
