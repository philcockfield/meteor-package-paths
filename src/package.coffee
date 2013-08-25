fs     = require 'fs'
fsPath = require 'path'
wrench = require 'wrench'
js     = require './javascript'


module.exports =
  ###
  Creates a new package.js file.
  @param dir: The directory to create the package within.
  @param options:
            - summary:  The summary description of the package.
            - force:    Flag indicating if the file should be overwritten.
            - withDirs: Flag indicating if the [client/server/shared] directories should be created.
  @returns true if the package file was created, otherwise false.
  ###
  create: (dir, options = {}) ->
    # Setup initial conditions.
    summary   = options.summary ? ''
    force     = options.force is true
    withDirs  = options.withDirs is true
    path      = fsPath.join(dir, 'package.js')
    return false if fs.existsSync(path) and not force

    # Add the [client/server/shared] directories.
    if withDirs
      createDir(dir, 'client')
      createDir(dir, 'server')
      createDir(dir, 'shared')


    # Save the base template.
    add_files = js.addFiles(dir).trim()
    tmpl =
      """
      Package.describe({
        summary: '#{ summary }'
      });



      Package.on_use(function (api) {
        api.use('http', ['client', 'server']);
        api.use('templating', 'client');
        api.use('coffeescript');
        api.use('sugar');
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

    # Determine if the resulting package.js is different.
    newPackage = lines.join('\n')
    currentPackage = readFile(path).join('\n')
    return false if (newPackage is currentPackage)

    # Finish up.
    fs.writeFileSync(path, newPackage)
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
      path: dir
      folders: {}

    # Get the child folders.
    paths = fs.readdirSync(dir).map (name) -> fsPath.join(dir, name)
    paths = paths.filter (path) ->  fs.statSync(path).isDirectory()
    paths = paths.filter (path) ->  not fs.lstatSync(path).isSymbolicLink()

    # Perform the update operations.
    for path in paths
      dirName = fsPath.basename(path)
      if fs.existsSync(fsPath.join("#{ path }/package.js"))
        wasUpdated = @update(path)
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


createDir = (base, name) ->
  path = fsPath.join(base, name)
  fs.mkdirSync(path) unless fs.existsSync(path)



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
  withinFunction = false
  for line, i in lines
    withinFunction = true if isFunctionOnUse(line)
    if withinFunction
      return i if isFunctionEnd(line)
  -1 # Not found.



