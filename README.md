#About
An SQL-like language for querying the DOM. More info [here](http://amasad.github.com/DOMQL/).

#Development
DOMQL is an interpereted language powered by the [Sizzle](http://sizzlejs.com/) selector engine.   
Most SELECT queries can be directly compiled to a Sizzle query (see src/test.coffee).  

DOMQL is written using the [Jison](http://zaach.github.com/jison/) parser generator.  

##Source Files Overview

* dql.coffee is the main file. Responsible for initiating the parser and contains some utils (domReady, templates etc).
* grammer.coffee is the language grammer file written in CoffeeScript's Jison DSL.
* lexer.coffee is the language lexer.
* nodes.coffee contains all the nodes for the syntax tree also responsible for compiling to sizzle / evaluating the code.
* test.coffee the test suite ran by index.html.

##Getting the Code

    git clone git@github.com:amasad/DOMQL.git  

##Dependancies

* NodeJS for the development environment.
* Browserify for Node requires to work in the browser.
* express for development server.
* uglify-js for minifying build file.
* Jison for creating the parser.

You only need to install NodeJS. All the modules are checked in.  
Note that browserify has been altered to work around a bug.

##Running

Using CoffeeScript's Cakefile you could do the following:

* `cake buildParser` : Builds the parser.
* `cake dev` : Starts the development server at localhost:8080 and watches the grammer file for changes to rebuild the parser.
* `cake build` : Builds and minifies to domql.min.js.

##Tests
Run `cake dev` and navigate your browser to http://localhost:8080 then open your JavaScript console to see the test results.

#License
The MIT License
Copyright 2012 Amjad Masad <amjad.masad@gmail.com>

