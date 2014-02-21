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
  api.add_files('private/nested/data.dat', 'server', { isAsset:true });
  api.add_files('private/code.js', 'server', { isAsset:true });
  api.add_files('private/data.txt', 'server', { isAsset:true });

});
