class Model extends MeteorOrm.Module
  @include(MeteorOrm.Query.instanceMethods)
  @extend(MeteorOrm.Query.classMethods)
  @extend(MeteorOrm.Validation.classMethods)
  @include(MeteorOrm.Validation.instanceMethods)
  @extend(MeteorOrm.Hooks.classMethods)
  @include(MeteorOrm.Hooks.instanceMethods)
  @extend(MeteorOrm.ServerHooks.classMethods)
  @include(MeteorOrm.ServerHooks.instanceMethods)

  @createdAtKey = 'createdAt'
  @updatedAtKey = 'updatedAt'

  # class methods

  @_attrsInSchema: (attrs) ->
    MeteorOrm.Deep.deepPick(attrs, @_schemaKeys)

  @_schemaKeys = ->
    MeteorOrm.Deep.deepKeys(@_schema)

  @_setupTimestampSchema = (data) ->
    data[@createdAtKey] = null if not data[@createdAtKey]
    data[@updatedAtKey] = null if not data[@updatedAtKey]
    @validates @createdAtKey, type: Date
    @validates @updatedAtKey, type: Date
    data

  @_setupTimestamps = ->
    if Meteor.isServer
      @beforeCreate ->
        @[@.constructor.createdAtKey] = new Date()

      @beforeUpdate -> 
        @[@.constructor.updatedAtKey] = new Date()

  # public class

  @collection = (tbl, @collection_options = {}) ->
    @_collection = new Meteor.Collection(tbl)

  @schema = (data) ->
    @_setupHooks()
    @_setupValidations()
    data = @_setupTimestampSchema(data) if @collection_options.timestamps
    @_schema = _.extend({ _id: null }, data)
    @_schemaKeys = MeteorOrm.Deep.deepKeys(@_schema)
    @_setupTimestamps() if @collection_options.timestamps
    @._setupServerHooks()

  @allow = (data) ->
    @_collection.allow(data) if Meteor.isServer

  @deny = (data) ->
    @_collection.deny(data) if Meteor.isServer

  @create = (data, options = {}) ->
    @new(data).save(options)

  @wrap = (objects) ->
    records = []
    objects = [].concat(objects)
    records.push(@.new(obj)) for obj in objects
    if records.length == 1 then records[0] else records

  @new: (data) ->
    new @(data)

  # instance

  _define: (attrs = {}) ->
    @['_id'] ||= null
    attrs = @.constructor._attrsInSchema(attrs)
    result = MeteorOrm.Deep.deepDefaults(attrs, @.constructor._schema)
    _.deepExtend(@, result)
    @['id'] = @['_id']
    result

  # This tries to keep the proper object state. First we save and reload right away
  # then after response from server, if its error, reset the safe to what it was before. 
  # otherwise reload since server might have added some stuff to it
  _create: (options = {}) ->
    @_setupValidation()
    @_callAllHooks('beforeValidation', options)
    @_validate('create')
    @_callAllHooks('afterValidation', options)

    return false if @hasErrors()

    @_callAllHooks('beforeSave', options)
    @_callAllHooks('beforeCreate', options)

    attrs = @valuesAsHash()
    delete attrs._id
    oldState = MeteorOrm.Deep.deepClone(attrs)

    id = @.constructor._collection.insert attrs, (err, status) =>
      if err
        console.error('create', err)
        @._define(oldState)
        options.onError?(err)
      else
        @.reload(id)
        @_callAllHooks('afterCreate', options)
        @_callAllHooks('afterSave', options)
        options.onSuccess?()

  _update: (options = {}) ->
    @_setupValidation()
    @_callAllHooks('beforeValidation', options)
    @_validate('update')
    @_callAllHooks('afterValidation', options)

    return false if @hasErrors()

    @_callAllHooks('beforeSave', options)
    @_callAllHooks('beforeUpdate', options)

    vals = @valuesAsHash()
    delete vals._id

    @.constructor._collection.update @id, { $set: vals }, (err) =>
      if err
        console.error('update', err)
        options.onError?(err)
      else
        @.reload(@id)
        @_callAllHooks('afterUpdate', options)
        @_callAllHooks('afterSave', options)
        options.onSuccess?()

  # public instance

  valuesAsHash: ->
    MeteorOrm.Deep.deepPick(@, @.constructor._schemaKeys)

  flatValuesAsHash: ->
    MeteorOrm.Deep.deepToFlat(@valuesAsHash())

  reload: (id = @id) ->
    throw new Meteor.Error('id is null') unless id?
    @._define(@.constructor._collection.findOne(id))
    @

  constructor: (attrs = {}) ->
    @._define(attrs)
    @_callAllHooks('afterInitialize')
    @

  save: (options = {}) ->
    if @id?
      @_update(options)
      id = @id
    else
      id = @_create(options)

    if typeof(id) == 'string'
      @.reload(id)  # we do this b/c its async - this updates the state right away - then if it fails on server, we can reset the state
    
    @

  isPersisted: ->
    @id?

  # no validation or hooks - just a delete. 
  delete: (cb) ->
    @.constructor._collection.remove @id, (err) ->
      if err
        console.error('delete', err)
      else
        cb?()

  destroy: (options = {}) ->
    @_setupValidation()
    @_callAllHooks('beforeValidation', options)
    @_validate('destroy')
    @_callAllHooks('afterValidation', options)
    return false if @hasErrors()

    @_callAllHooks('beforeDestroy', options)
    @delete =>
      @_callAllHooks('afterDestroy', options)
    true

MeteorOrm.Model = Model
