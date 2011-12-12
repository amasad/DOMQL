nodes = exports

nodes.Select = class Select
  constructor: (@fields, @source, @isAll) ->

  eval: ->
    source = if typeof @source is 'string'
      Sizzle @source
    else
      @source.eval()
    
    prefix = if @isAll then '' else '>'
    
    res = []
    for elem in source
      Sizzle prefix + field, elem, res for field in @fields
          
    res = @where.eval res if @where?
    
    return @fields.exec res if @fields instanceof nodes.Function
    res

nodes.Update = class Update
  constructor: (@source, @settings) ->
  
  eval: ->
    res = @source.eval()
    res = @where.eval res if @where?
    for elem in res
      for setting in @settings
        elem.setAttribute setting[0], setting[1]
    return res

nodes.Delete = class Delete extends Select
  eval: ->
    res = super()
    elem.parentElement.removeChild elem for elem in res

nodes.Create = class Create
  constructor: (@tag, @attrs) ->
    console.log arguments
  eval: ->
    elem = document.createElement @tag
    for attr in @attrs
      if attr[0] in ['innerHTML', 'html']
        elem.innerHTML = attr[1]
      else
        elem.setAttribute attr[0], attr[1] 
    return [elem]

nodes.Insert = class Insert
  constructor: (@target, @sources) ->
    
  eval: ->
    targets = @target.eval()
    sources = (query.eval() for query in @sources)
    console.log @sources
    for elem in targets
      for source in sources
        console.log source
        for child in source
          elem.appendChild child
  
nodes.Where = class Where
  constructor: (@expression) ->

  eval: (res) ->
    Sizzle.matches @expression, res

nodes.AttrOper = class AttrOper
  constructor: (@op1, [@oper, @op2]) ->
  
  compile: ->
    switch @oper
      when '=' then "[#{@op1}=#{@op2}]"
      when '<>' then "[#{@op1}!=#{@op2}]"
      when 'LIKE' then "[#{@op1}*=#{@op2}]"
      when 'IN'
        ("[#{@op1}=#{op}]" for op in @op2).join ','
      
  toString: -> @compile()
  
nodes.NumOper = class NumOper
  constructor: ([@oper, @op1, @op2]) ->
  
  compile: ->
    switch @oper
      when '>' then ":gt(#{@op1})"
      when '<' then ":lt(#{@op1})"
      when '=' then ":eq(#{@op1})"
      when 'BETWEEN' then ":lt(#{@op2}):gt(#{@op1})"
      when 'IN'
        (":eq(#{op})" for op in @op1).join ','

nodes.Function = class Function extends Array
  constructor: (@fnName, @fields) ->
    @push v for v in @fields
    @length = @fields.length
    
  exec: (res) ->
    switch @fnName
      when 'COUNT'
        res.length

        
      