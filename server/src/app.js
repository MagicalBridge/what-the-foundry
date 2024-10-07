const Koa = require("koa");
const bodyParser = require("koa-bodyparser");
const logger = require("koa-logger");
const errorHandler = require("./middlewares/errorHandler");
const cors = require("koa2-cors");
require("dotenv").config();
const connectDB = require("./config/db");
const router = require("./routes");
const serve = require("koa-static");
const staticDirPath = require("path").join(__dirname, "web");
require("./eventIndexer");

connectDB();

const app = new Koa();
app.use(serve(staticDirPath));

// Middlewares
app.use(cors());
app.use(logger());
app.use(bodyParser());
app.use(errorHandler);

// Routes
app.use(router.routes()).use(router.allowedMethods());

module.exports = app;
