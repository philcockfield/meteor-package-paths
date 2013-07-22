fs     = require 'fs'
fsPath = require 'path'
wrench = require 'wrench'
js     = require './javascript'


module.exports =
  ###
  Creates a new package.js file.
  @param dir: The directory to create the package within.
  @param options:
            - force: Flag indicating if the file should be overwritten.
  @returns true if the package file was created, otherwise false.
  ###
  create: (dir, options = {}) ->
    force = options.force is true
    path  = fsPath.join(dir, 'package.js')
    return false if fs.existsSync(path) and not force


    add_files = js.addFiles(dir).trim()

    tmpl =
      """
      Package.describe({
        summary: ''
      });



      Package.on_use(function (api) {
        api.use('coffeescript');
        api.use('sugar');
        api.use('http', ['client', 'server']);
        api.use('templating', 'client');
        api.use('core');

        #{ js.GENERATED_HEADER }
        #{ add_files }

      });

      """

    # Finish up.
    fs.writeFileSync(path, tmpl)
    true



  ###
  Updates the [add_new] statements within the package.js file.
  ###
  update: (dir) ->
    # Setup initial conditions.
    path = fsPath.join(dir, 'package.js')
    return @create(dir) unless fs.existsSync(path)

    # Get the package.js file as an array with all the [add_files] lines removed.
    lines = readFile(path)
    lines = lines.filter (line) ->
      return false if line.has(/api.add_files/)
      return false if line.has(new RegExp(js.GENERATED_HEADER))
      true
    lines = filterWithinOnUse lines, (line) -> not line.isBlank()

    # Get the insertion point.
    insertAt = getInsertionPoint(lines)
    if insertAt < 0
      throw new Error('Could not find an insertion location for the "add_files" methods.')


    # Insert the "add_files" statements.
    addLine = (text = '') ->
      lines.add(text, insertAt)
      insertAt += 1

    addLine()
    addLine("  #{ js.GENERATED_HEADER }")
    for fileLine in js.addFiles(dir).trim().split('\n')
      addLine("  #{ fileLine.trim() }")
    addLine()

    # Finish up.
    fs.writeFileSync(path, lines.join('\n'))
    true




# PRIVATE --------------------------------------------------------------------------


readFile = (path) ->
  text = fs.readFileSync(path).toString()
  text.split('\n')


isFunctionEnd = (line) -> line.has /\}\)\;/
isFunctionOnUse = (line) -> line.has /Package.on_use/

filterWithinOnUse = (lines, func) ->
  withinFunction = false
  lines.filter (line) ->
    if isFunctionOnUse(line)
      withinFunction = true
      return true
    withinFunction = false if withinFunction and isFunctionEnd(line)
    if withinFunction
      func(line)
    else
      true

getInsertionPoint = (lines) ->
  insertAt = -1
  withinFunction = false
  for line, i in lines
    withinFunction = true if isFunctionOnUse(line)
    if withinFunction
      return i if isFunctionEnd(line)

  # Finish up.
  -1