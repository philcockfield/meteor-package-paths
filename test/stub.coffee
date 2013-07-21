module.exports =
  api:
    add_files: (path, where) ->
      console.log ' add_files'.blue, where.toString().red, path.grey