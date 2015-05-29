class @User extends MeteorOrm.Model
  @collection 'users'
  @schema
    email: null
    password: null
    friends: []

  foo: -> 1

  @allow
    'insert': (userId, doc) ->
      true

    'remove': (userId, doc) ->
      true

    'update': ->
      true


class @Article extends MeteorOrm.Model
  @collection 'articles'
  @schema
    name: null
    cool: null
    extra:
      description: null
      testing: []

  @allow
    'insert': (userId, doc) -> true
    'remove': -> true
    'update': -> true

  @deny
    'insert': (userId, doc) ->
      a = new Article(doc)
      a.name == 'fail'

class @Val extends MeteorOrm.Model
  @collection 'vals'
  @schema
    email: null
    description: null
    alpha: null
    alphanumeric: null
    numericality: null
    inclusion: null
    exclusion: null
    length: 'a'
    length2: 'abc'
    length3: 'a'
    nested:
      msg: null

  @validates 'email', type: String, presence: true, email: true
  @validates 'alpha', type: { value: String, msg: 'woops' }, alpha: true
  @validates 'alphanumeric', alphanumeric: true
  @validates 'numericality', numericality: { greater_than_or_equal_to: 1, less_than: 10 }
  @validates 'inclusion', inclusion: { in: [null, 'a', 'b', 'c', 'd'] }
  @validates 'exclusion', exclusion: { in: ['a', 'b'] }
  @validates 'length', length: { max: 5, min: 1 }
  @validates 'length2', length: { equals: 3 }
  @validates 'length3', length: { within: [1, 4, 5] }
  @validates 'nested.msg', email: { value: true, msg: 'must be email' }
  @validates 'email', alphanumeric: true, on: 'destroy'

  @allow
    'insert': -> true
    'remove': -> true

class @ValUnique extends MeteorOrm.Model
  @collection 'valuniques'
  @schema
    email: null
    profile:
      second: 'a'

  @validates 'email', type: String, presence: true, uniqueness: { value: true, scope: 'profile.second' }

  @allow
    'insert': -> true
    'remove': -> true

User.deleteAll()
Article.deleteAll()

u1 = User.create(email: 'test@test.com', password: 'awesome', friends: [])
u2 = User.create(email: 'test2@test.com', password: 'awesome2', friends: ['Great'])

Tinytest.add 'collection is setup', (test) ->
  test.isNotNull User._collection

Tinytest.add 'schema setup', (test) ->
  test.isNotNull User._schema

Tinytest.add 'adds a user and returns user', (test) ->
  u = User.create(email: 'lol@test.com')
  test.equal u.id, User._collection.findOne(u.id)._id
  test.equal 1, u.foo()
  test.equal u.password, null

Tinytest.add 'attrs get saved to model', (test) ->
  u = User.new(email: 'm@m.com', password: 'nicely', testing: 1)
  test.equal u.email, 'm@m.com'
  test.equal u.password, 'nicely'
  test.equal u.testing, undefined
  test.equal u.friends, []

Tinytest.add 'returns proper for persisted', (test) ->
  u = User.new(email: 'lol@test.com')
  test.equal u.isPersisted(), false
  test.equal u.password, null

Tinytest.add 'one', (test) ->
  User.create(email: 'lol@test.com')
  u = User.where({ email: 'lol@test.com', password: null }).one()
  test.isNotNull u.id
  test.equal u.email, 'lol@test.com'
  test.equal u.password, null

Tinytest.add 'multiple wheres', (test) ->
  User.create(email: 'hah@hah.com', password: 'awesome!')
  u = User.where({ email: 'hah@hah.com' }).where({ password: 'awesome!' }).one()
  test.equal u.email, 'hah@hah.com'

Tinytest.add 'all', (test) ->
  u = User.where({ email: 'test@test.com' }).all()
  test.equal User._collection.find({ email: 'test@test.com' }).count(), u.length

Tinytest.add 'delete', (test) ->
  u = User.create(email: 'm@m.com', password: 'nicely', testing: 1)
  count = User.count()
  u.delete()
  test.equal count - 1, User.count()

Tinytest.add 'nested attrs get saved', (test) ->
  a = Article.create(name: 'Whoo', cool: 'Yay', extra: { description: 'great', lol: 'good', testing: ['Great'] })
  test.equal a.name, 'Whoo'
  test.equal a.cool, 'Yay'
  test.equal a.extra.description, 'great'
  test.equal a.extra.lol, undefined
  test.equal a.extra.testing, ['Great']

Tinytest.add 'failed to save', (test) ->
  a = Article.create(name: 'fail')
  test.isNotNull a.id
  test.equal a.isPersisted(), true
  setTimeout (=> 
    console.error('[failed to save] id is not emtpy') if a.id?
    console.error('[failed to save] not persisted') if a.isPersisted()
  ), 1000

Tinytest.add 'update', (test) ->
  a = Article.create(name: 'awesome')
  a.name = 'something else'
  a.save()
  test.equal a.name, 'something else'
  setTimeout (=> 
    console.error('[update] name not changed') if a.name != 'something else'
  ), 1000

Tinytest.add 'validate required', (test) ->
  r = Val.create()
  test.equal r.isPersisted(), false
  test.equal r.errors()['email'][0], 'is required'

Tinytest.add 'validate email', (test) ->
  r = Val.create(email: 'crap')
  test.equal r.isPersisted(), false
  test.equal r.errors()['email'][0], 'must be an email address'

