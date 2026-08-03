const mongoose = require('mongoose');

const checklistItemSchema = new mongoose.Schema({
    id: String,
    title: String,
    isCompleted: { type: Boolean, default: false }
});

const checklistSchema = new mongoose.Schema({
    userId: { type: String, required: true },
    type: { type: String, required: true }, // e.g., 'buying-resale'
    title: { type: String, required: true },
    items: [checklistItemSchema]
});

// Ensure a user can only have one checklist of each type
checklistSchema.index({ userId: 1, type: 1 }, { unique: true });

module.exports = mongoose.model('Checklist', checklistSchema);
