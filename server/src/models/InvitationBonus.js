const mongoose = require("mongoose");
const connectDB = require("../config/db");

const tokenSchema = new mongoose.Schema({
  timestamp: { type: Date },
  amount: { type: String },
  parent: { type: String },
  transactionHash: { type: String },
});

const Token = mongoose.model("InvitationBonus", tokenSchema);
module.exports = Token;
