class Model extends MeteorOrm.Module
  @include(MeteorOrm.Query.instanceMethods)
  @extend(MeteorOrm.Query.classMethods)

  # class methods

  @_attrsInSchema: (attrs) ->
    vAttrs = {}
    for k, v of attrs
      if k in _.keys(@_schema.getFlatObject())
        vAttrs[k] = v
    vAttrs

  # public class

  @collection = (tbl) ->
    @_collection = new Meteor.Collection(tbl)

  @schema = (data) ->
    @_schema = new MeteorOrm.MongoObject(_.extend({ _id: null }, data))

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

  _define: (attrs) ->
    @['_id'] ||= null
    attrs = new MeteorOrm.MongoObject(
      MeteorOrm.MongoObject.deepen(@.constructor._attrsInSchema(new MeteorOrm.MongoObject(attrs).getFlatObject()) || {})
    )

    _.deepExtend(@, attrs.getObject())

    @['id'] = @['_id']
    attrs

  _create: ->
    @.constructor._collection.insert(@_attrs.getObject())

  # public instance

  constructor: (attrs = {}) ->
    @_attrs = @._define(attrs)

  save: ->
    if @id?
      id = @_update()
    else
      id = @_create()

    obj = @.constructor.where(id).one()
    @._define(obj._attrs._obj)
    @

  isPersisted: ->
    @id?

  delete: ->
    @.constructor._collection.remove(@id)

MeteorOrm.Model = Model
