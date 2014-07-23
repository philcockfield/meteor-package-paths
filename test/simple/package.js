Package.describe({
  summary: ''
});



Package.on_use(function (api) {
  api.use('coffeescript');
  api.use('sugar');
  api.use('http', ['client', 'server']);
  api.use('templating', 'client');
  api.use('core');

  // Generated with: github.com/philcockfield/meteor-package-paths
  api.add_files('shared/circle.png', ['client', 'server']);
  api.add_files('shared/file.coffee', ['client', 'server']);
  api.add_files('shared/client/file.coffee', 'client');
  api.add_files('shared/server/file.coffee', 'server');
  api.add_files('server/client/file.coffee', 'client');
  api.add_files('server/child/file.coffee', 'server');
  api.add_files('server/circle.png', 'server', { isAsset:true });
  api.add_files('server/file.coffee', 'server');
  api.add_files('client/child/shared/file.js', ['client', 'server']);
  api.add_files('client/child/grand_child/grand_child.html', 'client');
  api.add_files('client/file4.html', 'client');
  api.add_files('client/child/grand_child/grand_child.coffee', 'client');
  api.add_files('client/child/grand_child/grand_child.js', 'client');
  api.add_files('client/child/child.coffee', 'client');
  api.add_files('client/child/child.js', 'client');
  api.add_files('client/circle.png', 'client');
  api.add_files('client/file1.js', 'client');
  api.add_files('client/file2a.coffee', 'client');
  api.add_files('client/file2b.coffee', 'client');
  api.add_files('client/file3.styl', 'client');
  api.add_files('client/z.coffee', 'client');
  api.add_files('client/child/grand_child/main.coffee', 'client');
  api.add_files('client/main.coffee', 'client');
  api.add_files('client/child/server/file.js', 'server');
  api.add_files('images/child/circle.png', ['client', 'server']);
  api.add_files('images/circle.jpeg', ['client', 'server']);
  api.add_files('images/circle.jpg', ['client', 'server']);
  api.add_files('images/circle.png', ['client', 'server']);
  api.add_files('images/circle.svg', ['client', 'server']);

});
