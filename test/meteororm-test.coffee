class @User extends MeteorOrm.Model
  @collection 'users'
  @schema
    email: String
    password: String
    friends: [String]

  foo: -> 1


class @Article extends MeteorOrm.Model
  @collection 'articles'
  @schema
    name: String
    cool: String
    extra:
      description: String

User.deleteAll()
Article.deleteAll()

u1 = User.create(email: 'test@test.com', password: 'awesome', friends: [])
u2 = User.create(email: 'test2@test.com', password: 'awesome2', friends: ['Great'])

Tinytest.add 'collection is setup', (test) ->
  test.isNotNull User._collection

Tinytest.add 'schema setup', (test) ->
  test.isNotNull User._schema

Tinytest.add 'adds a user and returns user', (test) ->
  u = User.create(email: 'lol@test.com', password: 'great')
  test.equal u.id, User._collection.findOne(u.id)._id
  test.equal 1, u.foo()

Tinytest.add 'attrs get saved to model', (test) ->
  u = User.new(email: 'm@m.com', password: 'nicely', testing: 1)
  test.equal u.email, 'm@m.com'
  test.equal u.password, 'nicely'
  test.equal u.testing, undefined
  test.equal u.friends, undefined

Tinytest.add 'returns proper for persisted', (test) ->
  u = User.new(email: 'lol@test.com')
  test.equal u.isPersisted(), false

Tinytest.add 'one', (test) ->
  User.create(email: 'lol@test.com')
  u = User.where({ email: 'lol@test.com' }).one()
  test.isNotNull u.id
  test.equal u.email, 'lol@test.com'

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
  a = Article.create(name: 'Whoo', cool: 'Yay', extra: { description: 'great', lol: 'good' })
  test.equal a.name, 'Whoo'
  test.equal a.cool, 'Yay'
  test.equal a.extra.description, 'great'
  test.equal a.extra.lol, undefined
