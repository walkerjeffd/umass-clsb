/* eslint no-console: "off" */

// const fs = require('fs');
const express = require('express');
const compression = require('compression');
// const morgan = require('morgan');
const bodyParser = require('body-parser');

// const config = require('../config');
const db = require('./db');

const config = {
  api: {
    port: 8090
  }
};

const app = express();

// access logging
// morgan.token('real-ip', req => req.headers['x-real-ip'] || req.connection.remoteAddress);
// const logFormat = ':date[iso] :real-ip :remote-user :method :url HTTP/:http-version :status :res[content-length] - :response-time ms';
// const accessLogStream = fs.createWriteStream(config.api.logFile, { flags: 'a' });
// app.use(morgan(logFormat, { stream: accessLogStream }));
// app.use(morgan());

// body parser
app.use(bodyParser.json());

// compression
app.use(compression());

// cors
const allowCrossDomain = (req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
};
app.use(allowCrossDomain);

// static
app.use('/static', express.static('static'));

// routes
app.get('/test', (req, res, next) => {
  db.getTest()
    .then(result => res.status(200).json({ status: 'ok', data: result }))
    .catch(next);
});

app.get('/nodes', (req, res, next) => {
  db.getNetwork(['c-244844', 'c-244895', 'c-282781', 'c-361794'])
    .then(result => res.status(200).json({ status: 'ok', data: result }))
    .catch(next);
});

app.post('/barriers/geojson', (req, res, next) => {
  db.getBarriersInGeoJSON(req.body.feature)
    .then(result => res.status(200).json({ status: 'ok', data: result }))
    .catch(next);
});

// error handler
function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  console.error(err.toString());
  return res.status(500).json({
    status: 'error',
    error: {
      data: err,
      message: err.toString(),
    },
  });
}
app.use(errorHandler);

// start server
app.listen(config.api.port, () => {
  console.log('listening port=%d', config.api.port);
});
