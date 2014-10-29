# Meteor Package Paths
Manages file paths for Meteor packages.

File inclusion is handled automatically by Meteor for `apps`. Unfortunately this is not so for packages
which have explicit file inclusion references within the `package.js` file.

This package scans the folder strucutre of your package(s) automatically updating the
file inclusion paths within your `package.js` file.

While this tool updates the `package.js` file, it is non-destructive and only changes
the file path references, leaving all other lines within `package.js` intact.

Along with emulating the default Meteor file load order rules, this package
provides [sprockets](https://github.com/sstephenson/sprockets) style overriding
of the load order of files within the `package.js` file.  This can be particularly
useful in the odd occasion where you really need one JS file to exist in the environment
prior to another - and you don't wish to pervert your naming or folder structure
to achieve that.




## Installation
Install globally so you can use the command line from any folder.

    npm install -g meteor-package-paths

## Usage
This module assumes you are structuring your package folders like this:

    /my-package
      /client
      /server
      /shared
      /images

To see the available commands, from within your package folder:

    $ package --help


To create a fresh `package.js` file with all the correct `api.addFiles` entries:

    $ cd my-package
    $ package create 'My Package'

To update an existing `package.js` file:

    $ cd my-package
    $ package update

The resulting `package.js` file will contain the `api.addFiles` listing for your package taking into account any
sprokets style comment directives you may have within any of the files.

And to update your app's entire set of packages:

    $ cd my-app/packages
    $ package update-all

Note, calling `update-all` will not effect any packages that have been sym-linked into your app.


## Load Order

#### Path Directives
The default load order is deepest to shallowest.  Use the comment directives to override
this ordering:

    require
    require_directory (shallow)
    require_tree      (deep)

For example:

    #= require file.coffee
    #= require_tree ../dir/foo
    #= require_directory ../dir/foo

    //= require file.js
    //= require_tree ../dir/foo
    //= require_directory ../dir/foo

#### Base directives
Files containing the `base` directive are ordered first, shallowest to deepest.  This is a
reversal of the above rules and is useful for the common pattern of having base classes
declared in parent folders, under which folders contianing the files of deriving classes reside.

    #= base
    //= base

#### Exclusions
To exclude a file:

    #= exclude


#### Exclusions
Images can be placed anywhere within the folder structure, and they are only added
to the `client`.  By convention, images are typically stored under:

    /my-package
      /images



## Testing from the Command Line

    $ package --help

For example, from the command line:

    $ package directory ./test/simple/client

    $ package tree ./test/simple
    $ package tree ./test/directives

    $ package file ./test/simple/client/child/grand_child/grand_child.coffee
    $ package file ./test/directives/client/child/grand_child/grand_child.coffee


#### Main
Files named `main` will be ordered last, deepest to shallowest.


#### 'Where' Overrides
The execution domain (`client` / `server` / `shared`) is whatever the closest `where` name folder is.
For example, you could override the `shared` folder, declaring some `client`-only files within it like this:

    /shared
      foo.js
      /client
        css.styl
        template.html


#### Package tests
Use the same `client` / `server` / `shared` folder structure within a `tests` directory
to have the test files output within the package's `Package.on_test` declaration block.



## License

The [MIT License](http://www.opensource.org/licenses/mit-license.php) (MIT)

Copyright © 2013 [Phil Cockfield](https://github.com/philcockfield) | [Tim Haines](https://github.com/timhaines)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
