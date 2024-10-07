const request = require('supertest');
// const mongoose = require('mongoose');
const Token = require('../src/models/Token'); // 你的Token模型路径
const app = require("../src/app")


// beforeAll(async () => {
//   // 连接到测试数据库
//   await mongoose.connect('mongodb://localhost:27017/test', {
//     useNewUrlParser: true,
//     useUnifiedTopology: true,
//   });
// });

// afterAll(async () => {
//   // 清理并断开连接
//   await mongoose.connection.db.dropDatabase();
//   await mongoose.connection.close();
// });

// beforeEach(async () => {
//   // 清理Token集合
//   await Token.deleteMany({});
// });

describe('Token API', () => {
  describe('POST /apply-token', () => {
    it('should apply for a new token', async () => {
      const response = await request(app.callback())
        .post('/token/apply-token')
        .send({ directory: 'dir1', applicant: 'user1', overridePermission: true })
        .expect(200);

      expect(response.body).toHaveProperty('token');
      expect(response.body.overridePermission).toBe(true);
    });

    it('should not allow applying for a subdirectory of an existing directory', async () => {
      await request(app.callback())
        .post('/token/apply-token')
        .send({ directory: 'dir1', applicant: 'user1', overridePermission: true })
        .expect(200);

      const response = await request(app.callback())
        .post('/token/apply-token')
        .send({ directory: 'dir1/innerdir', applicant: 'user1', overridePermission: true })
        .expect(400);

      expect(response.body.message).toBe('Directory or its subdirectory/parent directory has already been applied');
    });

    it('should not allow applying for a parent directory of an existing subdirectory', async () => {
      await request(app.callback())
        .post('/token/apply-token')
        .send({ directory: 'dir2/innerdir', applicant: 'user2', overridePermission: true })
        .expect(200);

      const response = await request(app.callback())
        .post('/token/apply-token')
        .send({ directory: 'dir2', applicant: 'user2', overridePermission: true })
        .expect(400);

      expect(response.body.message).toBe('Directory or its subdirectory/parent directory has already been applied');
    });

    it('should allow applying for unrelated directories', async () => {
      await request(app.callback())
        .post('/token/apply-token')
        .send({ directory: 'dir3', applicant: 'user3', overridePermission: true })
        .expect(200);

      await request(app.callback())
        .post('/token/apply-token')
        .send({ directory: 'dir4', applicant: 'user4', overridePermission: true })
        .expect(200);
    });
  });

  describe('POST /apply-temp-access', () => {
    it('should apply for temporary access credentials', async () => {
      const tokenResponse = await request(app.callback())
        .post('/token/apply-token')
        .send({ directory: 'dir1', applicant: 'user1', overridePermission: true })
        .expect(200);

      const token = tokenResponse.body.token;

      const response = await request(app.callback())
        .post('/token/apply-temp-access')
        .send({ token, dir: '/innerdir' })
        .expect(200);

      expect(response.body).toHaveProperty('directory', 'dir1');
      expect(response.body).toHaveProperty('stsToken');
      expect(response.body).toHaveProperty('accessKeyId');
      expect(response.body).toHaveProperty('accessKeySecret');
    });

    it('should not provide access with an invalid token', async () => {
      const response = await request(app.callback())
        .post('/token/apply-temp-access')
        .send({ token: 'invalid-token', dir: '/innerdir' })
        .expect(400);

      expect(response.body.message).toBe('Invalid token');
    });
  });
});
