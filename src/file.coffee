fs     = require 'fs'
fsPath = require 'path'
wrench = require 'wrench'

CLIENT = 'client'
SERVER = 'server'
SHARED = 'shared'

REQUIRE           = 'require'
REQUIRE_TREE      = 'require_tree'
REQUIRE_DIRECTORY = 'require_directory'

SUPPORTED_EXTENSIONS = ['.js', '.coffee', '.html', '.css', '.styl']


###
Represents a single file.
###
module.exports = class File
  constructor: (@path, options = {}) ->
    # Setup initial conditions.
    @path = fsPath.resolve(@path)
    @exists = fs.existsSync(path)
    if @exists
      @isFile = fs.statSync(path).isFile()

    # Store values.
    @dir       = fsPath.dirname(@path)
    @extension = fsPath.extname(@path)
    @name      = fsPath.basename(@path).remove(new RegExp("#{ @extension }$"))
    @domain    = executionDomain(@)
    @prereqs   = []

    # Build the request list.
    @_buildPrereqs() if (options.withPrereqs ? true)


  isValid: -> @exists and @isFile
  toString: -> @path


  ###
  Retrieves an array of file directives from the initial lines that start
  with the directive comment, eg:
    //= (javascript)
    #=  (coffeescript)

    Directives:
      require
      require_tree
      require_directory

  ###
  directives: ->
    # Setup initial conditions.
    result = []
    commentPrefix = switch @extension
                      when '.js' then '//='
                      when '.coffee' then '#='
    return result unless commentPrefix

    # Read the directive lines into an array.
    reader = new wrench.LineReader(@path)
    readLine = ->
      if reader.hasNextLine()
        line = reader.getNextLine()
        return line if line.startsWith(commentPrefix)

    while line = readLine()
      line = line.remove( new RegExp("^#{ commentPrefix }") )
      line = line.trim()
      unless line.isBlank()
        directive = new Directive(@, line)
        result.push(directive) if directive.isValid

    # Finish up.
    reader.close()
    result



  ###
  Retrieves an ordered array of prerequsite files that need
  to be added before this file.
  ###
  _buildPrereqs: ->
    files = []
    cache = {}

    # Add the files for each directive.
    for directive in @directives()
      for file in directive.toFiles(files, cache)
        files.push(file)

    # Process the results.
    files = files.map (file) -> file.path
    files = files.unique()
    files = files.filter (path) => path isnt @path # Ensure this file is not a pre-req of itself.

    # Finish up.
    @prereqs = files



###
Generates the ordered list of files for the entire hierarchy under the given directory (deep).
@param dir: The root directory to retrieve the file listing from.
@param options:
          - withPrereqs: (default:true) Flag indicating each files pre-requs collection should be built upon construction.
###
File.tree = (dir, options) -> toOrderedFiles(readdir(dir, true), options)


###
Generates the ordered list of files under the given directory (shallow).
@param dir: The root directory to retrieve the file listing from.
@param options:
          - withPrereqs: (default:true) Flag indicating each files pre-requs collection should be built upon construction.
###
File.directory = (dir, options) -> toOrderedFiles(readdir(dir, false), options)





# --------------------------------------------------------------------------



###
Represents a single comment directive within a file.
###
class Directive
  constructor: (@file, @text) ->
    # Setup initial conditions.
    parts = @text.split(' ')
    @type = parts[0]
    @path = parts[1] ? ''
    @files = []

    # Ensure the directive is valid.
    @isValid = [REQUIRE, REQUIRE_TREE, REQUIRE_DIRECTORY].any (item) => item is @type
    @isValid = false if @path.isBlank()

    # Format the path.
    if @isValid and @path.startsWith('.')
      @path = fsPath.resolve("#{ @file.dir }/#{ @path }")


  toString: -> @text


  toFiles: (result = [], _cache = {}) ->
    # Setup initial conditions.
    return result unless @isValid

    # alreadyAdded = (path) -> result.any (item) -> item.path is path
    addFiles = (files) => add(file) for file in files
    add = (file) =>
        # Don't add if the file has already been cached.
        return if _cache[file.path]?
        _cache[file.path] = file

        # Ensure the file can be added.
        throw new Error("The file for the directive [#{ @text }] does not exist [Path: #{ file.path }].") unless file.exists
        throw new Error("The file for the directive [#{ @text }] is not valid.") unless file.isValid()
        if file.domain isnt @file.domain
          throw new Error("The file for the directive [#{ @text }] is in the exeuction domain '#{ file.domain }' and cannot be added to the execution domain '#{ @file.domain }' of the file [#{ @file.path }]")

        # Add any pre-requisites first.
        for directive in file.directives()
          unless _cache[directive.path]
            files = directive.toFiles(result, _cache)
            addFiles(files)

        # Add the given file.
        result.push(file)


    switch @type
      when REQUIRE            then add(new File(@path, withPrereqs:false))
      when REQUIRE_DIRECTORY  then addFiles File.directory(@path, withPrereqs:false)[@file.domain]
      when REQUIRE_TREE       then addFiles File.tree(@path, withPrereqs:false)[@file.domain]


    # Finish up.
    result




# PRIVATE --------------------------------------------------------------------------



fileExists = (file, files) -> files.any (item) -> item.path is file.path



executionDomain = (file) ->
  # Find the last reference within the path to an execution domain.
  for part in file.path.split('/').reverse()
    return CLIENT if part is CLIENT
    return SERVER if part is SERVER
    return SHARED if part is SHARED

  SHARED # No execution domain found - default to 'shared'.



readdir = (dir, deep) ->
  dir = fsPath.resolve(dir)
  unless fs.existsSync(dir) and fs.statSync(dir).isDirectory()
    throw new Error("Not a directory: [#{ dir }]")
  if deep
    paths = wrench.readdirSyncRecursive(dir)
  else
    paths = fs.readdirSync(dir)
  paths = paths.map (path) -> "#{ dir }/#{ path }"
  paths = paths.filter (path) -> SUPPORTED_EXTENSIONS.any (ext) -> fsPath.extname(path) is ext
  paths



toOrderedFiles = (paths, options = {}) ->
  options.withPrereqs ?= true
  paths = paths.filter (path) -> not fsPath.extname(path).isBlank() # Remove folder-only paths.
  files = paths.map (path) -> new File(path, options)

  # Partition paths into their execution domains.
  byDomain = (domain) -> files.filter (file) -> file.domain is domain
  result =
    client: byDomain('client')
    server: byDomain('server')
    shared: byDomain('shared')

  # Process paths.
  process = (files) ->
    files = sortDeepest(files)
    files = withPrereqs(files) if options.withPrereqs
    files = files.unique (file) -> file.path
    files = putHtmlFirst(files)
    files = putMainLast(files)
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



withPrereqs = (files) ->
  result = []
  for file in files
    result.add(new File(path)) for path in file.prereqs
    result.add(file)
  result



putHtmlFirst = (files) ->
  notHtml = files.filter (file) -> fsPath.extname(file.path) isnt '.html'
  result  = files.filter (file) -> fsPath.extname(file.path) is '.html'
  result.add(notHtml)
  result


putMainLast = (files) ->
  mainFiles  = files.filter (file) -> file.name is 'main'
  files = files.filter (file) -> file.name isnt 'main'
  files.add(mainFiles)
  files




