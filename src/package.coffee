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



      Package.on_test(function (api) {
        api.use(['tinytest', 'coffeescript']);
        api.use(['templating', 'ui', 'spacebars'], 'client');
        // api.use(''); // Package name in [smart.json]
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
    packagePath = fsPath.join(dir, 'package.js')
    return false unless fs.existsSync(packagePath)

    # Get the package.js file as an array with all the [add_files] lines removed.
    lines = readFile(packagePath)
    lines = lines.filter (line) ->
                return false if line.has(/api.add_files/)
                return false if line.has(new RegExp(js.GENERATED_HEADER))
                true

    lines = filterWithin /Package.on_use/, lines, (line) -> not line.isBlank()
    lines = filterWithin /Package.on_test/, lines, (line) -> not line.isBlank()

    insertLines = (withinFuncRegex, path, prefix) ->
            # Get the insertion point.
            insertAt = getInsertionPoint(withinFuncRegex, lines)
            return if insertAt < 0

            # Insert the "add_files" statements.
            addLine = (text = '') ->
              lines.add(text, insertAt)
              insertAt += 1

            addLine()
            addLine("  #{ js.GENERATED_HEADER }")
            for fileLine in js.addFiles(path, prefix).trim().split('\n')
              addLine("  #{ fileLine.trim() }")
            addLine()

    insertLines(/Package.on_use/, dir)
    insertLines(/Package.on_test/, fsPath.join(dir, 'tests'), 'tests/')

    # Determine if the resulting package.js is different.
    newPackage = lines.join('\n')
    currentPackage = readFile(packagePath).join('\n')
    return false if (newPackage is currentPackage)

    # Finish up.
    fs.writeFileSync(packagePath, newPackage)
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


    filter = (path) ->
      try
        isDirectory = fs.statSync(path).isDirectory()
        isSymLink = fs.lstatSync(path).isSymbolicLink()
        isDirectory and not isSymLink

      catch e
        console.log "WARNING Problem with the path: #{ path }".red

    # Get the child folders.
    paths = fs.readdirSync(dir).map (name) -> fsPath.join(dir, name)
    paths = paths.filter (path) -> filter(path)

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
# isFunctionOnUse = (line) -> line.has /Package.on_use/

filterWithin = (funcStartRegEx, lines, func) ->
  withinFunction = false
  lines.filter (line) ->
    if line.has(funcStartRegEx)
      withinFunction = true
      return true
    withinFunction = false if withinFunction and isFunctionEnd(line)
    if withinFunction
      func(line)
    else
      true

getInsertionPoint = (funcStartRegEx, lines) ->
  withinFunction = false
  for line, i in lines
    withinFunction = true if line.has(funcStartRegEx)
    if withinFunction
      return i if isFunctionEnd(line)
  -1 # Not found.



