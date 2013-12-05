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
print = (files, trimStart) ->
  for key, items of files
    if items.length > 0
      console.log " #{ key }:".blue
      for file in items
        path = file.path
        if trimStart
          path = path.remove(new RegExp("^#{ trimStart }"))
        console.log '  File'.cyan, path
      console.log ''



program
  .command('tree')
  .description('Shows the ordered list of files for the entire hierarchy under the given directory (deep)')
  .action (dir, args) ->
    dir = './' unless Object.isString(dir)
    dir = fsPath.resolve(dir)
    console.log ''
    console.log 'Tree:'.red, dir.grey
    print(api.tree(dir), dir)

program
  .command('directory')
  .description('Shows the ordered list of files under the given directory (shallow)')
  .action (dir, args) ->
    dir = fsPath.resolve(dir)
    console.log ''
    console.log 'Directory:'.red, dir.grey
    print(api.directory(dir), dir)


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
  .description('Prints the [add_files] JavaScript to copy into your package.js file')
  .action (args) ->
    dir = fsPath.resolve('.')
    console.log 'package.js'.green, dir.grey
    console.log ''
    console.log "  #{ js.GENERATED_HEADER }".grey
    console.log js.addFiles(dir).red
    console.log ''


program
  .command('create')
  .usage('[options] <package summary>')
  .description('Creates a new package.js file')
  .option('-f --force', 'Overrite existing files')
  .option('-d --dirs', 'Create the [client/server/shared] directories if they do not exist')
  .action (summary, args) ->
    args    = summary unless Object.isString(summary)
    summary = null unless Object.isString(summary)
    dir     = fsPath.resolve('.')
    if pkg.create(dir, summary:summary, force:args.force, withDirs:args.dirs)
      console.log 'Created package.js'.green
    else
      console.log 'Cannot create package.js - file already exists.'.red, 'Use the --force [-f] option to overrite.'.grey
    console.log ''


program
  .command('update')
  .description('Updates the [add_new] statements within the package.js file')
  .action (args) ->
    dir = fsPath.resolve('.')
    unless fs.existsSync(fsPath.join(dir, 'package.js'))
      console.log 'No package.js file to update.'.red, 'Use [create] to create a new package.js file'.grey
    else
      if pkg.update(dir)
        console.log 'Updated package.js'.green
      else
        console.log 'No change.'.green, 'The package file is already up-to-date.'.grey
      console.log ''



program
  .command('update-all')
  .description('Updates the package.js files within each child folder')
  .action (args) ->
    dir = fsPath.resolve('.')
    console.log 'Update Packages'.blue, 'in folder'.grey, dir.cyan
    result = pkg.updateAll(dir)

    if result.total is 0
      console.log 'No package.js files available to update'.grey
    else
      totalFiles = result.updated
      if totalFiles is 0
        console.log "No files changed.".grey
      else
        console.log "Updated #{ totalFiles } files:".green
        for key, item of result.folders
          path = item.path.remove(new RegExp("^#{ dir }"))
          if item.updated
            console.log ' -'.grey, 'Updated'.green, " #{ path }".grey
          # else
          #   console.log ' -'.grey, 'Already up-to-date'.red, " #{ path }".grey
    console.log ''


# Finish up.
program.parse process.argv

