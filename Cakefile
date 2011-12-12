fs = require 'fs'
browserify = require 'browserify'
express = require 'express'
{exec} = require 'child_process'

task 'buildParser', 'build parser', ->
  {parser} = require('./src/grammar')
  fs.writeFileSync 'src/parser.js', parser.generate()
  
task 'dev', 'dev server', ->
  fs.watchFile './src/grammar.coffee', {interval: -1}, ->
    exec 'cake buildParser', (e, output) ->
      throw e if e
      console.log(output)
  
  exec 'cake buildParser', (e, output)->
    throw e if e
    console.log output
    app = express.createServer()
    app.listen 8080
    b = browserify 'src/test.coffee',
      watch: {interval: -1}
      ignore: ['file', 'system']
    app.use b
    app.use express.static __dirname

task 'build', 'build', ->
  exec 'cake buildParser', (e, output) ->
    throw e if e
    console.log output
    b = browserify 'src/dql.coffee',
      ignore: ['file', 'system']
    jsp = require("uglify-js").parser;
    pro = require("uglify-js").uglify;
    ast = jsp.parse b.bundle()
    ast = pro.ast_mangle(ast)
    ast = pro.ast_squeeze(ast)
    final_code = pro.gen_code(ast)
    fs.writeFileSync 'built.js', final_code