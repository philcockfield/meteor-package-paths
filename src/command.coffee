# See: https://github.com/visionmedia/commander.js/
require 'colors'
require 'sugar'

api     = require('./api')
program = require 'commander'




program
  .command('tree')
  .description('Shows the ordered list of files for the entire hierarchy under the given directory (deep)')
  .action (dir, args) ->
    console.log ''
    console.log 'Tree:'.red, dir.grey
    api.print(api.tree(dir))

program
  .command('directory')
  .description('Shows the ordered list of files under the given directory (shallow)')
  .action (dir, args) ->
    console.log ''
    console.log 'Directory:'.red, dir.grey
    api.print(api.directory(dir))


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



# Finish up.
program.parse process.argv