Tinytest.add 'validate letters', (test) ->
  r = Val.create(email: 'test@test.com', alpha: '123')
  test.equal r.isPersisted(), false
  test.equal r.errors()['alpha'][0], 'must be letters only'

Tinytest.add 'validate letters numbers', (test) ->
  r = Val.create(email: 'test@test.com', alphanumeric: 'awe123$')
  test.equal r.isPersisted(), false
  test.equal r.errors()['alphanumeric'][0], 'must be letters & numbers only'

Tinytest.add 'validate number', (test) ->
  r = Val.create(email: 'test@test.com', numericality: '0')
  test.equal r.isPersisted(), false
  test.equal r.errors()['numericality'][0], 'must be a valid number'

  r = Val.create(email: 'test@test.com', numericality: '15')
  test.equal r.isPersisted(), false
  test.equal r.errors()['numericality'][0], 'must be a valid number'

  r = Val.create(email: 'test@test.com', numericality: '4')
  test.equal r.isPersisted(), true

  r = Val.create(email: 'test@test.com', numericality: 6)
  test.equal r.isPersisted(), true

Tinytest.add 'validate inclusion', (test) ->
  r = Val.create(email: 'test@test.com', inclusion: 'what')
  test.equal r.isPersisted(), false
  test.equal r.errors()['inclusion'][0], 'is not included in list'

  r = Val.create(email: 'test@test.com', inclusion: 'a', numericality: 5)
  test.equal r.isPersisted(), true

Tinytest.add 'validate exclusion', (test) ->
  r = Val.create(email: 'test@test.com', exclusion: 'a', numericality: 5)
  test.equal r.isPersisted(), false
  test.equal r.errors()['exclusion'][0], 'is in list'

  r = Val.create(email: 'test@test.com', exclusion: 'c', numericality: 5)
  test.equal r.isPersisted(), true

  r = Val.create(email: 'test@test.com', numericality: 5)
  test.equal r.isPersisted(), true

Tinytest.add 'validate length', (test) ->
  r = Val.create(email: 'test@test.com',  numericality: 5, length: '')
  test.equal r.isPersisted(), false
  test.equal r.errors()['length'][0], 'is not the proper length'

  r = Val.create(email: 'test@test.com',  numericality: 5, length: 'too big')
  test.equal r.isPersisted(), false
  test.equal r.errors()['length'][0], 'is not the proper length'

  r = Val.create(email: 'test@test.com',  numericality: 5, length: null)
  test.equal r.isPersisted(), false
  test.equal r.errors()['length'][0], 'is not the proper length'

  r = Val.create(email: 'test@test.com',  numericality: 5, length2: null)
  test.equal r.isPersisted(), false
  test.equal r.errors()['length2'][0], 'is not the proper length'

  r = Val.create(email: 'test@test.com',  numericality: 5, length2: 'ok')
  test.equal r.isPersisted(), false
  test.equal r.errors()['length2'][0], 'is not the proper length'

  r = Val.create(email: 'test@test.com',  numericality: 5, length2: 'tooo')
  test.equal r.isPersisted(), false
  test.equal r.errors()['length2'][0], 'is not the proper length'

  r = Val.create(email: 'test@test.com',  numericality: 5, length3: null)
  test.equal r.isPersisted(), false
  test.equal r.errors()['length3'][0], 'is not the proper length'

  r = Val.create(email: 'test@test.com',  numericality: 5, length3: 'apples')
  test.equal r.isPersisted(), false
  test.equal r.errors()['length3'][0], 'is not the proper length'

  r = Val.create(email: 'test@test.com',  numericality: 5, length3: 'nice')
  test.equal r.isPersisted(), true

Tinytest.add 'validate nested and custom message', (test) ->
  r = Val.create(email: 'test@test.com',  numericality: 5, nested: { msg: 'ok' })
  test.equal r.isPersisted(), false
  test.equal r.errors()['nested']['msg'][0], 'must be email'
  test.equal r.errorKeys(), ['nested.msg']

Tinytest.add 'validate type', (test) ->
  r = Val.create(email: 'test@test.com',  numericality: 5, alpha: 4)
  test.equal r.isPersisted(), false
  test.equal r.errors()['alpha'][0], 'woops'
  test.equal r.errors()['alpha'][1], 'must be letters only'

  r = Val.create(email: 'test@test.com',  numericality: 5, alpha: { c: 3 })
  test.equal r.isPersisted(), false

Tinytest.add 'validate uniqueness', (test) ->
  ValUnique.deleteAll()
  
  r = ValUnique.create(email: 'test@test.com')
  test.equal r.isPersisted(), true

  r = ValUnique.create(email: 'test@test.com')
  test.equal r.isPersisted(), false
  test.equal r.errors()['email'][0], 'is already taken'

  r = ValUnique.create(email: 'test@test.com', profile: { second: 'nice' })
  test.equal r.isPersisted(), true

  r = ValUnique.create(email: 'test@test.com', profile: { second: 'nice' })
  test.equal r.isPersisted(), false
  test.equal r.errors()['email'][0], 'is already taken'

Tinytest.add 'validate length on update', (test) ->
  r = Val.create(email: 'test@test.com',  numericality: 5)
  test.equal r.isPersisted(), true

  r.length = ''
  r.save()
  test.equal r.hasErrors(), true

Tinytest.add 'validate length on destroy', (test) ->
  r = Val.create(email: 'test@test.com',  numericality: 5)
  r.destroy()
  test.equal r.hasErrors(), true
  test.equal r.errors()['email'][0], 'must be letters & numbers only'
