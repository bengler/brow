# Brow

Brow automatically configures all you rack apps and pebbles to be served with unicorn through nginx. It 
takes care of mapping all your pebbles into the url-space of all your apps.

## Requirements

* You must have nginx installed via macports or homebrew
* All apps must use bundler and have unicorn in its Gemfile
* Currently you must use Mac OS X – Ubuntu to follow

## Installation

    git clone git@github.com:benglerpebbles/brow.git
    cd brow
    rake install

## Usage

Check that everytning installed correctly by listing configured services

    brow status

Now you have a .brow folder in your home directory which you can use to mount your rack services. Symlink your
pebbles in .brow/pebbles and your applications in .brow/apps. Then do:

    brow up

To launch everyting. This will launch a unicorn server for every app and pebble and configure the apps to
run with all pebbles proxied in via nginx. Each app will be availible like this:

    http://yourapp.dev

To restart a single pebble or app, do this:

    brow restart checkpoint

To restart everything do

    brow restart

To kill all:

    brow down

To execute a command in all repos, do:

    brow exec bundle install

## Pebbles?!

This is not the time nor place to describe the details of the pebbles spec, suffice it to say that each service
added to the pebbles folder is proxied into the url space of every app at /api/[service-name]
