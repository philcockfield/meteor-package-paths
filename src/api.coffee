require 'colors'
require 'sugar'

fs     = require 'fs'
fsPath = require 'path'
wrench = require 'wrench'
File   = require './file'


module.exports = api =

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



  addFiles: (packageDirName, api) ->
    console.log ''
    console.log 'ADD FILES'.green
    console.log 'packageDirName'.red, packageDirName
    console.log 'api'.red, api
    console.log 'fsPath.resolve(".")'.blue, fsPath.resolve(".")

    # Derive the path to the package directory.
    packageDir = "#{ fsPath.resolve('.') }/packages/#{ packageDirName }"
    console.log ''
    console.log 'Adding files to'.green, packageDir


    addTree = (executionDomain, where) ->

      console.log ' ',  executionDomain.blue
      dir = "#{ packageDir }/#{ executionDomain }"

      console.log 'dir'.red, dir

      console.log ''

      files = api.tree(dir)

      api.print(files)







    addTree 'server', 'server'





    console.log ''







  print: (files) ->
    for key, items of files
      if items.length > 0
        console.log " #{ key }:".blue
        for file in items
          console.log '  File'.cyan, file.path
        console.log ''

