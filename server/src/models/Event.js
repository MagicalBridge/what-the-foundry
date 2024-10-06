const mongoose = require("mongoose");

const EventSchema = new mongoose.Schema({
  blockNumber: Number,
  transactionHash: String,
  logIndex: Number,
  address: String,
  event: String,
  returnValues: Object,
});

module.exports = mongoose.model("Event", EventSchema);
