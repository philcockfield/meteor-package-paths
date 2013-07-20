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
    file = api.file(path)
    console.log ''
    console.log file
    console.log ''
    console.log '  - directives'.cyan,  file.directives()
    console.log '  - prereqs'.cyan,  file.prereqs()
    console.log ''




# Finish up.
program.parse process.argv



# --------------------------------------------------------------------------



# temp = (file) ->
#   console.log '------'.cyan

#   console.log 'file'.red, file
#   # console.log 'file.prereqs()'.red, file.prereqs()
#   console.log 'file.directives()'.red, file.directives()
#   console.log ''

# temp files.client[0]


