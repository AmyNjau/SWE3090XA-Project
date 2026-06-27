'use strict';

const { createApp } = require('./app');
const config = require('./config');

const app = createApp();

app.listen(config.port, () => {
  console.log(
    `Smart Health backend listening on http://localhost:${config.port}` +
      ` (dataStore=${config.dataStore}, providerSource=${config.providerSource})`
  );
});
