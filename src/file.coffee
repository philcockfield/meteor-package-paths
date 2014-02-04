fs        = require 'fs'
fsPath    = require 'path'
wrench    = require 'wrench'
Directive = require './directive'

CLIENT = 'client'
SERVER = 'server'
SHARED = 'shared'

CODE_EXTENSIONS      = ['.js', '.coffee']
STYLE_EXTENSIONS     = ['.css', '.styl']
HTML_EXTENSIONS      = ['.html', '.htm']
IMAGE_EXTENSIONS     = ['.jpg', '.jpeg', '.png', '.gif', '.svg', '.swf']
SUPPORTED_EXTENSIONS = [].union(CODE_EXTENSIONS, STYLE_EXTENSIONS, HTML_EXTENSIONS, IMAGE_EXTENSIONS)


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
    @prereqs   = []

    # File type flags.
    hasExtension = (extensions) => extensions.any (ext) => ext is @extension
    @isCode  = hasExtension CODE_EXTENSIONS
    @isStyle = hasExtension STYLE_EXTENSIONS
    @isHtml  = hasExtension HTML_EXTENSIONS
    @isImage = hasExtension IMAGE_EXTENSIONS

    # Determine where the file is executed (client/server/shared).
    @domain = executionDomain(@path)

    # Determine if the file type is an server asset.
    if @isFile and @domain is SERVER
      @isAsset = true unless hasExtension(CODE_EXTENSIONS)

    # Process directives.
    @_buildPrereqs() if (options.withPrereqs ? true)
    directives = @directives()
    @isBase    = directives.any (directive) -> directive.type is 'base'
    @isExclude = directives.any (directive) -> directive.type is 'exclude'

    # Finish up.
    @isValid = @exists and @isFile



  ###
  Creates a string representation of the file.
  ###
  toString: -> @path



  ###
  Generates the "api.add_files" line of JS.
  @param packageDir: The directory path to the package.
  @returns string of javascript code.
  ###
  toAddFilesJavascript: (packageDir) ->
    path = @path
    path = path.remove(new RegExp("^#{ packageDir }/"))

    formatWhere = (where) ->
        where = [where] unless Object.isArray(where)
        result = ''
        for item in where
          result += "'#{ item }', "
        result = result.remove(/, $/)
        result = "[#{ result }]" if where.length > 1
        result

    toLine = (where, isAsset) ->
        where = formatWhere(where)
        options = ''
        options = ', { isAsset:true }' if isAsset
        line = "  api.add_files('#{ path }', #{ where }#{ options });\n"



    switch @domain
      when CLIENT then toLine('client', @isAsset)
      when SERVER then toLine('server', @isAsset)
      when SHARED

        if @isStyle
          # Style-sheets that are in 'shared' get two entries, one on the client,
          # and the other on the server as an asset { isAsset:true }.
          result = ''
          result += toLine('client', false)
          result += toLine('server', true)
          result

        else
          toLine(['client', 'server'], @isAsset)





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



# PRIVATE --------------------------------------------------------------------------



fileExists = (file, files) -> files.any (item) -> item.path is file.path



executionDomain = (filePath) ->
  # Find the last reference within the path to an execution domain.
  for part in filePath.split('/').reverse()
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
  paths = paths.filter (path) -> isSupported(path)
  paths


isSupported = (path) ->
  if isServer = executionDomain(path) is SERVER
    # All files are supported on the server.
    # They are set as { isAsset:true } if they are note JS or CSS.
    true
  else
    SUPPORTED_EXTENSIONS.any (ext) -> fsPath.extname(path) is ext



toOrderedFiles = (paths, options = {}) ->
  options.withPrereqs ?= true
  paths = paths.filter (path) -> not fsPath.extname(path).isBlank() # Remove folder-only paths.
  files = paths.map (path) -> new File(path, options)
  files = files.filter (file) -> not file.isExclude and file.isValid

  # Partition paths into their execution domains.
  byDomain = (domain) -> files.filter (file) -> file.domain is domain
  result =
    client: byDomain('client')
    server: byDomain('server')
    shared: byDomain('shared')

  # Put "shared" CSS files as two distinct entries:
  #  - client
  #  - server { isAsset:true }
  # processCssFiles(result)

  # Process paths.
  process = (files) ->
    files = sortDeepest(files)
    files = putBaseFirst(files)
    files = withPrereqs(files) if options.withPrereqs
    files = files.unique (file) -> file.path
    files = putHtmlFirst(files)
    files = putMainLast(files)
    files

  for key, files of result
    result[key] = process(files)

  # Finish up.
  result


# processCssFiles = (byDomain) ->
#   # Put "shared" CSS files as two distinct entries:
#   #  - client
#   #  - server { isAsset:true }

#   for file in byDomain.shared
#     console.log ' > file',  file




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


putBaseFirst = (files) ->
  baseFiles = files.filter (file) -> file.isBase
  baseFiles = baseFiles.reverse() # Shallowest to deepest (files have been pre-ordered).
  files = files.filter (file) -> not file.isBase
  files.add(baseFiles, 0)



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
  mainFiles = files.filter (file) -> file.name is 'main'
  files = files.filter (file) -> file.name isnt 'main'
  files.add(mainFiles)
  files




