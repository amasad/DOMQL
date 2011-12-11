###
  SELECT * FROM BODY
  BODY > *
  
  SELECT * FROM BODY.ALL
  BODY *
  
  SELECT DIV,SPAN FROM BODY
  BODY > DIV, BODY > SPAN
  
  SELECT DIV FROM BODY.ALL WHERE ID = 'A'
  [ID=A]
  
  SELECT SPAN FROM (SELECT DIV FROM BODY.ALL WHERE ROWNUM = 1) 
  SIZZLE('>SPAN', SIZZLE('BODY DIV:eq(1)')
  
  DELETE DIV FROM (SELECT DIV FROM BODY.ALL)
  delete(SIZZLE(DIV, SIZZLE(BODY DIV)))
  
  INSERT INTO BODY (CREATE DIV (
    ID  "amjad"
  ))
###
WORDS = 
  COMMAND: ['SELECT', 'DELETE', 'UPDATE', 'INSERT', 'DROP', 'CREATE']
  OPERATOR: ['FROM', 'INTO', 'WHERE']
  LOGIC: ['AND', 'OR']
  COMPARE: ['LIKE', 'BETWEEN', 'IN']

SYMBOLS =
  EQ: '='
  GT: '>'
  LT: '<'
  STAR: '*'
  DOT: '.'
  COMMA: ','
  LPAREN: '('
  RPAREN: ')'

FUNCTION = ['COUNT']

STRING = /^'[^\\']*(?:\\.[^\\']*)*'/
NUMBER = /^-?\d+/
IDENTIFIER = /^[A-Za-z]\w*/

listify = (obj) ->
  isArray = Array.isArray or (arg) -> Object::toString.call(arg) is '[object Array]'
  ret = []
  for _, v of obj
    if Array.isArray v then ret = ret.concat v else ret.push v
  ret
WORD_LIST = listify WORDS
SYMBOL_LIST = listify SYMBOLS

SYMBOL_TAGS = do ->
  obj = {}
  for key, value of SYMBOLS
    obj[value] = key
  obj

exports.Lexer = class Lexer
  
  token: (type, val) -> 
    @tokens.push [type, val]
  
  error: (type) ->
    throw SyntaxError switch type
      when 'mismatch' then 'MISMATCHED PARENS'
      when 'unrecognized' then 'UNRECOGNIZED TOKEN ' + @chunk.match(/([^\s]*)\b/)[1]

  tokenize: (code) ->
    @tokens = []
    @stackMatch = []
    
    i = 0
    while @chunk = code.slice i
      b = @whitespace() or
          @wordMatch() or
          @identifierMatch() or
          @literalMatch() or
          @charMatch()

      if b is 0 then @error 'unrecognized'
      i += b
    @tokens.push ['TERMINATOR', '\n']
    return @tokens

  whitespace: ->
    return 0 unless match = @chunk.match /^\s+/
    return match[0].length

  wordMatch: ->
    return 0 unless match = @chunk.match /^\w+/
    
    word = match[0].toUpperCase()
    # KEYWORDS:
    if word in WORD_LIST
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
      @token 'STRING', match[0]
      return match[0].length
    else if match = @chunk.match NUMBER
      @token 'NUMBER', match[0]
      return match[0].length
    else
      return 0
  
  charMatch: ->
    val = @chunk[0]
    if val in SYMBOL_LIST
      @token SYMBOL_TAGS[val], val
      return 1
    else
      return 0

    