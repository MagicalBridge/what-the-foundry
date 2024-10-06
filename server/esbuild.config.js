const { build } = require('esbuild');
const path  =require("path")
const fs = require("fs")

build({
  entryPoints: ['src/start.js'],
  bundle: true,
  platform: 'node',
  target: 'node18',
  outfile: 'dist/app.js',
  sourcemap: true,
  define: {
    IS_LOCAL: process.env.IS_LOCAL || JSON.stringify("")
  }
}).catch(() => process.exit(1));


const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  failOnErrors: true, // Whether or not to throw when parsing errors. Defaults to false.
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Hello World',
      version: '1.0.0',
    },
  },
  apis: ['./src/routes/*.js'],
};

const openapiSpecification = swaggerJsdoc(options);
fs.writeFileSync("./swagger/swagger.json", JSON.stringify(openapiSpecification))

const distDir = path.join(__dirname, 'dist');
if (!fs.existsSync(distDir)) {
    fs.mkdirSync(distDir, { recursive: true });
}
fs.copyFileSync(path.join(__dirname, ".env"), path.join(__dirname, "dist/.env"))
require("./copy")