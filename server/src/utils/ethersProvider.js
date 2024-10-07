const { WebSocketProvider } = require("ethers");

let provider;

function getProvider() {
  if (!provider) {
    provider = new WebSocketProvider(process.env.WS_RPC_URL);
    // provider._websocket.on("close", () => {
    //   console.log("WebSocket 连接已关闭，正在重新连接...");
    //   provider = null;
    //   getProvider();
    // });
  }
  return provider;
}

module.exports = { getProvider };
