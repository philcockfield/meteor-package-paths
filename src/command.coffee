# See: https://github.com/visionmedia/commander.js/
require 'colors'
require 'sugar'

program = require 'commander'
api     = require('./api')


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
    console.log 'Tree:'.red, dir
    print(api.tree(dir))

program
  .command('directory')
  .description('Shows the ordered list of files under the given directory (shallow)')
  .action (dir, args) ->
    console.log ''
    console.log 'Directory:'.red, dir
    print(api.directory(dir))




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


