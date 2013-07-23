# See: https://github.com/visionmedia/commander.js/
require 'colors'
require 'sugar'

fs     = require 'fs'
fsPath = require 'path'
program = require 'commander'

api     = require('./api')
js      = require './javascript'
pkg     = require './package'


###
Pretty prints a set of files.
###
print = (files) ->
  for key, items of files
    if items.length > 0
      console.log " #{ key }:".blue
      for file in items
        console.log '  File'.cyan, file.path
      console.log ''



program
  .command('tree')
  .description('Shows the ordered list of files for the entire hierarchy under the given directory (deep)')
  .action (dir, args) ->
    console.log ''
    console.log 'Tree:'.red, dir.grey
    print(api.tree(dir))

program
  .command('directory')
  .description('Shows the ordered list of files under the given directory (shallow)')
  .action (dir, args) ->
    console.log ''
    console.log 'Directory:'.red, dir.grey
    print(api.directory(dir))


program
  .command('file')
  .description('Shows the file for the given path')
  .action (path, args) ->
    console.log ''
    console.log 'File:'.red, path.grey
    unless file = api.file(path)
      console.log ' Not found.'.red
    else
      console.log ''
      console.log '- directives:'.cyan
      console.log file.directives().map (d) -> d.toString()

      console.log ''
      console.log '- prereqs:'.cyan
      console.log file.prereqs.map (d) -> d.toString()

      console.log ''
      console.log '- [object File]:'.cyan
      console.log file

    console.log ''


program
  .command('js')
  .description('Prints the [add_files] JavaScript to copy into your package.js')
  .action (cmd, args) ->
    dir = fsPath.resolve('.')
    console.log 'package.js'.green, dir.grey
    console.log ''
    console.log "  #{ js.GENERATED_HEADER }".grey
    console.log js.addFiles(dir).red
    console.log ''


program
  .command('create')
  .description('Creates a new package.js file.')
  .option('-f --force', 'Overrite existing files')
  .action (args) ->
    dir = fsPath.resolve('.')
    if pkg.create(dir, args)
      console.log 'Created package.js'.green
    else
      console.log 'Cannot create package.js - file already exists.'.red
    console.log ''


program
  .command('update')
  .description('Updates the [add_new] statements within the package.js file.')
  .action (args) ->
    dir = fsPath.resolve('.')
    if pkg.update(dir)
      console.log 'Updated package.js'.green
    else
      console.log 'No package.js file to update.'.red, 'Use [create] to create a new package.js file.'.grey
    console.log ''



program
  .command('update-all')
  .description('Updates the package.js files within each child folder.')
  .action (args) ->
    dir = fsPath.resolve('.')
    result = pkg.updateAll(dir)

    if result.updated is 0
      console.log 'No package.js files updated.'.red
    else
      console.log "Updated #{ result.updated } package.js files.".green
      for key, item of result.folders
        if item.updated
          console.log " - #{ item.path }".grey
    console.log ''



# Finish up.
program.parse process.argv

