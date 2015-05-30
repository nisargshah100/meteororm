class @Person extends MeteorOrm.Model
  @collection 'persons', timestamps: true

  @schema
    email: null
    password: null

  @hasMany 'memberships'
  @hasMany 'homes', through: 'memberships'

  @allow
    'insert': -> true
    'remove': -> true

class @Membership extends MeteorOrm.Model
  @collection 'memberships', timestamps: true

  @schema
    personId: null
    homeId: null

  @belongsTo 'person'
  @belongsTo 'home'

  @allow
    'insert': -> true
    'remove': -> true

class @Home extends MeteorOrm.Model
  @collection 'homes', timestamps: true

  @schema
    title: null

  @hasMany 'memberships'
  @hasMany 'persons', through: 'memberships'

  @allow
    'insert': -> true
    'remove': -> true

Person.deleteAll()
Home.deleteAll()
Membership.deleteAll()

u1 = Person.create({ email: '1@1.com', password: 'one' })
u2 = Person.create({ email: '1@2.com', password: 'one' })
u3 = Person.create({ email: '1@3.com', password: 'one' })
u4 = Person.create({ email: '1@4.com', password: 'one' })

a1 = Home.create({ title: 'one' })
a2 = Home.create({ title: 'two' })

m1 = u1.memberships().create({ homeId: a1.id })
m2 = u2.memberships().create({ homeId: a1.id })
m3 = u3.memberships().create({ homeId: a2.id })
m4 = u3.memberships().create({ homeId: a1.id })
m5 = u4.memberships().create({ homeId: a2.id })

Tinytest.addAsync 'find memberships from user', (test, next) ->
  Meteor.setTimeout (->
    test.equal u1.memberships().count(), 1
    test.equal u1.memberships().sort({ createdAt: 1 }).pluck('_id'), [m1.id]
    test.equal u2.memberships().count(), 1
    test.equal u2.memberships().sort({ createdAt: 1 }).pluck('_id'), [m2.id]
    test.equal u3.memberships().sort({ createdAt: 1 }).pluck('_id'), [m3.id, m4.id]
    test.equal u4.memberships().sort({ createdAt: 1 }).pluck('_id'), [m5.id]

    next()
  ), 1000

Tinytest.addAsync 'find homes from user', (test, next) ->
  Meteor.setTimeout (->
    test.equal u1.homes().count(), 1
    test.equal u1.homes().sort({ createdAt: 1 }).pluck('_id'), [a1.id]
    test.equal u2.homes().count(), 1
    test.equal u2.homes().sort({ createdAt: 1 }).pluck('_id'), [a1.id]
    test.equal u3.homes().sort({ createdAt: 1 }).pluck('_id'), [a1.id, a2.id]
    test.equal u4.homes().sort({ createdAt: 1 }).pluck('_id'), [a2.id]

    next()
  ), 1

Tinytest.addAsync 'find user from memberships', (test, next) ->
  Meteor.setTimeout (->
    test.equal m1.person().id, u1.id
    test.equal m2.person().id, u2.id
    test.equal m3.person().id, u3.id
    test.equal m4.person().id, u3.id
    test.equal m5.person().id, u4.id

    next()
  ), 1

Tinytest.addAsync 'find home from memberships', (test, next) ->
  Meteor.setTimeout (->
    test.equal m1.home().id, a1.id
    test.equal m2.home().id, a1.id
    test.equal m3.home().id, a2.id
    test.equal m4.home().id, a1.id
    test.equal m5.home().id, a2.id

    next()
  ), 1

Tinytest.addAsync 'find users from homes', (test, next) ->
  Meteor.setTimeout (->
    test.equal a1.persons().sort({ createdAt: 1 }).pluck('_id'), [u1.id, u2.id, u3.id]
    test.equal a2.persons().sort({ createdAt: 1 }).pluck('_id'), [u3.id, u4.id]

    next()
  ), 1
