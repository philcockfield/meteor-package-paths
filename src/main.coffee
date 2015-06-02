# See: https://github.com/visionmedia/commander.js/
require 'colors'
require 'sugar'

fs      = require 'fs'
fsPath  = require 'path'
program = require 'commander'

# api     = require './api'
js      = require './js'
pkg     = require './pkg'


###
Initialize the command-line program.
###
packageJson = JSON.parse(fs.readFileSync(fsPath.resolve(__dirname, '../package.json')))
version = packageJson.version
program
  .version(version)



###
Pretty prints a set of files.
###
print = (files, trimStart) ->
  trimStart = fsPath.resolve(trimStart)
  for key, items of files
    if items.length > 0
      console.log " #{ key }:".blue
      for file in items
        path = file.path
        if trimStart
          path = path.remove(new RegExp("^#{ trimStart }"))

        suffix = ''
        if file.isAsset
          suffix = '(asset)'.grey

        console.log '  File'.cyan, path, suffix
      console.log ''


# ----------------------------------------------------------------------


module.exports = api =
  version: version

  ###
  Updates the package.js in the given directory.
  @param dir: Optional.  The directly to update.
                         If not specified the current execution directly is used.
  ###
  update: (dir) ->
    dir ?= '.'
    dir = fsPath.resolve(dir)
    unless fs.existsSync(fsPath.join(dir, 'package.js'))
      console.log 'No package.js file to update.'.red
    else
      if pkg.update(dir)
        console.log 'Updated package.js'.green
      else
        console.log 'No change.'.green, 'The package file is already up-to-date.'.grey
      console.log ''




  ###
  Updates all packages in the given directly.
  @param dir: Optional.  The directly to update.
                         If not specified the current execution directly is used.
  ###
  updateAll: (dir) ->
    dir ?= '.'
    dir = fsPath.resolve(dir)

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
    console.log ''




# CLI Commands ----------------------------------------------------------------------


program
  .command('update')
  .description('Updates the [add_new] statements within the package.js file')
  .action (args) -> api.update()


program
  .command('update-all')
  .description('Updates the package.js files within each child folder')
  .action (args) -> api.updateAll()


# Finish up.
program.parse process.argv
