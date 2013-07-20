# See: https://github.com/visionmedia/commander.js/
require 'colors'
require 'sugar'

api     = require('./api')
program = require 'commander'


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
    file =
    if file = api.file(path)
      console.log ''
      console.log file
      console.log ''
      console.log '- directives:'.cyan
      console.log file.directives().map (d) -> d.toString()

      console.log ''
      console.log '- prereqs:'.cyan
      console.log file.prereqs().map (d) -> d.toString()
    else
      console.log ' Not found.'.red
    console.log ''



# Finish up.
program.parse process.argv

