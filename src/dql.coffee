{Lexer} = require './lexer'
{parser} = require './parser.js'
{Sizzle} = require './lib/sizzle'

parser.lexer =
  lex: ->
    [tag, @yytext, @yylineno] = @tokens[@pos++] or ['']
    tag
  setInput: (@tokens) -> @pos = 0
  upcomingInput: -> ""

parser.yy = require './nodes'
l = new Lexer

formatRegExp = /%[sdj%]/g
format = (f, args) ->
  i = 0
  len = args.length
  String(f).replace formatRegExp, (x) ->
    return x if i >= len
    switch x
      when '%s' then String(args[i++])
      when '%d' then Number(args[i++])
      when '%j' then JSON.stringify(args[i++])
      when '%%' then '%'
      else return x;
  
DOMQL = (source, args...) ->
  source = format source, args
  tokens = l.tokenize source
  parser.parse(tokens).eval()

DOMQL.tmpls = {}

DOMQL.addTmpl = (name, source) ->
  DOMQL.tmpls[name] = source

DOMQL.tmpl = (name, args...) ->
  tmpl = DOMQL.tmpls[name]
  if tmpl?
    DOMQL tmpl, args...
  else
    throw new Error 'Template not found.'

DOMQL.ready = do ->
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

DOMQL.ready ->
  for tmpl in Sizzle('script[type="text/domql-tmpl"]')
    DOMQL.addTmpl tmpl.getAttribute('id'), tmpl.innerHTML
  
  DOMQL script.innerHTML for script in Sizzle('script[type="text/domql"]')

DOMQL.DELETE = (elem) ->
  elem.parentElement.removeChild elem

window.DOMQL = DOMQL

  