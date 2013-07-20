require 'colors'
require 'sugar'

fs     = require 'fs'
fsPath = require 'path'
wrench = require 'wrench'
File   = require './file'


module.exports =
  ###
  Generates an object with ordered list of files to add
  partitioned into execution domains (client / server / shared).

  @param dir: The root directory to retrieve the file listing from.

  ###
  paths: (dir) ->
    # Setup initial conditions.
    dir   = fsPath.resolve(dir)
    paths = wrench.readdirSyncRecursive(dir)
    paths = paths.filter (path) -> not fsPath.extname(path).isBlank() # Remove folder-only paths.
    paths = paths.map (path) -> "#{ dir }/#{ path }"
    files = paths.map (path) -> new File(path)

    # Partition paths into their execution domains.
    byDomain = (domain) -> result = files.filter (file) -> file.domain is domain
    result =
      client: byDomain('client')
      server: byDomain('server')
      shared: byDomain('shared')

    # Process paths.
    process = (domain, files) ->
      files = sortDeepest(files)
      files

    for key, files of result
      result[key] = process(key, files)


    # Finish up.
    result



# PRIVATE --------------------------------------------------------------------------



sortDeepest = (files) ->
  # Organize files by folder.
  byFolder = {}
  for file in files
    byFolder[file.dir] ?= []
    byFolder[file.dir].push( file )

  # Convert to array.
  folders = []
  for key, value of byFolder
    item = { dir:key, files:value }
    folders.push(item)

  # Sort by depth.
  fnSort = (item) -> item.dir.split('/').length
  folders = folders.sortBy(fnSort, desc:true)
  folders = folders.sortBy(fnSort, desc:true)

  # Flatten to array.
  result = []
  for item in folders
    for file in item.files
      result.push file

  # Finish up.
  result


