const Router = require("koa-router");
const mainRouter = require("./main");

const router = new Router();

router.use("/main", mainRouter.routes());

// 健康检查路由
router.get("/health", async (ctx) => {
  ctx.status = 200;
  ctx.body = {
    status: "UP",
    timestamp: new Date().toISOString(),
  };
});

module.exports = router;
