fs   = require 'fs'
File = require './file'



module.exports =
  GENERATED_HEADER: '// Generated with: github.com/philcockfield/meteor-package-paths'

  ###
  Generates the block of 'add_files' JS statements for
  the package.js file.
  @param rootDir:     The directory path to the package.
  @param pathPrefix:  A prefix to prepend the path with.
  @param options:
              - pathPrefix:   A prefix to prepend the path with.
                              Default: none ('').

              - isCamelCase:  Flag indicating if file names are
                              'addFiles' camel-case style (true) or
                              'add_files' underscore style (false).
                              (Default: true)

  @returns string of javascript code.
  ###
  addFiles: (rootDir, options = {}) ->
    result = ''
    prefixPath = options.prefixPath ? ''
    isCamelCase = options.isCamelCase ? true

    printFiles = (files, whereParam) ->
      for file in files
        result += file.toAddFilesJavascript(rootDir, options)

    print = (dir) ->
      dir = "#{ rootDir }/#{ dir }"
      if fs.existsSync(dir)
        tree = File.tree(dir)
        printFiles(tree.shared, ['client', 'server'])
        printFiles(tree.client, ['client'])
        printFiles(tree.server, ['server'])

    print 'shared'
    print 'server'
    print 'client'
    print 'images'
    print 'private'

    # Finish up.
    result

