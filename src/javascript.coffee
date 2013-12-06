fs     = require 'fs'
File   = require './file'



module.exports =
  GENERATED_HEADER: '// Generated with: github.com/philcockfield/meteor-package-loader'

  ###
  Generates the block of 'add_files' JS statements for
  the package.js file.
  @param packageDir: The directory path to the package.
  @returns string of javascript code.
  ###
  addFiles: (packageDir) ->
    result = ''

    printFiles = (files, whereParam) ->
      for file in files
        result += file.toAddFilesJavascript(packageDir)


    print = (dir) ->
      dir = "#{ packageDir }/#{ dir }"
      if fs.existsSync(dir)
        tree = File.tree(dir)
        printFiles(tree.shared, ['client', 'server'])
        printFiles(tree.client, ['client'])
        printFiles(tree.server, ['server'])

    print 'shared'
    print 'server'
    print 'client'
    print 'images'

    # Finish up.
    result

