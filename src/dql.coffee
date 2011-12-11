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
  console.log tokens
  parser.parse(tokens).eval()
