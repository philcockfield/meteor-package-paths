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
    # Setup initial conditions.
    force = options.force is true
    path  = fsPath.join(dir, 'package.js')
    return false if fs.existsSync(path) and not force

    # Save the base template.
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
      });

      """

    fs.writeFileSync(path, tmpl)

    # Insert the "add_files" block.
    @update(dir)

    # Finish up.
    true



  ###
  Updates the [add_new] statements within the package.js file.
  @param dir: The directory to the package.js file resides within.
  @returns true if the file was updated, or false if the file does not already exist.
  ###
  update: (dir) ->
    # Setup initial conditions.
    path = fsPath.join(dir, 'package.js')
    return false unless fs.existsSync(path)

    # Get the package.js file as an array with all the [add_files] lines removed.
    lines = readFile(path)
    lines = lines.filter (line) ->
      return false if line.has(/api.add_files/)
      return false if line.has(new RegExp(js.GENERATED_HEADER))
      return false if line.has(new RegExp(js.GENERATED_TIME_STAMP))
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
    addLine("  #{ js.GENERATED_TIME_STAMP } #{ new Date() }")
    for fileLine in js.addFiles(dir).trim().split('\n')
      addLine("  #{ fileLine.trim() }")
    addLine()

    # Finish up.
    fs.writeFileSync(path, lines.join('\n'))
    true


  ###
  Runs update on all child folders within the given directory.
  @param dir: The directory that contains the folders to update.
  @returns object containing results.
  ###
  updateAll: (dir) ->
    # Setup initial conditions.
    result =
      total: 0
      updated: 0
      folders: {}

    # Get the child folders.
    paths = fs.readdirSync(dir).map (name) -> fsPath.join(dir, name)
    paths = paths.filter (path) -> fs.statSync(path).isDirectory()

    # Perform the update operations.
    for path in paths
      dirName        = fsPath.basename(path)
      wasUpdated     = @update(path)
      result.total   += 1
      result.updated += 1 if wasUpdated
      result.folders[dirName] =
        updated: wasUpdated
        path:    fsPath.join(path, 'package.js')

    # Finish up.
    result




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