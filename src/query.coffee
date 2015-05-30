class Query

  constructor: (@model, @finder = {}, @modifiers = {}) ->
    @collection = @model._collection

  where: (attrs, modifiers = {}) ->
    _.deepExtend(@finder, attrs)
    _.deepExtend(@modifiers, modifiers)
    @

  sort: (attrs) ->
    attrs = { sort: attrs }
    _.deepExtend(@modifiers, attrs)
    @

  limit: (n) ->
    attrs = { limit: n }
    _.deepExtend(@modifiers, attrs)
    @

  first: -> @one()

  one: ->
    @model.wrap(@collection.findOne(@finder, @modifiers))

  all: ->
    [].concat(@model.wrap(@collection.find(@finder, @modifiers).fetch()))

  count: ->
    @collection.find(@finder, @modifiers).count()

  delete: ->
    obj.delete() for obj in @all()

  destroy: ->
    obj.destroy() for obj in @all()

  build: (attrs = {}) ->
    _.deepExtend(attrs, @finder)
    new @model(attrs)

  create: (attrs = {}) ->
    @build(attrs).save()

  select: (attrs = []) ->
    attrs = [].concat(attrs)
    k = {}
    _.each attrs, (x) -> k[x] = 1
    _.deepExtend(@modifiers, { fields: k })
    @

  pluck: (attr = '_id') ->
    f = {}
    f[attr] = 1

    @select(attr)
    _.map @collection.find(@finder, @modifiers).fetch(), (x) -> x[attr]

MeteorOrm.Query = {

  classMethods: {

    first: ->
      @one()

    sort: (attrs) ->
      new Query(@).sort(attrs)

    where: (attrs, modifiers = {}) ->
      new Query(@).where(attrs, modifiers)

    one: ->
      new Query(@).one()

    all: ->
      new Query(@).all()

    limit: (n) ->
      new Query(@).limit(n)

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