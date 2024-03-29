MeteorOrm.Validation = {}

MeteorOrm.Validation.Rules = {

  Type: (options = {}) ->
    {
      message: ->
        options.msg || "is invalid type"

      validate: (value) ->
        return true unless value?
        type = options.value || options

        try
          check(value, type)
          true
        catch err
          false
    }

  Presence: (options = {}) ->
    {
      message: ->
        options.msg || "is required"

      validate: (value) ->
        !(value == undefined || value == null || value == '')
    }

  Format: (options = {}) ->
    {
      message: ->
        options.msg || "is invalid"

      validate: (value) ->
        value = null if value == undefined
        vString = JSON.stringify(value) if typeof(value) != 'string'

        return true if value == null || value == ''

        format = options.with
        format = options if ((typeof(options) == 'string') || (options instanceof RegExp)) && !format?
        throw new Error('format not specified for validator. specify using { format: /abc/ } or { format: { with: /abc/ }}') if !format?
    
        value = JSON.stringify(value) if typeof(value) != 'string'
        value.match(format)?
    }

  Email: (options = {}) ->
    {
      message: ->
        options.msg || 'must be an email address'

      validate: (value) ->
        format = MeteorOrm.Validation.rules.format(/^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,6}$/i)
        format.validate(value)
    }

  Alpha: (options = {}) ->
    {
      message: ->
        options.msg || 'must be letters only'

      validate: (value) ->
        format = MeteorOrm.Validation.rules.format(/^[a-z]+$/i)
        format.validate(value)
    }

  AlphaNumeric: (options = {}) ->
    {
      message: ->
        options.msg || 'must be letters & numbers only'

      validate: (value) ->
        format = MeteorOrm.Validation.rules.format(/^[a-z0-9]+$/i)
        format.validate(value)
    }

  Numericality: (options = {}) ->
    {
      message: ->
        options.msg || 'must be a valid number'

      validate: (value) ->
        value = null if value == undefined
        # return false if value == null

        regex = /^\-?[0-9]+$/
        regex = /^\-?[0-9]+\.?[0-9]+$/ if options.allow_float
        regex = /^[0-9]+$/ if options.unsigned
        regex = /^[0-9]+\.?[0-9]+$/ if options.allow_float && options.unsigned

        valid = MeteorOrm.Validation.rules.format(regex).validate(value)

        if valid
          value = parseFloat(value)

          # we can also do greater_than & less_than checks
          valid = value > options.greater_than && valid if options.greater_than
          valid = value >= options.greater_than_or_equal_to && valid if options.greater_than_or_equal_to
          valid = value < options.less_than && valid if options.less_than
          valid = value <= options.less_than_or_equal_to && valid if options.less_than_or_equal_to
          valid = value == options.equal_to && valid if options.equal_to
          valid = (Math.abs(value) % 2 == 0) && valid if options.even
          valid = (Math.abs(value) % 2 == 1) && valid if options.odd

        valid
    }

  Inclusion: (options = {}) ->
    {
      message: ->
        options.msg || 'is not included in list'

      validate: (value) ->
        inList = null
        inList = options.in || options.within if options instanceof Object
        inList = options if options instanceof Array
        throw new Error('inclusion validator: list not specified') if !inList?
        value in inList
    }

  Exclusion: (options = {}) ->
    {
      message: ->
        options.msg || 'is in list'

      validate: (value) ->
        !MeteorOrm.Validation.rules.inclusion(options).validate(value)
    }

  Length: (options = {}) ->
    {
      message: ->
        options.msg || 'is not the proper length'

      validate: (value) ->
        return false unless value?

        valid = true
        value = JSON.stringify(value) || '' if typeof(value) != 'string'

        valid = value.length <= options.max && valid if options.max?
        valid = value.length >= options.min && valid if options.min?
        valid = value.length == options.equals && valid if options.equals?
        valid = value.length in options.within && valid if options.within?

        valid
    }

  Uniqueness: (options = {}, @name, @model) ->
    {
      message: ->
        options.msg || 'is already taken'

      validate: (value, model) =>
        modelValue = null
        whereCond = {}
        whereCond[@name] = value

        if options.scope
          MeteorOrm.Deep.deepMapValues(model.valuesAsHash(), ((v, k) ->
            modelValue = v if k == options.scope
          ))
          whereCond[options.scope] = modelValue

        @model.where(whereCond).count() == 0
    }
}

MeteorOrm.Validation = {

  rules: {
    'presence': MeteorOrm.Validation.Rules.Presence,
    'format': MeteorOrm.Validation.Rules.Format,
    'email': MeteorOrm.Validation.Rules.Email,
    'alpha': MeteorOrm.Validation.Rules.Alpha,
    'alphanumeric': MeteorOrm.Validation.Rules.AlphaNumeric,
    'numericality': MeteorOrm.Validation.Rules.Numericality,
    'inclusion': MeteorOrm.Validation.Rules.Inclusion,
    'exclusion': MeteorOrm.Validation.Rules.Exclusion,
    'length': MeteorOrm.Validation.Rules.Length,
    'uniqueness': MeteorOrm.Validation.Rules.Uniqueness,
    'type': MeteorOrm.Validation.Rules.Type
  }

  classMethods: {
    validates: (name, options = {}) ->
      onMethod = options['on'] || ['create', 'update']
      onMethod = ['create', 'update'] if onMethod == 'save'
      delete options['on']
      onMethod = [onMethod] if typeof(onMethod) == 'string'

      @_validationRules[name] ||= []
      for vName, vOptions of options
        validator = MeteorOrm.Validation.rules[vName]
        if validator
          onMethod = [].concat(vOptions.on) if vOptions.on
          @_validationRules[name].push({ validator: validator(vOptions, name, @), on: onMethod })
        else
          throw new Error("unknown validator: #{vName}")

    _setupValidations: ->
      @_validationRules = {}
  }


  instanceMethods: {

    errors: ->
      MeteorOrm.Deep.deepFromFlat(@_errors || {})

    errorMessages: ->
      _.map @errors(), (v, k) -> "#{k} #{v}"

    errorKeys: ->
      keys = []
      keys.push(key) for key, v of @_errors
      keys

    hasErrors: ->
      @_errors? && @errorKeys().length > 0

    addError: (name, error) ->
      @_errors ||= {}
      @_errors[name] ||= []
      @_errors[name].push(error)

    _setupValidation: ->
      @_errors = {}

    _validate: (onMethod) ->
      rules = @.constructor._validationRules
      attrs = @valuesAsHash()

      for attr in @.constructor._schemaKeys
        val = MeteorOrm.Deep.value(attrs, attr)
        
        if rules[attr]
          for v in rules[attr]
            validator = v.validator
            methods = v.on
            if onMethod in methods
              result = validator.validate(val, @)
              if result == false
                @addError(attr, validator.message())
  }

}