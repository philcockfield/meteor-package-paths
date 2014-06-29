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
  api.add_files('client/foo.coffee', 'client');

});



Package.on_test(function (api) {
  api.use('tinytest');
  // api.use(''); // Package name from [smart.json]



});
