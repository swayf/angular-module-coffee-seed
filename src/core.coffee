'use strict'

angular.module('swayf.keeper', [])
.provider 'ArtModel', () ->

    # mixin API here
    extend = (baseObject, mixinClass, options, schema) ->
        for key, value of mixinClass::
            baseObject[key] = value

        mixinClass.call baseObject, options, schema
        baseObject


    include = (baseClass, mixinClass) ->
        for key, value of mixinClass::
            #save old function
            old = if (key of baseClass::) then baseClass::[key] else null
            baseClass::[key] = value
            baseClass::[key].super = old

        baseClass::_mixins ?= []
        baseClass::_mixins.push mixinClass

        baseClass



    $get: (Document, $injector) ->

        class Model

            @idPrefix = '$$'
            @primaryKey = 'id'
            @uid = ['0', '0', '0']
            @registry =
                String: {}
                Number: {}
                Boolean: {}
                Array:   {}

            @register: (schema) ->
                if schema.name of @registry
                    throw new Error "Schema '#{schema.name}' is already registered"
                else
                    model = new Model(schema)

                    if schema.typeConstructor?
                        model.Document = schema.typeConstructor

                    else if schema.mixins?
                        class DocumentMixed extends Document
                            constructor: (id, options) ->
                                result = super model, id, options
                                for fn in @_mixins
                                    fn.call (result || this), id, options

                                return result

                        for mixinName, options of schema.mixins
                            Mixin = $injector.get mixinName
                            extend model, Mixin.Model, options, schema if Mixin.Model?
                            include DocumentMixed, Mixin.Document if Mixin.Document?

                        model.Document = DocumentMixed

                    else
                        model.Document = _.partial Document, model

                    # add statics to the model
                    if schema.statics?
                        for name, value of schema.statics
                            if angular.isFunction value
                                # bind to model and save original if needed
                                if name of model
                                    old = model[name]
                                model[name] = _.bind value, model
                                model[name].super = old if old?
                            else
                                model[name] = value

                    model.initialize?()

                    return @registry[schema.name] = model


            constructor: (schema) ->
                # if schema object register new schema
                # if it is string.. get from model registry
                if angular.isObject schema
                    if schema.name of Model.registry
                        return Model.registry[schema.name]
                    else
                        @schema = schema
                        @docs = {}
                        return
                return Model.registry[schema]


            create: (value, options) ->
                if @schema.typeConstructor?
                    if value?
                        return new @Document value...
                    else
                        return new @Document()
                else
                    doc = new @Document(null, options)
                    doc.$initialize value
                    return doc


            getDocuments: () ->
                return _.values @docs


            ###*
            * A consistent way of creating unique IDs in angular. It will be exposed first in 2.0
            *
            * @returns an unique alpha-numeric string
            ###
            @nextUid: () ->
                index = Model.uid.length
                digit = undefined
                while index
                    index--
                    digit = Model.uid[index].charCodeAt(0)
                    if digit is 57 #'9'
                        Model.uid[index] = "A"
                        return Model.uid.join("")
                    if digit is 90 #'Z'
                        Model.uid[index] = "0"
                    else
                        Model.uid[index] = String.fromCharCode(digit + 1)
                        return Model.uid.join("")
                Model.uid.unshift "0"
                return Model.idPrefix + Model.uid.join ""

        return Model


.provider 'ArtDocument', () ->

    # Private variables

    # Private constructor
    class Document
        constructor: (@$model, id, options) ->
            @$options = options ? {}
            @$children = {}

            if id?
                @$id = id
                if @$id in @$model.docs
                    return  @$model.docs[@$id]
            else
                if not @$options.withoutId
                    @$id = @$model.constructor.nextUid()
                    @$model.docs[@$id] = this


        $initialize: (values) ->
            Model = @$model.constructor
            for name, field of @$model.schema.fields
                value = values?[name] ? field.default

                item = if field.type != 'Array' then field else field.item

                createOptions =
                    withoutId: !item.reference

                if item.type of Model.registry
                    ItemModel = Model.registry[item.type]
                    @[name] =
                        if not ItemModel.create? or (not value? and not field.validate?.required)
                            # if value null or undefined and type is not required lets return the value
                            # the same if field.type is one of the simple types (without document wrapper)
                            value
                        else if field.type == 'Array'
                            (ItemModel.create(v, createOptions) for v in value ? [])
                        else
                            ItemModel.create value, createOptions

                    if ItemModel.schema?
                        @$children[name] = ItemModel.schema

                else
                    throw new Error "could not find type '#{item.type}' of the field '#{name}'"
            return


        $getSchemaProperties: () ->
            return _.pick this, _.keys @$model.schema.fields


        $delete: () ->
            delete @$model.docs[@$id]


    ##################################################################################################################
    # Public API for configuration

    # Method for instantiating
    $get: () ->
        return Document












