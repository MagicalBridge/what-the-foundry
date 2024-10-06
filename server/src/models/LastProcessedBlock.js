const mongoose = require("mongoose");

const LastProcessedBlockSchema = new mongoose.Schema({
  contractAddress: String,
  blockNumber: Number,
});

module.exports = mongoose.model("LastProcessedBlock", LastProcessedBlockSchema);
