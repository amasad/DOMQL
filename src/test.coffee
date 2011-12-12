class AssertionError extends Error
  name: 'AssertionError'
  constructor: ({@message, @actual, @expected}) ->
    console.log '\t Expected : ', @expected
    console.log '\t But got  : ', @actual

assert =
  _makeArray: (obj) -> Array::slice.call obj
  
  ok: (val) ->
    if !!!val then throw new AssertionError {
      message: 'Not OK'
      expected: true
      actual: false
    }
  
  strictEqual: (actual, expected) ->
    if actual isnt expected then throw new AssertionError {
      message: 'Not strictly equal'
      expected
      actual
    }
    
  collectionEqual: (actual, expected) ->
    actual = assert._makeArray actual
    expected = assert._makeArray expected
    if actual.length isnt expected.length then throw new AssertionError {
      message: 'Collections not equal in length.'
      expected
      actual
    }
    
    check = (col1, col2) ->
      for elem in col1
        if elem not in col2 then throw new AssertionError {
          message: 'Different elements.'
          expected
          actual
        }
    
    check actual, expected
    check expected, actual
  
require './dql'

tests =
  SELECT: 
    'SELECT * FROM BODY': 'body > *'
    'SELECT * FROM (SELECT * FROM BODY)': 'body > * > *'
    'SELECT * FROM (SELECT * FROM (SELECT * FROM BODY))': 'body > * > * > *'
    'SELECT SPAN FROM BODY': 'body > span'
    'SELECT DIV,SPAN FROM BODY': 'body > div, body > span'
    'SELECT LI FROM (SELECT UL FROM BODY)': 'body > ul > li'
    'SELECT DIV FROM BODY WHERE ID = \'id-div\'': 'body > div#id-div'
    'SELECT DIV FROM BODY WHERE CLASS = \'all\'': 'body > div.all'
    'SELECT DIV FROM BODY WHERE CLASS = \'all\' AND ID = \'id-div\'': 'body > div.all#id-div'
    'SELECT DIV FROM BODY WHERE CLASS = \'all\' AND NOT ID = \'not-me\'': 'body > div.all:not(#not-me)'
    'SELECT DIV FROM BODY.ALL': 'body div'
    'SELECT * FROM (SELECT DIV FROM BODY).ALL': 'body > div *'
    'SELECT COUNT(*) from BODY': (res)-> Sizzle('body > *').length
    'SELECT COUNT(*) from BODY.ALL': (res) -> Sizzle('body *').length
  
  UPDATE:
    'UPDATE (SELECT H1 FROM BODY) SET ID = \'changed-id\'': (res) ->
      siz = Sizzle('#changed-id')
      assert.collectionEqual res, siz
      assert.ok siz.length
    'UPDATE (SELECT H2 FROM BODY) SET ID=\'changed-id2\', CLASS=\'changed-class\'': (res) ->
      siz = Sizzle('#changed-id2.changed-class')
      assert.collectionEqual res, siz
      assert.ok siz.length
    'UPDATE (SELECT H3 FROM BODY) SET CLASS=\'changed-us\'': (res) ->
      siz = Sizzle 'body > h3.changed-us'
      assert.collectionEqual res, siz
      assert.ok siz.length
    'UPDATE (SELECT LI FROM (SELECT OL FROM BODY)) SET CLASS=\'conditional-change\'': (res) ->
      siz = Sizzle 'body > ol > li.conditional-change'
      assert.collectionEqual res, siz
      assert.ok siz.length
helper =
  start: (type) ->
    console.log 'Testing %s', type
    @passed = Object.keys(tests[type]).length
  end: (type) ->
    console.log '%s testing passed %d/%d', type, @passed, Object.keys(tests[type]).length
    console.log ('*' for _ in [0...100]).join ''
  catcher: (e, query) ->
    @passed--
    if e instanceof AssertionError
      console.error 'Test Failed: %s with %s', query, e
    else
      console.log e.stack
  
DQL.ready ->
  helper.start 'SELECT'
  for query, selector of tests.SELECT
    try
      if typeof selector is 'string'
        assert.collectionEqual DQL(query), Sizzle selector
        console.log 'Test Passed: %s', query, Sizzle selector
      else
        selector DQL query
        console.log 'Test Passed: %s', query
    catch e
      helper.catcher e, query
  helper.end 'SELECT'
  
  
  console.log 'Testing UPDATE'
  for query, fn of tests.UPDATE
    try
      fn DQL query
      console.log 'Test Passed: %s', query
    catch e
      helper.catcher e, query
  
