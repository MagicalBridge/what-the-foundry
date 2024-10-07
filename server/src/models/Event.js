const mongoose = require("mongoose");

const EventSchema = new mongoose.Schema({
  blockNumber: Number,
  transactionHash: String,
  transactionIndex: Number,
  index: Number,
  address: String,
  event: String,
  args: mongoose.Schema.Types.Mixed,
  // 其他您需要的字段
});

EventSchema.index({ transactionHash: 1, index: 1 }, { unique: true });

const Event = mongoose.model("Event", EventSchema);

module.exports = Event;
