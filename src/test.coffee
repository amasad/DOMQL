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
###
#DQL:
Lately we've learnt that web development is a basic human right. And it should be accessable to every developer in the industry. CoffeeScript did its part by bringing web development closer to rubyists and pythonistas, dart to java devs, clojurescript to lispers ...etc. But what about DBAs aren't they equally human? Should they be doomed to suffer learning all about JS, DOM and/or jQuery?
DQL is here to make web development fimiliar to DBAs looking for a change in career (or suffering a brain-damage). With a goal of making them Feel Right At Home (TM).
DQL is not a fully-fleged programming language but a small DSL inspired by SQL aimed at easing DOM manipulation for DBAs.

Quick examples to make you feel warm and fuzzy (Right At Home (TM)):
  SELECT DIV FROM BODY WHERE ID='container'
  UPDATE (SELECT H1 FROM (SELECT DIV FROM BODY).ALL) SET CLASS='active' WHERE CLASS='disabled'
  DELETE A FROM BODY.ALL WHERE HREF LIKE "google.com" AND ROWNUM BETWEEN 5 AND 10

# Right At Home (TM):
## Speed:
Just as in transactional DBMS you can write queries that are insanely slow.

## DQL INJECTION:
I tried my best to bring the stuff you mostly adore from SQL and I thought that Injections is a must have to make you Feel Right At Home (tm).
Features added/removed to make injections possible:
 1- Insert `--` anywhere in the code to comment out the rest of the query.
 2- Stacking queries. You can terminate any query with `;` and start a new one.
 3- Nothing is sanitized.

SELECT * FROM BODY WHERE CLASS='%s' AND ROWNUM > 2, [';DROP BODY;-- pwned! \o/ ] 


TODO:
  Submit a W3C proposal to make DQL native in all browsers.

###
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
  
DQL.ready ->
  helper.start 'SELECT'
  for query, selector of tests.SELECT
    console.log ' '
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
  
  
  helper.start 'UPDATE'
  for query, fn of tests.UPDATE
    console.log ' '
    try
      fn DQL query
      console.log 'Test Passed: %s', query
    catch e
      helper.catcher e, query
  helper.end 'UPDATE'
  
  helper.start 'DELETE'
  for query, fn of tests.DELETE
    console.log ' '
    try
      fn DQL query
      console.log 'Test Passed: %s', query
    catch e
      helper.catcher e,query
  helper.end 'DELETE'
        