fs = require 'fs'
browserify = require 'browserify'
express = require 'express'
{exec} = require 'child_process'

task 'buildParser', 'build parser', ->
  console.log 'buildin shit'
  {parser} = require('./src/grammar')
  fs.writeFileSync 'src/parser.js', parser.generate()
  
task 'dev', 'bebs', ->
  fs.watchFile './src/grammar.coffee', {interval: -1}, ->
    exec 'cake buildParser', (e, output) ->
      if e then throw e
      console.log(output)
  
  exec 'cake buildParser', (e, output)->
    if e then throw e
    console.log output
    app = express.createServer()
    app.listen 8080
    b = browserify 'src/test.coffee',
      watch: {interval: -1}
      ignore: ['file', 'system']
    app.use b
    app.use express.static __dirname
