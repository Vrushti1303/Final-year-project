const mongoose = require('mongoose');

const StampDutySchema = new mongoose.Schema({
  userId: { type: String, required: true },
  propertyType: { type: String, required: true },
  state: { type: String, required: true },
  agreementValue: { type: Number, required: true },
  circleRate: { type: Number, default: 0 },
  applicableMarketValue: { type: Number, required: true },
  gender: { type: String, required: true },
  firstTimeBuyer: { type: String, required: true },
  stampDutyRate: { type: Number, required: true },
  stampDutyAmount: { type: Number, required: true },
  registrationRate: { type: Number, required: true },
  registrationAmount: { type: Number, required: true },
  totalPayable: { type: Number, required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('StampDuty', StampDutySchema);
