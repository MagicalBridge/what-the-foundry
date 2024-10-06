const Router = require("koa-router");
const controller = require("../controllers/main");

const router = new Router();

/**
 * @swagger
 * tags:
 *   name: demo
 *   description: Token management
 */

/**
 * @swagger
 * /demo/apply-token:
 *   post:
 *     summary: 申请存储空间, 需要管理员权限
 *     tags: [Token]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               directory:
 *                 type: string
 *                 description: 申请的存储目录
 *               applicant:
 *                 type: string
 *                 description: 申请人
 *               overridePermission:
 *                 type: boolean
 *                 description: 是否覆盖已有权限
 *               admin:
 *                 type: string
 *                 description: 管理员权限验证字符串
 *     responses:
 *       200:
 *         description: Token applied successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *                   description: 申请成功的 token
 *                 overridePermission:
 *                   type: boolean
 *                   description: 是否有覆盖权限
 *       400:
 *         description: Bad request
 *       403:
 *         description: Forbidden
 */
// router.post("/apply", tokenController.applyToken);

module.exports = router;
