const mongoose = require("mongoose");
const connectDB = require("../config/db");

const tokenSchema = new mongoose.Schema({
  directory: { type: String, required: true },
  applicant: { type: String, required: true },
  desc: { type: String, required: false },
  token: { type: String, required: true },
  overridePermission: { type: Boolean, default: false },
  isProduction: { type: Boolean, default: false }, // 新增字段
  createdAt: { type: Date, default: Date.now },
});

const Token = mongoose.model("test1", tokenSchema);
module.exports = Token;
