fs = require 'fs'
browserify = require 'browserify'
express = require 'express'
{exec} = require 'child_process'

buildParser = ->
  {parser} = require('./src/grammar')
  fs.writeFileSync 'src/parser.js', parser.generate()

task 'buildParser', 'build parser', buildParser

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
    fs.writeFileSync 'domql.min.js', final_code

option '-f', '--file [FILE]', 'file to compile'

lex = (code) ->
  {Lexer} = require('./src/lexer')
  lexer = new Lexer()
  lexer.tokenize(code)

task 'lex', (options) ->
  throw 'Need a file to lex' if not options.file
  code = fs.readFileSync options.file, 'utf8'
  console.log(lex(code))

task 'parse', (options) ->
  throw 'Need a file to parse' if not options.file
  code = fs.readFileSync options.file, 'utf8'
  {parser} = require('./src/parser')
  parser.lexer =
    lex: ->
      [tag, @yytext, @yylineno] = @tokens[@pos++] or ['']
      tag
    setInput: (@tokens) -> @pos = 0
    upcomingInput: -> ""
  parser.yy = require './src/nodes'
  util = require('util')
  console.log(util.inspect(parser.parse(lex(code)), depth: null))
