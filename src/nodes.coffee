if typeof window isnt 'undefined'
  {Sizzle} = require './lib/sizzle'

nodes = exports
evalQuery = (source) ->
  if typeof source is 'string'
    Sizzle source
  else
    source.eval()

nodes.QueryList = class Queries
  constructor: (first) ->
    @queries = [first]
    @type = 'QueryList'

  add: (query) ->
    @queries.push query
    return @

  eval: ->
    # Eval all queries but get the last result.
    (query.eval() for query in @queries)[-1...][0]

nodes.Select = class Select
  constructor: (@fields, @source, @isAll) ->
    @type = 'Select'

  eval: ->
    source = evalQuery @source

    prefix = if @isAll then '' else '>'

    res = []
    for elem in source
      Sizzle prefix + field, elem, res for field in @fields

    res = @where.eval res if @where?

    return @fields.exec res if @fields instanceof nodes.Function
    res

setAttributes = (elem, attrs) ->
  for attr in attrs
    if attr[0] in ['innerHTML', 'html']
      elem.innerHTML = attr[1]
    else if attr[0] in ['innerText', 'text']
      elem.innerText = attr[1]
      elem.textContent = attr[1]
    else
      elem.setAttribute attr[0], attr[1]

nodes.Update = class Update
  constructor: (@source, @settings) ->
    @type = 'Update'

  eval: ->
    res = evalQuery @source
    res = @where.eval res if @where?
    setAttributes elem, @settings for elem in res
    return res

nodes.Delete = class Delete extends Select
  constructor: (@source, @settings) ->
    @type = 'Delete'

  eval: ->
    res = super()
    for elem in res
      parent = elem.parentElement || elem.parentNode
      parent.removeChild elem

nodes.Create = class Create
  constructor: (@tag, @attrs) ->
    @type = 'Create'

  eval: ->
    elem = document.createElement @tag
    setAttributes elem, @attrs
    return [elem]

nodes.Insert = class Insert
  constructor: (@target, @sources) ->
    @type = 'Insert'

  eval: ->
    targets = evalQuery @target
    sources = (query.eval() for query in @sources)
    for elem in targets
      for source in sources
        for child in source
          elem.appendChild child
    targets

nodes.Drop = class Drop
  constructor: (@target) ->
    @type = 'Drop'

  eval: ->
    target = evalQuery @target
    for elem in target
      parent = elem.parentElement || elem.parentNode
      parent.removeChild elem

nodes.Where = class Where
  constructor: (@expression) ->
    @type = 'Where'

  eval: (res) ->
    Sizzle.matches @expression, res

nodes.AttrOper = class AttrOper
  constructor: (@op1, [@oper, @op2]) ->
    @type = 'Attribute Operation'

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
    @type = 'RowNum Operation'

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
    @type = 'Function'

  exec: (res) ->
    switch @fnName
      when 'COUNT' then res.length
      when 'VAL' then res[0].value
      when 'TEXT' then res[0].innerText or res[0].textContent
