Package.describe({
  summary: ''
});



Package.on_use(function (api) {
  api.use('http', ['client', 'server']);
  api.use('templating', 'client');
  api.use('coffeescript');
  api.use('sugar');
  api.use('core');

  // Generated with: github.com/philcockfield/meteor-package-paths
  api.add_files('server/SERVER.md', 'server');
  api.add_files('client/CLIENT.md', 'server');

});
