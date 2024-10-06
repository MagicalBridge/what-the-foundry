const ethers = require("ethers");

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);

module.exports = { provider };
