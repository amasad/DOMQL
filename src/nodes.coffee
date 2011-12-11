exports.Select = class Select
  constructor: (@fields, @source) ->

  eval: ->
    source = if typeof @source is 'string'
      Sizzle @source
    else
      @source.eval()
    console.log source, @fields
    res = []
    if source.length is 1
      Sizzle '>' + field, source[0], res for field in @fields
    else
      console.log 'xx', @fields[0], Sizzle.matches @fields[0], source, res
      for field in @fields
        res = res.concat Sizzle.matches field, source
      return res
    if @where?
      Sizzle.matches @where.compile(), res
    else
      res

exports.Where = class Where
  constructor: (@expression) ->
    
  compile: ->
    @expression

exports.AttrOper = class AttrOper
  constructor: (@op1, [@oper, @op2]) ->
  
  compile: ->
    switch @oper
      when '=' then "[#{@op1}=#{@op2}]"
      when '<>' then "[#{@op1}!=#{@op2}]"
      when 'LIKE' then "[#{op1}*=#{@op2}]"
      when 'IN'
        ("[#{@op1}=#{op}]" for op in @op2).join ','
      
  toString: -> @compile()