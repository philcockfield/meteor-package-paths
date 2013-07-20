# See: https://github.com/visionmedia/commander.js/
require 'colors'
require 'sugar'

program = require 'commander'
api     = require('./api')


print = (files) ->
  for key, value of files
    console.log "#{ key }:".blue
    for file in value
      console.log ' File'.cyan, file.path
      # console.log '   - dir:'.cyan, file.dir
    console.log ''



program
  .command('tree')
  .description('Shows the ordered list of files for the entire hierarchy under the given directory')
  .action (dir, args) ->
    # Retreive the set of files.
    files = api.tree(dir)
    print(files)


    # temp = (file) ->
    #   console.log '------'.cyan

    #   console.log 'file'.red, file
    #   # console.log 'file.prereqs()'.red, file.prereqs()
    #   console.log 'file.directives()'.red, file.directives()
    #   console.log ''

    # temp files.client[0]




# Finish up.
program.parse process.argv



# --------------------------------------------------------------------------

