fs     = require 'fs'
fsPath = require 'path'
wrench = require 'wrench'
js     = require './js'


module.exports =
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

                return true if line.has(/api.addFiles\('build\//)
                return true if line.has(/api.add_files\('build\//)

                return false if line.has(/api.add_files/)
                return false if line.has(/api.addFiles/)
                return false if line.has(new RegExp(js.GENERATED_HEADER))
                true

    isCamelCase = lines.any (line) -> line.indexOf('Package.onUse') > -1

    lines = filterWithin /Package.on_use/, lines, (line) -> not line.isBlank()
    lines = filterWithin /Package.on_test/, lines, (line) -> not line.isBlank()

    lines = filterWithin /Package.onUse/, lines, (line) -> not line.isBlank()
    lines = filterWithin /Package.onTest/, lines, (line) -> not line.isBlank()


    insertLines = (withinFuncRegex, path, prefix) ->
            # Get the insertion point.
            insertAt = getInsertionPoint(withinFuncRegex, lines)
            return if insertAt < 0

            # Insert the "add_files" statements.
            addLine = (text = '') ->
                lines.add(text, insertAt)
                insertAt += 1

            addLine()
            addLine("  #{ js.GENERATED_HEADER }") if lines.length > 0

            files = js.addFiles(path, pathPrefix:prefix, isCamelCase:isCamelCase)

            for fileLine in files.trim().split('\n')
              addLine("  #{ fileLine.trim() }")
            addLine()

    switch isCamelCase
      when true
        insertLines(/Package.onUse/, dir)
        insertLines(/Package.onTest/, fsPath.join(dir, 'tests'), 'tests/')

      when false
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
