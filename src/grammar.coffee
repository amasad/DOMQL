{Parser} = require 'jison'

# CoffeeScript JISON DSL

unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/

o = (patternString, action, options) ->
  patternString = patternString.replace /\s{2,}/g, ' '
  return [patternString, '$$ = $1;', options] unless action
  action = if match = unwrap.exec action then match[1] else "(#{action}())"
  action = action.replace /\bnew /g, '$&yy.'
  action = action.replace /\b(?:Block\.wrap|extend)\b/g, 'yy.$&'
  [patternString, "$$ = #{action};", options]


grammar =
  
  Root: [
    o 'Query TERMINATOR'
  ]
  
  Query: [
    o 'SelectQuery'
    # o 'InsertQuery'
    # o 'CreateQuery'
    # o 'DropQuery'
    # o 'DeleteQuery'ssssss
  ]
  
  SelectQuery: [
    o 'Select'
    o 'Select Where',                                      -> $1.where = $2; $1
  ]
  
  Select: [
    o 'SELECT Fields FROM Table',                          -> new Select $2, $4
  ]
  
  Fields: [
    o 'Field',                                             -> [$1]
    o 'Fields COMMA Field',                                -> $1.concat $3
  ]
  
  Field: [
    o 'IDENTIFIER'
    o 'STAR'
  ]
  
  Table: [
    o 'IDENTIFIER'
    o 'LPAREN Query RPAREN',                              -> $2
  ]
  
  Where: [
    o 'WHERE Expression',                                  -> new Where $2
  ]
  
  Expression: [
    o 'Expression Logic Expression',                        -> $1 + $2 + $3
    o 'IDENTIFIER AttributeCompare',                        -> new AttrOper($1, $2).compile()
    o 'ROWNUM RownumCompare',                               -> new NumOper($1, $2).compile()
  ]
  
  Logic: [
    o 'AND',                                               -> ''
    o 'OR',                                                -> ','
  ]
  
  AttributeCompare: [
    o 'EQ Value',                                          -> [$1, $2]
    o 'LT GT Value',                                       -> [$1 + $2, $3]
    o 'LIKE Value',                                        -> [$1, $2]
    o 'IN Values',                                         -> [$1, $2]
  ]
  
  RownumCompare: [
    o 'EQ Number',                                          -> [$1, $2]
    o 'LT Number',                                          -> [$1, $2]
    o 'GT Number',                                          -> [$1, $2]
    o 'IN Values',                                          -> [$1, $2]
    o 'BETWEEN Number AND Number',                           -> [$1, $2, $4]
  ]
  
  Values: [
    o 'Value',                                             -> [$1]
    o 'Values COMMA Value',                                -> $1.concat $3
  ]
  
  Value: [
    o 'STRING'
    o 'NUMBER'
  ]

tokens = []
for name, alternatives of grammar
  grammar[name] = for alt in alternatives
    for token in alt[0].split ' '
      tokens.push token unless grammar[token]
    alt[1] = "return #{alt[1]}" if name is 'Root'
    alt

exports.parser = new Parser
  tokens: tokens.join ' '
  bnf: grammar
  statSymbol: 'Root'

  