fs     = require 'fs'
fsPath = require 'path'
js     = require './javascript'


module.exports =
  ###
  Creates a new package.js file.
  @param dir: The directory to create the package within.
  @param options:
            - force: Flag indicating if the file should be overwritten.
  @returns true if the package file was created, otherwise false.
  ###
  create: (dir, options = {}) ->
    force = options.force is true
    path  = fsPath.join(dir, 'package.js')
    return false if fs.existsSync(path) and not force


    add_files = js.addFiles(dir).trim()

    tmpl =
      """
      Package.describe({
        summary: ''
      });



      Package.on_use(function (api) {
        api.use('coffeescript');
        api.use('sugar');
        api.use('http', ['client', 'server']);
        api.use('templating', 'client');
        api.use('core');

        #{ js.GENERATED_HEADER }
        #{ add_files }

      });

      """

    # Finish up.
    fs.writeFileSync(path, tmpl)
    true
