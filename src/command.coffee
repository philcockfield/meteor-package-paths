# See: https://github.com/visionmedia/commander.js/
require 'colors'
require 'sugar'

program = require 'commander'
api     = require('./api')


program
  .command('paths')
  .description('Shows the packages paths to add for the given folder')
  .action (dir, args) ->
    # Retreive the paths.
    paths = api.paths(dir)

    # Print results to the console.
    for key, value of paths
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

    temp paths.client[0]
    # temp paths.client[1]

    # Finish up.
    paths



# Finish up.
program.parse process.argv
