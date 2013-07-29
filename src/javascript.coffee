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

        path = file.path
        path = path.remove(new RegExp("^#{ packageDir }/"))

        where = ''
        for item in whereParam
          where += "'#{ item }', "

        where = where.remove(/, $/)
        where = "[#{ where }]" if whereParam.length > 1

        line = "  api.add_files('#{ path }', #{ where });\n"
        result += line

    printLine = -> result += '\n'

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

