const mongoose = require("mongoose");
const connectDB = require("../config/db");

const tokenSchema = new mongoose.Schema({
  timestamp: { type: Date },
  referrer: { type: String },
  transactionHash: { type: String },
});

const Token = mongoose.model("Users", tokenSchema);
module.exports = Token;
