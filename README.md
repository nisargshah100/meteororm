# Use with caution - there may be bugs still!

# MeteorOrm

A Javascript implementation similar to active record for MeteorJS

##### Written in Coffeescript & all examples in coffeescript

### Namespace

MeteorOrm is encompassed in MeteorOrm global.

-------------


#### Define a model & setup its schema

```
class @User extends MeteorOrm.Model
  @collection 'users' # Meteor.Collection name
  @schema
    email: null               # default value
    password: null
   
  @allow
    'insert': -> true        # only runs on server.
    'remove': -> true
    'update': -> true
```

Thats it. You are ready to use this model. Allow block only runs on server - it is basically Collection.allow from meteor. [Meteor - Collection#allow](http://docs.meteor.com/#/full/allow)

#### Access & set attributes once model is created

```
  user = new User(email: 'a@a.com')
  user.email                            # accessor
  user.email = 'b@b.com'                # setter
```

#### Saving & Updating Model

```
user = new User(email: 'email@email.com')
user.save()
user.password = 'foobar'
user.save()
```

Saves the record locally which automatically gets saved to server.

#### Destroy Model


```
user = User.create(email: 'a@a.com')
user.destroy()

# without callbacks
user.destroy({ runHooks: false })
```

#### reload model from local db

```
user.reload()
```

#### update attributes is also available

```
user.updateAttributes({ email: 'c@c.com', password: 'boo' })
```

#### get hash from model

```
user.valuesAsHash()
```

#### Timestamps

If you want to model to be timestamped in javascript whenever created / updated, you can use:

```
class User
  @collection 'users', timestamps: true
```

This will add created_at & updated_at to your schema and add callbacks that update those values on create / update.

#### Delete Vs Destroy

```
user.delete()
user.destroy()

User.deleteAll()         # removes all users
User.destroyAll()
```

Delete doesn't run any validation or hooks. Destroy will run them. 

### Hooks

Hooks allow you run custom code at certain points in model execution. The following hooks are available:

* beforeSave (create / update)
* afterSave (create / update)
* beforeCreate
* afterCreate
* beforeUpdate
* afterUpdate
* afterInitialize
* beforeValidation
* afterValidation
* beforeDestroy
* afterDestroy

```
class User extends MeteorOrm.Model
  @collection 'users'
  @schema
    email: null
    password: null
    token: null
  
  @generateToken: ->
    @token = 'something random'
  
  @beforeCreate 'generateToken'
  
  # You can also specify function with the hooks
  @afterCreate ->
    console.log('user is done!')
```

###### Infinite loop with hooks

There is a chance to get into an infinite loop with hooks. Lets take the above example. After the model is created, we call update attributes to save token. This update attributes does an update and so will call beforeSave, beforeUpdate, afterUpdate, afterSave hooks. In those hook, if you were to save / update again, you would have an infinite loop. 

OR 

This would be an infinite loop:

```
  @generateToken: ->
    @updateAttributes({ token: 'blah' })

  @afterSave 'generateToken'
```

This is because after we save, we call generate token which calls beforeSave, beforeUpdate, afterUpdate, afterSave hooks. This would result in afterSave getting called over and over. 

So how you get past this? You can update / save by disabling hooks

```
  @afterSave ->
    @updateAttributes({ blah: 1 }, { runHooks: false })
```

### Validation

There are bunch of validations supported and you can easily define custom validations as needed. **Validations run both on server and client. There you just need to specify them in one place.**

Example:

```
class User
  @collection 'users'
  @schema
    email: null
    name: null
    age: 0
  
  @validates 'email', presence: true, email: true, uniqueness: { value: true, on: 'create' }
  @validates 'name', length: { min: 4, max: 30, msg: 'name must be between 4 to 30 characters long' }
  @validates 'age', :numericality => { :greater_than_or_equal_to => 1, :less_than => 150 }
  
### saving a user that fails validation

user = User.create({ email: 'test' })
user.isPersisted() # false
user.hasErrors() # true
user.errors() # set of errors { email: [ERRORS], name: [ERRORS] }

```

###validation 'on'

Sometimes you just want to run validations on 'create' or 'update'. You can do:

```
@validates 'email', presence: true, email: true, on: 'create'
```

Both presence and email validation are run on `create`.

```
@validates 'email', presence: true, email: { value: true, on: 'create' }
```

In this example - presence is run on `create` and `update`. Email is only run on `create`


#### Supported Validations

* type
* uniqueness
  * scope
* format
  * with: /regex/
* email
* alpha
* alphanumeric
* numericality
  * allow_float
  * unsigned (only positive numbers)
  * greater_than
  * less_than
  * greater_than_or_equal_to
  * less_than_or_equal_to
  * equal_to
  * odd
  * even
* inclusion
  * in / within (same just aliases)
* exclusion
  * in / within
* length
  * max
  * min
  * equals
  * within (ex/ within: [4..10])
  
##### Type Validation

You should always use type validation on your schema. This restricts what types of data can be stored.

```
@validates 'email', type: String
```

Or

```
@validates 'emails', type: [String]
```

Type just runs meteor's `check` method. [Meteor #check](http://docs.meteor.com/#/full/check_package)
 
###### Validation Error Message

You can provide a custom error message for each validation using `msg`. Example/ 

```
@validates 'email', presence: { msg: 'its required' }, email: { msg: 'invalid email' }, format: { with: /@/, msg: 'has to have @ symbol' }
```

##### Specify multiple valdiations of same field


Also, You can validate 'email' multiple times. 

```
@validates 'email', presence: true, uniqueness: true, on: 'create'
@validates 'email', presence: true, on: 'update'
```

### Custom Validations

You can provide your own validations via hooks. Example validation before creating:

```

class User extends MeteorOrm.Model
  @setup 'users'
  @schema
  	email: null
  	token: null
  
  @validateToken: ->
    if @token == '123'
      @addError('token', 'cant be 123')
  
  # has to be below the method declaration since JS can't find it otherwise
  @beforeCreate 'validateToken'


```

You can add validations to beforeCreate, beforeUpdate, beforeSave or beforeDestroy

## Observer

In publishes, you need to return an observer for Meteor to auto update. That can be 
done via:

```
User.observer()
```

or 

```
User.where({ email: 'foo' }).limit(20).observer()
```

## Quering

ARJS supports many ways to fetch data from database. 

The following methods are supported:

* all
* where
* first
* limit
* sort
* pluck
* count
* offset

Find a single user

```
User.where({ email: 'a@a.com' }).one() # returns null / user
```


Fetch all records:

```
User.all()
```

Fetch all records where email is `foo`

```
User.where({ email: 'foo' }).all()
```

Get first record where email is like `foo`

```
User.where({ email: /foo/ }).first()
```

Limit email like `foo` to 10 records


```
User.where({ email: /foo/ }).limit(10).all()
```

Pluck emails from all users

```
User.pluck('email') # returns array - ex/ [email1, email2, email3]
```

Count 

```
User.count()
User.where({ email: 'foo' }).count()
```

### Where

In queries - where is extremely powerful. Essentially you can perform any query with where. 

In meteor - you would run query like:

```
users = User.findOne({}, {})
```
In MeteorOrm, you can run:

```
users = User.where({}, {}).one()
```

Also, where returns a query object and doesn't perform a query. You can tag multiple where together:

```
users = User.where({ email: 'a' }).where({ password: 'b' }).all()
```

Until `all` is called, no query is performed. 

## Associations

We support many different kinds of associations. These incude:

* belongsTo
   * key
   * foreignKey
   * className
* hasMany
   * key
   * className
   * foreignKey
   * through

### Belongs To

If the current object belongs to another one and has an id for the other object, use this. Example/ book belongs to author. 

```
class Book
  @collection 'books'
  @belongsTo 'author'
  
  @schema
  	name: null
  	userId: null
```

Thats it. We assume a lot of stuff but everything is customizable. This relationship can be used like:

```
Book.first().author()
```

The code above assumes you have a `author_id` key in the schema. You can change that using `key`

```
@belongsTo 'author', key: 'person_id'
```

It also assumes that we should look at author's `id`. That can be customized using:

```
@belongsTo 'author', key: 'person_id', foreignKey: '_id', className: 'User'
```

### Has Many

Opposite of belongs to relationship. The id attribute is on the foreign table. Example/

```
class Author
  @collection 'authors'
  @hasMany 'books'
  
  @schema (t) ->
    my_id: null
    name: null
```

This can be accessed via:

```
Author.first().books()
```

We dont run a query to database when you use the above statement. It just returns a query builder so you can add more conditions to it. 

```
Author.first().books().where({ name: 'foo' }).sort({ createdAt: 1 }).all()
```

Again, just using `@hasMany 'books'` assumes a lot of stuff. That is customizable through `key`, `foreignKey`, and `className`

```
@hasMany 'books', key: 'my_id', foreignKey: 'user_id', className: 'Book'
```

#### Through Association

Through allows you to setup a many to many relationship. It goes through another model to the target model. 

Example:

```
class User extends MeteorOrm.Model
  @collection 'users'
  @hasMany 'user_accounts'
  @hasMany 'accounts', through: 'user_accounts'
  @schema
  	email: null

class UserAccount extends MeteorOrm.Model
  @collection 'user_accounts'
  @belongsTo 'user'
  @belongsTo 'account'
  @schema
  	userId: null
  	accountId: null

class Account extends MeteorOrm.Model
  @collection 'accounts'
  @schema
  	name: null

```

Using this, you can query records like:

```
User.first().accounts().all()       # fetch all records
User.first().accounts().where({ name: 'apples' }).all()    # fetch all my accounts with the name apples
```