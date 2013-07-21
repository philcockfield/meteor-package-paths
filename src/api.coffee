require 'colors'
require 'sugar'

fs     = require 'fs'
fsPath = require 'path'
wrench = require 'wrench'
File   = require './file'


module.exports = loader =
  ###
  Generates the ordered list of files for the entire hierarchy under the given directory (deep).
  @param dir: The root directory to retrieve the file listing from.
  ###
  tree: (dir) -> File.tree(dir)

  ###
  Generates the ordered list of files under the given directory (shallow).
  @param dir: The root directory to retrieve the file listing from.
  ###
  directory: (dir) -> File.directory(dir)


  ###
  Gets the [File] object for the given path.
  @param path: The path to the file to load.
  ###
  file: (path) ->
    file = new File(path)
    file if file.isValid()



  printJavaScript: (packageDir) ->
    console.log 'package.js'.green
    console.log ''
    console.log '  // Generated with: github.com/philcockfield/meteor-package-loader'.grey

    printFiles = (files, whereParam) ->
      for file in files

        path = file.path
        path = path.remove(new RegExp("^#{ packageDir }/"))

        where = ''
        for item in whereParam
          where += "'#{ item }', "

        where = where.remove(/, $/)
        where = "[#{ where }]" if whereParam.length > 1

        js = "  api.add_files('#{ path }', #{ where });"
        console.log js.red


    print = (dir) ->
      dir = "#{ packageDir }/#{ dir }"
      if fs.existsSync(dir)
        tree = loader.tree(dir)
        printFiles(tree.shared, ['client', 'server'])
        printFiles(tree.client, ['client'])
        printFiles(tree.server, ['server'])


    print 'shared'
    print 'client'
    print 'server'
    console.log ''



  ###
  Pretty prints a set of files.
  ###
  print: (files) ->
    for key, items of files
      if items.length > 0
        console.log " #{ key }:".blue
        for file in items
          console.log '  File'.cyan, file.path
        console.log ''

