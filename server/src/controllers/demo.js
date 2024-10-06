const { v4: uuidv4 } = require("uuid");
const Token = require("../models/Token");
const path = require("pathe");

const applyToken = async (ctx) => {
  const token = "",
    overridePermission = false;
  ctx.body = { token, overridePermission };
};

module.exports = { applyToken };
