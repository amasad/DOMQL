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
{Sizzle} = require './lib/sizzle'

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
    'SELECT DIV FROM BODY WHERE ID LIKE \'like\'': 'body > div[class*=like]'
    'SELECT DIV FROM BODY.ALL': 'body div'
    'SELECT * FROM (SELECT DIV FROM BODY).ALL': 'body > div *'
    'SELECT LI FROM (SELECT UL FROM BODY) WHERE ROWNUM < 5 AND ROWNUM > 0': 'body > ul > li:lt(5):gt(0)'
    'SELECT LI FROM (SELECT UL FROM BODY) WHERE ROWNUM BETWEEN 0 AND 5': 'body > ul > li:lt(5):gt(0)'
    'SELECT LI FROM (SELECT UL FROM BODY) WHERE ROWNUM IN (1,2,4)': 'body > ul > li:eq(1),body > ul > li:eq(2),body > ul > li:eq(4)'
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
    'UPDATE (SELECT LI FROM (SELECT OL FROM BODY)) SET CLASS=\'conditional-change\' WHERE TITLE IN (\'a\', \'b\', \'c\')': (res) ->
      siz = Sizzle 'body > ol > li[title="a"],body > ol > li[title="b"],body > ol > li[title="c"]'
      assert.collectionEqual res, siz
      for elem in res
        assert.strictEqual elem.getAttribute('class'), 'conditional-change'
      assert.ok siz.length
  
  DELETE:
    'DELETE A FROM BODY WHERE HREF=\'delete-me\'': (res) ->
      siz = Sizzle 'body > a[href=\'delete-me\']'
      assert.ok !siz.length
    
    'DELETE LI FROM BODY.ALL WHERE ROWNUM BETWEEN 2 AND 5': (res) ->
      siz = Sizzle 'body > ul > li'
      assert.strictEqual siz.length, 4
    
    'DELETE DIV FROM (SELECT DIV FROM (SELECT DIV FROM BODY WHERE ID=\'parent-div\'))': (res) ->
      siz = Sizzle '#inner-child-div'
      assert.ok !siz.length
      assert.strictEqual res[0].getAttribute('id'), 'inner-child-div'
  
  CREATE:
    'CREATE ELEMENT A ( ID  \'fak\' )': (res) ->
      console.log res
  
  INSERT:
    """
    INSERT INTO (SELECT DIV FROM BODY WHERE ID=\'parent-div\') 
      VALUES (
        CREATE ELEMENT A (
          CLASS \'added\',
          html \'added\',
          onclick \'alert("x")\'
        ),
        CREATE ELEMENT A (
          html \'added-2\'
        )

      )""": ->
    
    """
      INSERT INTO (SELECT DIV FROM BODY WHERE ID=\'parent-div\')
        VALUES (
          SELECT UL FROM BODY,
          SELECT LI FROM (SELECT OL FROM BODY)
        )""": ->
  
  DROP: 'DROP ELEMENT DIV': ->
    
    
helper =
  start: (type) ->
    console.log '\nTesting %s', type
    @passed = Object.keys(tests[type]).length
  end: (type) ->
    console.log '\n--->%s testing passed %d/%d<---', type, @passed, Object.keys(tests[type]).length
    console.log ('*' for _ in [0...100]).join ''
  catcher: (e, query) ->
    @passed--
    if e instanceof AssertionError
      console.error 'Test Failed: %s with %s', query, e
    else
      console.log e.stack

run = (type) ->
  helper.start type
  for query, fn of tests[type]
    console.log ' '
    try
      fn DOMQL query
      console.log 'Test Passed: %s', query
    catch e
      helper.catcher e, query
  helper.end type
    
DOMQL.ready ->
  helper.start 'SELECT'
  for query, selector of tests.SELECT
    console.log ' '
    try
      if typeof selector is 'string'
        assert.collectionEqual DOMQL(query), Sizzle selector
        console.log 'Test Passed: %s', query, Sizzle selector
      else
        selector DOMQL query
        console.log 'Test Passed: %s', query
    catch e
      helper.catcher e, query
  helper.end 'SELECT'
  
  run 'UPDATE'
  run 'DELETE'
  run 'CREATE'
  run 'INSERT'
  run 'DROP'
  