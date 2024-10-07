module.exports = async (ctx, next) => {
  try {
    await next();

    // 设置默认状态码为 200
    if (!ctx.status) {
      ctx.status = 200;
    }

    // 如果是成功的响应，并且 body 不是 null 或 undefined
    if (ctx.status < 400 && ctx.body != null) {
      // 将原有的 body 包装在 data 字段中
      ctx.body = {
        code: ctx.status,
        message: "success",
        data: ctx.body,
      };
    }
  } catch (err) {
    ctx.status = err.status || 500;
    ctx.body = {
      code: ctx.status,
      message: err.message,
      data: null,
    };
    ctx.app.emit("error", err, ctx);
  }
};
