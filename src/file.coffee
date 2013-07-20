fsPath = require 'path'
wrench = require 'wrench'

CLIENT = 'client'
SERVER = 'server'
SHARED = 'shared'



###
Represents a single file.
###
module.exports = class File
  constructor: (@path) ->
    @dir       = fsPath.dirname(@path)
    @extension = fsPath.extname(@path)
    @domain    = executionDomain(@)


  prereqs: -> []

  ###
  Retrieves an array of file directives from the initial lines that start
  with the directive comment, eg:
    //= (javascript)
    #=  (coffeescript)
  ###
  directives: ->
    # Setup initial conditions.
    commentPrefix = switch @extension
                      when '.js' then '//='
                      when '.coffee' then '#='
    return unless commentPrefix

    # Read the directive lines into an array.
    reader = new wrench.LineReader(@path)
    readLine = ->
      if reader.hasNextLine()
        line = reader.getNextLine()
        return line if line.startsWith(commentPrefix)

    result = []
    while line = readLine()
      unless line.trim() is commentPrefix
        result.push(line)

    # Finish up.
    reader.close()
    result




# PRIVATE --------------------------------------------------------------------------



executionDomain = (file) ->
  # Find the last reference within the path to an execution domain.
  for part in file.path.split('/').reverse()
    return CLIENT if part is CLIENT
    return SERVER if part is SERVER
    return SHARED if part is SHARED

  SHARED # No execution domain found - default to 'shared'.
