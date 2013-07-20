require 'colors'
require 'sugar'

fs     = require 'fs'
fsPath = require 'path'
wrench = require 'wrench'
File   = require './file'


module.exports =
  ###
  Generates the ordered list of files for the entire hierarchy under the given directory (deep).
  @param dir: The root directory to retrieve the file listing from.
  ###
  tree: (dir) -> toOrderedFiles(readdir(dir, true))

  ###
  Generates the ordered list of files under the given directory (shallow).
  @param dir: The root directory to retrieve the file listing from.
  ###
  directory: (dir) -> toOrderedFiles(readdir(dir, false))







# PRIVATE --------------------------------------------------------------------------




readdir = (dir, deep) ->
  dir = fsPath.resolve(dir)
  if deep
    paths = wrench.readdirSyncRecursive(dir)
  else
    paths = fs.readdirSync(dir)
  paths = paths.map (path) -> "#{ dir }/#{ path }"
  paths





toOrderedFiles = (paths) ->
  paths = paths.filter (path) -> not fsPath.extname(path).isBlank() # Remove folder-only paths.
  files = paths.map (path) -> new File(path)

  # Partition paths into their execution domains.
  byDomain = (domain) -> files.filter (file) -> file.domain is domain
  result =
    client: byDomain('client')
    server: byDomain('server')
    shared: byDomain('shared')

  # Process paths.
  process = (files) ->
    files = sortDeepest(files)
    files = withPrereqs(files)
    files

  for key, files of result
    result[key] = process(files)


  # Finish up.
  result





sortDeepest = (files) ->
  # Organize files by folder.
  byFolder = {}
  for file in files
    byFolder[file.dir] ?= []
    byFolder[file.dir].push( file )

  # Convert to array.
  folders = []
  for key, value of byFolder
    folders.push({ dir:key, files:value })

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



withPrereqs = (files) -> files






