class Relationship

  constructor: (@foreignName, @foreignKey, @foreignClassName, @myKey, @options) ->
    @foreignKey = MeteorOrm.Inflection.lowercaseFirstLetter(@foreignKey)
    @myKey = MeteorOrm.Inflection.lowercaseFirstLetter(@myKey)

  foreignClass: ->
    klass = MeteorOrm.models[@foreignClassName]
    throw new Error("Relationship cannot be found: #{@foreignClassName}") if !klass?
    klass


class BelongsToRelationship extends Relationship

  called: (myModel, foreignModel) ->
    => 
      myModel[@myKey] ||= foreignModel[@foreignKey] if foreignModel?
      whereCond = {}
      whereCond[@foreignKey] = myModel[@myKey]
      @foreignClass().where(whereCond).one()

class HasManyRelationship extends Relationship

  called: (myModel, foreignModels) ->
    =>
      whereCond = {}
      if @options.through
        association = myModel.getAssociationByName(@options.through)
        throw new Error('unable to find association: ' + @options.through) if !association?
        ids = association.called(myModel)().pluck(@foreignKey)
        whereCond[association.myKey] = { '$in': ids }
      else
        whereCond[@foreignKey] = myModel[@myKey]

      @foreignClass().where(whereCond)

MeteorOrm.Associations = {

  classMethods: {

    _setupAssociations: ->
      @_associations = {}

    belongsTo: (foreignName, options = {}) ->
      myKey = options.key || "#{foreignName}Id"
      foreignClass = options.className || MeteorOrm.Inflection.classify(foreignName)
      foreignKey = options.foreignKey || '_id'
      @_associations[foreignName] = new BelongsToRelationship(foreignName, foreignKey, foreignClass, myKey, options)
    
    hasMany: (foreignName, options = {}) ->
      myKey = options.key || "_id"
      foreignClassName = options.className || MeteorOrm.Inflection.classify(foreignName)
      if options.through
        foreignKey = options.foreignKey || "#{MeteorOrm.Inflection.singularize(foreignName)}Id"
      else
        foreignKey = options.foreignKey || "#{MeteorOrm.Inflection.singularize(@.name)}Id"
      @_associations[foreignName] = new HasManyRelationship(foreignName, foreignKey, foreignClassName, myKey, options)
  }

  instanceMethods: {

    # this is called for every object created. It does nothing unless
    # there is an association defined & an attr matched it. 
    _defineAssociations: (attrs = {}) ->
      return if _.isEmpty(@getAssociations())
      
      for name, association of @getAssociations()
        @[name] = association.called(@, attrs[name])

    getAssociations: ->
      @.constructor._associations

    getAssociationByName: (name) ->
      @.constructor._associations[name]

  }

}