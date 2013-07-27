fsPath = require 'path'

REQUIRE               = 'require'
REQUIRE_TREE          = 'require_tree'
REQUIRE_DIRECTORY     = 'require_directory'
BASE                  = 'base'
SUPPORTED_DIRECTIVES  = [REQUIRE, REQUIRE_TREE, REQUIRE_DIRECTORY, BASE]
PATH_DIRECTIVES       = [REQUIRE, REQUIRE_TREE, REQUIRE_DIRECTORY]


createFile = (path, options) ->
    # NB: Require statement here because [File] has a reference
    #     to [Directive], so cannot be loaded at the time the file is parsed
    File = require('./file')
    return new File(path, options)



###
Represents a single comment directive within a file.
###
module.exports = class Directive
  constructor: (@file, @text) ->
    # Setup initial conditions.
    parts = @text.split(' ')
    @type = parts[0]
    @path = parts[1] ? ''
    @files = []

    # Ensure the directive is valid.
    @isPath  = PATH_DIRECTIVES.any (item) => item is @type
    @isValid = SUPPORTED_DIRECTIVES.any (item) => item is @type
    @isValid = false if @isPath and @path.isBlank()

    # Format the path.
    if @isValid and @path.startsWith('.')
      @path = fsPath.resolve("#{ @file.dir }/#{ @path }")

      # If this is a file 'require' directive, and an extension is not
      # present, infer the file-extension from the containing file.
      if @type is REQUIRE and fsPath.extname(@path).isBlank()
        @path += @file.extension



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

        console.log '@isPath', @isPath, @type, @path

        # Ensure the file can be added.
        if @isPath
          throw new Error("The file for the directive [#{ @text }] does not exist [Path: #{ file.path }].") unless file.exists
        throw new Error("The file for the directive [#{ @text }] is not valid.") unless file.isValid
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
      when REQUIRE            then add(createFile(@path, withPrereqs:false))
      when REQUIRE_DIRECTORY  then addFiles File.directory(@path, withPrereqs:false)[@file.domain]
      when REQUIRE_TREE       then addFiles File.tree(@path, withPrereqs:false)[@file.domain]


    # Finish up.
    result
