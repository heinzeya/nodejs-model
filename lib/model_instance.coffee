Q = require 'q'
s = require 'stampit'
_ = require 'underscore'
_s = require 'underscore.string'

model_instance = s().enclose(() ->
    model = @model
    delete @model

    @validate = (filter) ->
        canValidate = (options, validator) =>
            #if options is an object then seek the 'if' fn as the object's property
            if typeof (options) is "object"
                if options["if"]
                    #options[if] is a function, execute it.
                    if typeof (options.if) is "function"
                        options.if @, validator
                    #options[if] is a string
                    else if typeof (options.if) is "string"
                        #is the current model instance has a direct method that corresponds to the options[if] value?
                        if typeof (@[options.if]) is "function"
                            @[options.if]()
                        #otherwise try as a property
                        else if typeof @[options]["if"]() is "function"
                            @[options].if()
                        #We cant find how to handle the if criteria, then for safety validator should be executed
                        else
                            true
                #Same logic but '!' should be for unless as 'if' above
                else if options.unless
                    if typeof (options.unless) is "function"
                        not options.unless @, validator
                    else if typeof (options.unless) is "string"
                        if typeof (@[options.unless]) is "function"
                            not @[options.unless]()
                        else if typeof @[options]["unless"]() is "function"
                            not @[options].unless()
                #there is no if/unless properties in the validator options hash then validator should be executed
                else
                    true
            #in case options is not an object the validator should be executed
            else
                true

        Validators = model.validators()

        @errors = {}
        oper = Q.defer()
        deffers = []

        if filter
            vProps = [filter];
        else
            attrsDefs = model.attrsDefs()

            for prop of attrsDefs
                validators = attrsDefs[prop].validations
                if validators?
                    for validator of validators
                            validator_options = validators[validator]
                            if canValidate validator_options, validators[validator]
                                if Validators[validator]? and typeof Validators[validator] is 'function'
                                    accessor = _s.camelize prop
                                    deffers = deffers.concat Validators[validator](@, accessor, validator_options)

            Q.allSettled(deffers).then((result) =>
                @isValid = Object.keys(@errors).length is 0
                oper.resolve()
            )
        oper.promise

    @getType = () ->
        model.getType()

    @addError = (attr, message) ->
        @errors[attr] = (@errors[attr] || []).concat(message)

    @update = (object, accessibility) ->
        if ! accessibility?
            accessibility = ['public']
        else if accessibility.constructor isnt Array
            accessibility = [accessibility]

        attrsDefs = model.attrsDefs()
        for p of object
            if _.contains(accessibility, '*') or _.intersection(attrsDefs[p].accessibility, accessibility).length > 0
                @attrs[p] = object[p]

        @


    @toJSON = (accessibility) ->
        if ! accessibility?
            accessibility = ['public']
        else if accessibility.constructor isnt Array
            accessibility = [accessibility]

        attrsToReturn = {}
        attrsDefs = model.attrsDefs()

        for attr of @attrs
            if _.contains(accessibility, '*') or _.intersection(attrsDefs[attr].accessibility, accessibility).length > 0
                attrsToReturn[attr] = @attrs[attr]

        attrsToReturn
    @
)

module.exports = model_instance