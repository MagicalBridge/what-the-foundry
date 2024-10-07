const mongoose = require("mongoose");
const connectDB = require("../config/db");

const tokenSchema = new mongoose.Schema({
  timestamp: { type: Date },
  amount: { type: String },
  transactionHash: { type: String },
});

const Token = mongoose.model("DividendRecords", tokenSchema);
module.exports = Token;
