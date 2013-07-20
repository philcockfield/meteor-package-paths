# See: https://github.com/visionmedia/commander.js/
require 'colors'
require 'sugar'

program = require 'commander'
api     = require('./api')


program
  .command('files')
  .description('Shows the packages ordered list of files')
  .action (dir, args) ->
    # Retreive the set of files.
    files = api.files(dir)

    # Print results to the console.
    for key, value of files
      console.log "#{ key }:".blue
      for file in value
        console.log ' File'.cyan, file.path
        # console.log '   - dir:'.cyan, file.dir
      console.log ''

    temp = (file) ->
      console.log '------'.cyan

      console.log 'file'.red, file
      # console.log 'file.prereqs()'.red, file.prereqs()
      console.log 'file.directives()'.red, file.directives()
      console.log ''

    temp files.client[0]




# Finish up.
program.parse process.argv
