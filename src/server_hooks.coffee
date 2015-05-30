MeteorOrm.ServerHooks = {

  classMethods: {

    _setupBeforeCreate: ->
      @_collection.before.insert (userId, doc) =>
        obj = @.new(doc)
        options = { userId: userId }

        obj._callAllHooks('beforeValidation', options)
        obj._validate('create')
        obj._callAllHooks('afterValidation', options)
        obj._callAllHooks('beforeSave', options)
        obj._callAllHooks('beforeCreate', options)
        throw new Meteor.Error(JSON.stringify(obj.errors())) if obj.hasErrors()
        _.deepExtend(doc, obj.valuesAsHash())

    _setupAfterCreate: ->
      @_collection.after.insert (userId, doc) =>
        obj = @.new(doc)
        options = { userId: userId }

        obj._callAllHooks('afterCreate', options)
        obj._callAllHooks('afterSave', options)

    _setupBeforeUpdate: ->
      @_collection.before.update (userId, doc, fieldNames, modifier, options) =>
        obj = @.new(modifier.$set)
        options = { userId: userId, fieldNames: fieldNames, modifier: modifier, options: options }

        obj._callAllHooks('beforeValidation', options)
        obj._validate('update')
        obj._callAllHooks('afterValidation', options)
        obj._callAllHooks('beforeSave', options)
        obj._callAllHooks('beforeUpdate', options)
        throw new Meteor.Error(JSON.stringify(obj.errors())) if obj.hasErrors()

        val = obj.valuesAsHash()
        delete val._id
        _.extend(modifier, { $set: val })

    _setupAfterUpdate: ->
      @_collection.after.update (userId, doc, fieldNames, modifier, options) =>
        obj = @.new(doc)
        options = { userId: userId, fieldNames: fieldNames, modifier: modifier, options: options }

        obj._callAllHooks('afterUpdate', options)
        obj._callAllHooks('afterSave', options)

    _setupServerHooks: ->
      if Meteor.isServer
        @_setupBeforeCreate()
        @_setupAfterCreate()
        @_setupBeforeUpdate()
        @_setupAfterUpdate()

  }

  instanceMethods: {

  }
}