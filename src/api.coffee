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

  @param dir: The root directory to retrieve the file listing from.

  ###
  paths: (dir) ->
    # Setup initial conditions.
    dir   = fsPath.resolve(dir)
    paths = wrench.readdirSyncRecursive(dir)
    paths = paths.filter (path) -> not fsPath.extname(path).isBlank() # Filter folder-only paths.
    paths = paths.map (path) -> "#{ dir }/#{ path }"
    files = paths.map (path) -> new File(path)


    # Partition paths into their execution domains.
    byDomain = (domain) -> result = files.filter (file) -> file.domain is domain
    result =
      client: byDomain(CLIENT)
      server: byDomain(SERVER)
      shared: byDomain(SHARED)

    # Process paths.
    process = (domain, files) ->
      files = sortDeepest(files)
      # paths = paths.map (path) -> "#{ dir }/#{ path }"
      # paths = paths.map (path) -> new File(domain, path)
      files

    for key, files of result
      result[key] = process(key, files)


    # Finish up.
    result






# PRIVATE --------------------------------------------------------------------------


class File
  constructor: (@path) ->
    @dir       = fsPath.dirname(@path)
    @extension = fsPath.extname(@path)
    @domain    = executionDomain(@)


  prereqs: ->

  ###
  Retrieves an array of file directives from the initial lines that start
  with the directive comment, eg:
    //= (javascript)
    #=  (coffeescript)
  ###
  directives: ->
    # Setup initial conditions.
    prefix = switch @extension
      when '.js' then '//='
      when '.coffee' then '#='
    return unless prefix

    # Read the directive lines into an array
    reader = new wrench.LineReader(@path)
    readLine = ->
      if reader.hasNextLine()
        line = reader.getNextLine()
        return line if line.startsWith(prefix)

    result = []
    while line = readLine()
      result.push(line)

    # Finish up.
    reader.close()
    result









executionDomain = (file) ->
  # Find the last reference within the path to an execution domain.
  for part in file.path.split('/').reverse()
    return CLIENT if part is CLIENT
    return SERVER if part is SERVER
    return SHARED if part is SHARED

  SHARED # No execution domain found - default to 'shared'.




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


