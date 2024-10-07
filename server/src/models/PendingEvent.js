const mongoose = require("mongoose");

const PendingEventSchema = new mongoose.Schema({
  blockNumber: Number,
  transactionHash: String,
  transactionIndex: Number,
  index: Number, // 添加这个字段
  address: String,
  event: String,
  args: mongoose.Schema.Types.Mixed,
  // 其他您可能需要的字段
});

PendingEventSchema.index({ transactionHash: 1, index: 1 }, { unique: true });

const PendingEvent = mongoose.model("PendingEvent", PendingEventSchema);

module.exports = PendingEvent;
