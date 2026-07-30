require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const documentRoutes = require('./routes/documentRoutes');
const checklistRoutes = require('./routes/checklistRoutes');
const chatRoutes = require('./routes/chatRoutes');
const authRoutes = require('./routes/authRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use('/api', documentRoutes);
app.use('/api', checklistRoutes);
app.use('/api', chatRoutes);
app.use('/api/auth', authRoutes);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

mongoose.connect(process.env.MONGODB_URI, { family: 4 })
  .then(() => {
    console.log('Connected to MongoDB');
  })
  .catch((err) => {
    console.warn('MongoDB connection failed (running without DB connection):', err.message);
  });

