KEYWORDS = [
  # Statements
  'SELECT', 'DELETE', 'UPDATE', 'INSERT', 'DROP', 'CREATE'

  # Operators
  'FROM', 'INTO', 'WHERE', 'SET'

  # Logic
  'AND', 'OR', 'NOT'

  # Compare
  'LIKE', 'BETWEEN', 'IN'

  # Keywords
  'ROWNUM', 'ELEMENT', 'VALUES'

  # Postfix operator
  'ALL'
]

FUNCTION = ['COUNT', 'TEXT', 'VAL']

SYMBOLS =
  '=': 'EQ'
  '>': 'GT'
  '<': 'LT'
  '*': 'STAR'
  '.': 'DOT' 
  ',': 'COMMA'
  '(': 'LPAREN'
  ')': 'RPAREN'
  ';': 'TERMINATOR'

SYMBOL_LIST = (key for key of SYMBOLS)

STRING = /^'[^\\']*(?:\\.[^\\']*)*'/
NUMBER = /^-?\d+/
IDENTIFIER = /^[A-Za-z]\w*/


exports.Lexer = class Lexer
  
  token: (type, val) ->
    @tokens.push [type, val, @line]
  
  error: (type) ->
    throw SyntaxError switch type
      when 'mismatch' then 'MISMATCHED PARENS'
      when 'unrecognized' then 'UNRECOGNIZED TOKEN ' + @chunk.match(/([^\s]*)\b/)[1]

  tokenize: (@code) ->
    @tokens = []
    @stackMatch = []
    @line = 0
    
    i = 0
    while @chunk = @code.slice i
      b = @whitespace() or
          @wordMatch() or
          @identifierMatch() or
          @literalMatch() or
          @charMatch()

      if b is 0 then @error 'unrecognized'
      i += b
    if @tokens[-1...][0][0] isnt 'TERMINATOR' then @tokens.push ['TERMINATOR', ';', @line]
    return @tokens

  whitespace: ->
    return 0 unless match = @chunk.match /^[ \n\r]+/
    newLines = match[0].split(/\n/).length - 1
    @line += newLines
    return match[0].length

  wordMatch: ->
    return 0 unless match = @chunk.match /^\w+/
    
    word = match[0].toUpperCase()
    # KEYWORDS:
    if word in KEYWORDS
      @token word, word
    else if word in FUNCTION
      @token 'FUNCTION', word
    else 
      return 0
    
    return word.length
  
  identifierMatch: ->
    return 0 unless match = @chunk.match IDENTIFIER
    @token 'IDENTIFIER', match[0]
    return match[0].length
  
  literalMatch: ->
    if match = @chunk.match STRING
      @token 'STRING', match[0].slice(1,-1)
      return match[0].length
    else if match = @chunk.match NUMBER
      @token 'NUMBER', match[0]
      return match[0].length
    else
      return 0
  
  charMatch: ->
    val = @chunk[0]
    if val in SYMBOL_LIST
      @token SYMBOLS[val], val
      return 1
    else if val is '-' and @chunk[1] is '-'
      return @code.length
    else
      return 0

    