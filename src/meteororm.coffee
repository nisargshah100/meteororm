class Model extends MeteorOrm.Module
  @include(MeteorOrm.Query.instanceMethods)
  @extend(MeteorOrm.Query.classMethods)
  @extend(MeteorOrm.Validation.classMethods)
  @include(MeteorOrm.Validation.instanceMethods)
  @extend(MeteorOrm.Hooks.classMethods)
  @include(MeteorOrm.Hooks.instanceMethods)

  # class methods

  @_attrsInSchema: (attrs) ->
    MeteorOrm.Deep.deepPick(attrs, @_schemaKeys)

  @_schemaKeys = ->
    MeteorOrm.Deep.deepKeys(@_schema)

  # public class

  @collection = (tbl) ->
    @_collection = new Meteor.Collection(tbl)

  @schema = (data) ->
    @_schema = _.extend({ _id: null }, data)
    @_schemaKeys = MeteorOrm.Deep.deepKeys(@_schema)
    @_setupHooks()
    @_setupValidations()

  @allow = (data) ->
    @_collection.allow(data) if Meteor.isServer

  @deny = (data) ->
    @_collection.deny(data) if Meteor.isServer

  @create = (data) ->
    @new(data).save()

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
    @_validate('create')

    return false if @hasErrors()

    oldState = MeteorOrm.Deep.deepClone(@_attrs)
    delete @_attrs._id
    id = @.constructor._collection.insert @_attrs, (err, status) =>
      if err
        console.log("(#{err.errorType}) #{err.message}")
        @._define(oldState)
      else
        @.reload(id)

  _update: (options = {}) ->
    @_setupValidation()
    @_validate('update')

    return false if @hasErrors()

    vals = @valuesAsHash()
    delete vals._id
    @.constructor._collection.update @id, { $set: vals }, (err) =>
      if err
        console.log("(#{err.errorType}) #{err.message}")
      else
        @.reload(@id)

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
    @_attrs = @._define(attrs)
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
  delete: ->
    @.constructor._collection.remove(@id)

  destroy: (options = {}) ->
    @_setupValidation()
    @_validate('destroy')
    return false if @hasErrors()
    @delete()
    true

MeteorOrm.Model = Model
