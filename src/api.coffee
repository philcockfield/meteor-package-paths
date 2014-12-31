require 'colors'
require 'sugar'

File   = require './file'


module.exports = loader =

  ###
  Generates the ordered list of files under the given directory (shallow).
  @param dir: The root directory to retrieve the file listing from.
  ###
  directory: (dir) -> File.directory(dir)


  ###
  Gets the [File] object for the given path.
  @param path: The path to the file to load.
  ###
  file: (path) ->
    file = new File(path)
    file if file.isValid


