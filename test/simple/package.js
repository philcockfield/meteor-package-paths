Package.describe({
  summary: ''
});



Package.on_use(function (api) {
  api.use('coffeescript');
  api.use('sugar');
  api.use('http', ['client', 'server']);
  api.use('templating', 'client');
  api.use('core');



});
