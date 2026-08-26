const Hapi = require('@hapi/hapi');
const routes = require('./routes');

const createServer = (port) => Hapi.server({
  port,
  host: '0.0.0.0',
  routes: {
    cors: {
      origin: ['*'],
    },
  },
});

const init = async () => {
  const servers = [createServer(5000), createServer(80)];

  servers.forEach((server) => server.route(routes));

  await Promise.all(servers.map(async (server) => {
    try {
      await server.start();
      console.log(`Server berjalan pada ${server.info.uri}`);
    } catch (error) {
      if (server.info.port === 80 && error.code === 'EACCES') {
        console.warn('Port 80 membutuhkan hak akses tambahan untuk dijalankan.');
        return;
      }
      throw error;
    }
  }));
};

init();