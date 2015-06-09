Package.describe({
  summary: ''
});


/*
The `build` path should not be stripped.

  This allows custom builds to be referenced, and explicitly
  declared within this file without the tool being destructive.

*/


Package.on_use(function (api) {
  api.addFiles('build/bundle.js', 'client');
  api.add_files('build/bundle.js', 'client');

  // Generated with: github.com/philcockfield/meteor-package-paths
  

});
