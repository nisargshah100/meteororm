

class Query

  constructor: (@model, @finder = {}, @modifier = {}) ->
    @collection = @model._collection

  where: (attrs) ->
    @finder = _.deepExtend(@finder, attrs)
    @

  one: ->
    @model.wrap(@collection.findOne(@finder, @modifier))

  all: ->
    [].concat(@model.wrap(@collection.find(@finder, @modifier).fetch()))

  count: ->
    @collection.find(@finder, @modifier).count()

  delete: ->
    obj.delete() for obj in @all()

  destroy: ->
    obj.destroy() for obj in @all()

MeteorOrm.Query = {

  classMethods: {

    first: (attrs = {}) ->
      new Query(@).where(attrs).one()

    where: (attrs) ->
      new Query(@).where(attrs)

    one: ->
      new Query(@).one()

    all: ->
      new Query(@).all()

    count: ->
      new Query(@).count()

    deleteAll: ->
      new Query(@).where().delete()

    destroyAll: ->
      new Query(@).where().destroy()

  }

  instanceMethods: {

  }

}