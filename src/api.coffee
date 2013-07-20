require 'colors'
require 'sugar'
fs     = require 'fs'
fsPath = require 'path'
wrench = require 'wrench'

CLIENT = 'client'
SERVER = 'server'
SHARED = 'shared'



module.exports =
  ###
  Generates an object with ordered list of files to add
  partitioned into execution domains (client / server / shared).
  @param dir
  ###
  paths: (dir) ->
    # Setup initial conditions.
    dir   = fsPath.resolve(dir)
    paths = wrench.readdirSyncRecursive(dir)
    paths = paths.filter (path) -> not fsPath.extname(path).isBlank() # Filter folder-only paths.

    # Partition paths into their execution domains.
    filter = (domain) -> result = paths.filter (path) -> executionDomain(path) is domain
    result =
      client: filter(CLIENT)
      server: filter(SERVER)
      shared: filter(SHARED)

    # Process paths.
    process = (paths) ->
      paths = sortDeepest(paths)
      paths = paths.map (path) -> "#{ dir }/#{ path }"
      paths

    for key, paths of result
      result[key] = process(paths)

    # Finish up.
    result






# PRIVATE --------------------------------------------------------------------------



executionDomain = (path) ->
  # Find the last reference within the path to an execution domain.
  for part in path.split('/').reverse()
    return CLIENT if part is CLIENT
    return SERVER if part is SERVER
    return SHARED if part is SHARED

  SHARED # No execution domain found - default to 'shared'.


toParts = (path) ->
  dir = fsPath.dirname(path)
  dir = '' if dir is '.'
  result =
    path:   path
    dir:    dir
    file:   fsPath.basename(path)
    ext:    fsPath.extname(path)


sortDeepest = (paths) ->
  # Organize files by folder.
  byFolder = {}
  for path in paths
    path = toParts(path)
    byFolder[path.dir] ?= []
    byFolder[path.dir].push( path.file )

  # Convert to array.
  folders = []
  for key, value of byFolder
    item = { dir:key, files:value }
    folders.push(item)

  # Sort by depth.
  fnSort = (item) -> item.dir.split('/').length
  folders = folders.sortBy(fnSort, desc:true)

  # Convert to full paths.
  result = []
  for item in folders
    for file in item.files
      result.push "#{ item.dir }/#{ file }".remove(/^\//)

  # Finish up.
  result



