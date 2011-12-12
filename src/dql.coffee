{Lexer} = require './lexer'
{parser} = require './parser.js'

parser.lexer =
  lex: ->
    [tag, @yytext] = @tokens[@pos++] or ['']
    tag
  setInput: (@tokens) -> @pos = 0
  upcomingInput: -> ""

parser.yy = require './nodes'
l = new Lexer

window.DQL = (source) ->
  tokens = l.tokenize source
  parser.parse(tokens).eval()

window.DQL.ready = do ->
  fns = []
  f = false
  doc = document
  testEl = doc.documentElement
  hack = testEl.doScroll
  domContentLoaded = 'DOMContentLoaded'
  addEventListener = 'addEventListener'
  onreadystatechange = 'onreadystatechange'
  loaded = /^loade|c/.test(doc.readyState)

  flush = (f) ->
    loaded = 1
    f() while (f = fns.shift())
  
  doc[addEventListener] and doc[addEventListener](domContentLoaded, fn = (->
    doc.removeEventListener domContentLoaded, fn, f
    flush()
  ), f)

  if hack then doc.attachEvent(onreadystatechange, fn = ->
    if /^c/.test(doc.readyState)
      doc.detachEvent(onreadystatechange, fn)
      flush())
  
  return if ready = hack then (fn) ->
    if self isnt top
      if loaded then fn() else fns.push(fn)
    else do ->
      try
        testEl.doScroll('left')
      catch e
        return setTimeout (->ready(fn)), 50
      fn()
  else (fn) -> if loaded then fn() else fns.push(fn)


