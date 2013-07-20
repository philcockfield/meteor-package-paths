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
      for path in value
        console.log ' ', path
      console.log ''

    # Finish up.
    paths



# Finish up.
program.parse process.argv
