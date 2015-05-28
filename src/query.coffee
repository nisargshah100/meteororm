

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

MeteorOrm.Query = {

  classMethods: {

    where: (attrs) ->
      new Query(@, attrs).where(attrs)

    one: ->
      new Query(@).one()

    all: ->
      new Query(@).all()

    count: ->
      new Query(@).count()

    deleteAll: ->
      new Query(@).where().delete()

  }

  instanceMethods: {

  }

}