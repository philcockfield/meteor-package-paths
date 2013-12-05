Package.describe({
  summary: ''
});



Package.on_use(function (api) {
  api.use('http', ['client', 'server']);
  api.use('templating', 'client');
  api.use('coffeescript');
  api.use('sugar');
  api.use('core');

  // Generated with: github.com/philcockfield/meteor-package-loader
  api.add_files('server/circle.png', 'server', { isAsset:true });
  api.add_files('server/sample.coffee', 'server');
  api.add_files('server/sample.jade', 'server', { isAsset:true });

});
