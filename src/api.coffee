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


  ###
  Adds the files of the given package to the Meteor [api] object.
  @param toPackage: The folder-name of the package, or a path to the package folder.
  @param api:       The Meteor package API parameter.
  ###
  addFiles: (toPackage, api) ->
    console.log ''
    console.log 'ADD FILES'.green
    console.log 'toPackage'.red, toPackage
    console.log 'api'.red, api
    console.log 'fsPath.resolve(".")'.blue, fsPath.resolve(".")

    # Derive the path to the package directory.
    isPath = toPackage.startsWith('.') or toPackage.startsWith('/')
    if isPath
      packageDir = fsPath.resolve "#{ fsPath.resolve('.') }/#{ toPackage }"
    else
      packageDir = "#{ fsPath.resolve('.') }/packages/#{ toPackage }"


    count = 0
    console.log ''
    console.log 'Adding package files to'.green, packageDir

    where =
      client: 'client'
      server: 'server'
      shared: ['client', 'server']


    addFiles = (files, where) ->
      for file in files
        api.add_files(file.path, where)


    addTree = (dir) ->
      dir = "#{ packageDir }/#{ dir }"

      console.log '--- START'.green, dir.grey


      if fs.existsSync(dir)
        tree = loader.tree(dir)
        loader.print(tree)

        addFiles(tree.shared, ['client', 'server'])
        addFiles(tree.client, 'client')
        addFiles(tree.server, 'server')


      console.log '--- END', dir.grey
      console.log ''


    # Add root folders.
    addTree 'shared'
    addTree 'client'
    addTree 'server'


    console.log ''







  print: (files) ->
    for key, items of files
      if items.length > 0
        console.log " #{ key }:".blue
        for file in items
          console.log '  File'.cyan, file.path
        console.log ''

