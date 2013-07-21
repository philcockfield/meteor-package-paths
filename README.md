# Meteor Package Loader

Provides sprockets style loading of files for a Meteor package.


## Testing from the Command Line

    $ bin/command.js --help

For example, from the command line:

    bin/command.js directory ./test/simple/client

    bin/command.js tree ./test/simple
    bin/command.js tree ./test/directives

    bin/command.js file ./test/simple/client/child/grand_child/grand_child.coffee
    bin/command.js file ./test/directives/client/child/grand_child/grand_child.coffee



