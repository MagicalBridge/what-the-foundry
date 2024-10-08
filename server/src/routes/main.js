const Router = require("koa-router");
const controller = require("../controllers/main");

const router = new Router();

/**
 * @swagger
 * tags:
 *   name: main
 *   description: Main API endpoints
 */

/**
 * @swagger
 * /main/getWithdrawalRecords:
 *   post:
 *     summary: 查询用户提现记录
 *     tags: [main]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userAddress:
 *                 type: 用户地址
 *     responses:
 *       200:
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: 200
 *                 data:
 *                   type: object
 *                   properties:
 *                     lists:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           args:
 *                             type: object
 *                             properties:
 *                               user:
 *                                 type: 用户地址
 *                               amount:
 *                                 type: htx提现金额
 *                               usdtAmount:
 *                                 type: USDT 提现金额
 *       400:
 *         description: Bad request
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Internal server error
 */
router.post("/getWithdrawalRecords", controller.getWithdrawalRecords);

/**
 * @swagger
 * /main/getInvitationRewards:
 *   post:
 *     summary: 查询邀请奖励列表
 *     tags: [main]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userAddress:
 *                 type: 用户地址
 *     responses:
 *       200:
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: 200
 *                 data:
 *                   type: object
 *                   properties:
 *                     lists:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           args:
 *                             type: object
 *                             properties:
 *                               user:
 *                                 type: 用户地址
 *                               amount:
 *                                 type: 奖励金额
 *       400:
 *         description: Bad request
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Internal server error
 */
router.post("/getInvitationRewards", controller.getInvitationRewards);

/**
 * @swagger
 * /main/getDividendRecords:
 *   post:
 *     summary: 查询分红记录
 *     tags: [main]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userAddress:
 *                 type: 用户地址
 *     responses:
 *       200:
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: 200
 *                 data:
 *                   type: object
 *                   properties:
 *                     lists:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           args:
 *                             type: object
 *                             properties:
 *                               user:
 *                                 type: 用户地址
 *                               amount:
 *                                 type: 奖励金额
 *       400:
 *         description: Bad request
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Internal server error
 */
router.post("/getDividendRecords", controller.getDividendRecords);

/**
 * @swagger
 * /main/getTotalAmount:
 *   post:
 *     summary: 查询总金额
 *     tags: [main]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userAddress:
 *                 type: 用户地址
 *     responses:
 *       200:
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: 200
 *                 data:
 *                   type: object
 *                   properties:
 *                     dividendTotalAmount:
 *                       type: 分红总金额
 *                     invitationTotalAmount:
 *                       type: 邀请总金额
 *       400:
 *         description: Bad request
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Internal server error
 */
router.post("/getTotalAmount", controller.getTotalAmount);

module.exports = router;
