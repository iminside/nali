Nali.extend Model:

  extension: ->
    if @_name isnt 'Model'
      @_table       = @_tables[ @_name ] ?= []
      @_table.index = {}
      @_parseRelations()
      @_adapt()
    @

  cloning: ->
    @_views = {}

  _tables:     {}
  _callStack:  []
  attributes: {}
  updated:     0
  destroyed:   false

  _adapt: ->
    for name, method of @ when /^__\w+/.test name
      do ( name, method ) =>
        @[ name[ 2.. ] ] = @[ name ] if typeof method is 'function'
    @_adaptViews()
    @

  _adaptViews: ->
    @_views = {}
    for name, view of @View.extensions when name.indexOf( @_name ) >= 0
      do ( name, view ) =>
        @_views[ short = view._shortName ] = view
        shortCap = short.capitalize()
        unless @[ viewMethod = 'view' + shortCap ]? then @[ viewMethod ] = -> @view short
        unless @[ showMethod = 'show' + shortCap ]? then @[ showMethod ] = ( insertTo ) -> @show short, insertTo
        unless @[ hideMethod = 'hide' + shortCap ]? then @[ hideMethod ] = -> @hide short
    @

  _callStackAdd: ( params ) ->
    # добавляет задачу в очередь на выполнение, запускает выполнение очереди
    @_callStack.push params
    @runStack()
    @

  runStack: ->
    # запускает выполнение задач у существующих моделей
    for item, index in @_callStack[ 0.. ]
      if model = @extensions[ item.model ].find item.id
        model[ item.method ] item.params
        @_callStack.splice @_callStack.indexOf( item ), 1
    @

  # работа с моделями

  _accessing: ->
    # устанавливает геттеры доступа к атрибутам и связям
    @access @attributes
    @_setRelations()
    @

  save: ( success, failure ) ->
    # отправляет на сервер запрос на сохранение модели, вызывает success в случае успеха и failure при неудаче
    @beforeSave?()
    if @isValid()
      @query "#{ @_name.lower() }s.save", @attributes,
        ( { attributes, created, updated } ) =>
          @update( attributes, updated, created ).write()
          @afterSave?()
          success? @
    else failure? @
    @

  sync: ( { name, attributes, created, updated, destroyed } ) ->
    # синхронизирует пришедшую с сервера модель с локальной, либо создает новую
    if model = @extensions[ name ].find attributes.id
      if destroyed then model.remove()
      else if updated > @updated
        model.updated = updated
        model.created = created
        model.update attributes
    else
      model = @extensions[ name ].new attributes
      model.updated = updated
      model.created = created
      model.write()
    @

  select: ( options ) ->
    # отправляет на сервер запрос на выборку моделей
    obj = {}
    if typeof options is 'object'
      obj.selector = Object.keys( options )[0]
      obj.params   = options[ obj.selector ]
    else
      obj.selector = options
      obj.params   = {}
    @query @_name.lower() + 's.select', obj
    @

  written: ->
    @ in @_table

  write: ->
    # добавляет модель в локальную таблицу, генерирует событие create
    @_table.index[ @id ] = @ if @id and not @_table.index[ @id ]
    unless @written()
      @_table.push @
      @onCreate?()
      @Model.trigger "create.#{ @_name.lower() }", @
      @Model.runStack()
    @

  remove: ->
    # удаляет модель из локальной таблицы, генерирует событие destroy
    if @written()
      @destroyed = true
      delete @_table.index[ @id ]
      @_table.splice @_table.indexOf( @ ), 1
      @trigger 'destroy'
      @Model.trigger "destroy.#{ @_name.lower() }", @
      @onDestroy?()
      @unsubscribeAll()
    @

  new: ( attributes ) ->
    # создает модель, не сохраняя её на сервере
    model = @clone( attributes: @_defaultAttributes() )._accessing()
    model[ name ] = @_normalizeAttributeValue name, value for name, value of attributes
    model

  create: ( attributes, success, failure ) ->
    # создает модель, и сохраняет её на сервере, вызывает success в случае успеха и failure при неудаче
    @new( attributes ).save success, failure

  update: ( attributes, checkValidation = true ) ->
    # обновляет атрибуты модели, проверяя их валидность, генерирует событие update
    changed = []
    changed.push name for name, value of attributes when @updateProperty name, value, checkValidation
    if changed.length
      @onUpdate? changed
      @trigger 'update', changed
      @Model.trigger "update.#{ @_name.lower() }", @
    @

  updateProperty: ( name, value, checkValidation = true ) ->
    # обновляет один атрибут модели, проверяя его валидность, генерирует событие update.propertyName
    value = @_normalizeAttributeValue name, value
    if @[ name ] isnt value and ( not checkValidation or @isValidAttributeValue( name, value ) )
      @[ name ] = value
      @[ 'onUpdate' + name.capitalize() ]?()
      @trigger "update.#{ name }"
      true
    else false

  upgrade: ( attributes, success, failure ) ->
    # обновляет атрибуты модели и сохраняет её на сервер
    @update( attributes ).save success, failure
    @

  destroy: ( success, failure ) ->
    # отправляет на сервер запрос на удаление модели, вызывает success в случае успеха и failure при неудаче
    @query @_name.lower() + 's.destroy', @attributes, success, failure
    @

  # поиск моделей

  find: ( id ) ->
    # находит модель по её id используя индекс
    @_table.index[ id ]

  where: ( filters ) ->
    # возвращает коллекцию моделей соответствующих фильтру
    @Collection.new @, filters

  all: ->
    # возвращает коллекцию всех моделей
    @where id: /./

  each: ( callback ) ->
    # применяет колбек ко всем моделям
    callback.call @, model for model in @_table
    @

  # работа с аттрибутами

  guid: ->
    # генерирует случайный идентификатор
    date = new Date().getTime()
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, ( sub ) ->
      rand = ( date + Math.random() * 16 ) % 16 | 0
      date = Math.floor date / 16
      ( if sub is 'x' then rand else ( rand & 0x7 | 0x8 ) ).toString 16

  _defaultAttributes: ->
    # возвращает объект аттрибутов по умолчанию
    attributes = id: @guid()
    for name, value of @attributes
      if value instanceof Object
        attributes[ name ] = if value.default? then @_normalizeAttributeValue name, value.default else null
      else attributes[ name ] = @_normalizeAttributeValue name, value
    attributes

  _normalizeAttributeValue: ( name, value ) ->
    # если формат свойства number пробует привести значение к числу
    if @::attributes[ name ]?.format is 'number' and value is ( ( correct = + value ) + '' ) then correct else value

  isCorrect: ( filters = {} ) ->
    # проверяет соответствие аттрибутов модели определенному набору фильтров, возвращает true либо false
    return filters.call @ if typeof filters is 'function'
    return false unless Object.keys( filters ).length
    for name, filter of filters
      result = if name is 'correct' and typeof filter is 'function'
        filter.call @
      else @isCorrectAttribute @[ name ], filter
      return false unless result
    return true

  isCorrectAttribute: ( attribute, filter ) ->
    # проверяет соответствие аттрибута модели определенному фильтру, возвращает true либо false
    return false unless attribute
    if filter instanceof RegExp
      filter.test attribute
    else if typeof filter is 'string'
      '' + attribute is filter
    else if typeof filter is 'number'
      + attribute is filter
    else if typeof filter is 'boolean'
      attribute is filter
    else if filter instanceof Array
      '' + attribute in filter or + attribute in filter
    else false

  # работа со связями

  _parseRelations: ( type, options ) ->
    # производит разбор связей
    @relations = {}
    for type in [ 'belongsTo', 'hasOne', 'hasMany' ]
      for options in [].concat( @[ type ] ) when @[ type ]?
        params = @[ '_parse' + type.capitalize() ] @_parseInitialRelationParams options
        section = type + if params.through? then 'Through' else ''
        ( @relations[ section ] ?= [] ).push params
    @

  _parseInitialRelationParams: ( options ) ->
    # дает начальные параметры настроек связи
    if typeof options is 'object'
      params         = name: Object.keys( options )[0]
      params.through = through if through = options[ params.name ].through
      params.key     = key     if key     = options[ params.name ].key
      params.model   = @Model.extensions[ model.capitalize() ] if model = options[ params.name ].model
    else
      params = name: options
    params

  _parseBelongsTo: ( params ) ->
    # производит разбор связей belongsTo
    params.model ?= @Model.extensions[ params.name.capitalize() ]
    params.key   ?= params.name.lower() + '_id'
    params

  _parseHasOne: ( params ) ->
    # производит разбор связей hasOne
    params.model ?= @Model.extensions[ params.name.capitalize() ]
    params.key   ?= ( if params.through then params.name else @_name + '_id' ).lower()
    params

  _parseHasMany: ( params ) ->
    # производит разбор связей hasMany
    params.model ?= @Model.extensions[ params.name[ ...-1 ].capitalize() ]
    params.key   ?= ( if params.through then params.name[ ...-1 ] else @_name + '_id' ).lower()
    params

  _setRelations: ->
    # запускает установку связей у модели
    @_setRelationsType type for type in [ 'belongsTo', 'hasOne', 'hasMany', 'hasOneThrough', 'hasManyThrough' ]
    @

  _setRelationsType: ( type ) ->
    # запускает установку связей определенного типа
    if params = @relations[ type ]
      @[ '_set' + type.capitalize() ] param for param in params
    @

  _setBelongsTo: ( { key, model, name, through } ) ->
    # устанавливает геттер типа belongsTo возвращающий связанную модель
    @getter name, => model.find @[ key ]
    @

  _setHasOne: ( { key, model, name, through } ) ->
    # устанавливает геттер типа hasOne возвращающий связанную модель
    @getter name, =>
      delete @[ name ]
      ( filters = {} )[ key ] = @id
      collection = model.where filters
      @getter name, => collection.first()
      @[ name ]
    @

  _setHasMany: ( { key, model, name, through } ) ->
    # устанавливает геттер типа hasMany возвращающий коллекцию связанных моделей
    @getter name, =>
      delete @[ name ]
      ( filters = {} )[ key ] = @id
      @[ name ] = model.where filters
    @

  _setHasOneThrough: ( { key, model, name, through } ) ->
    # устанавливает геттер типа hasOne возвращающий модель,
    # связанную с текущей через модель through
    @getter name, =>
      delete @[ name ]
      @getter name, => @[ through ][ key ]
      @[ name ]
    @

  _setHasManyThrough: ( { key, model, name, through } ) ->
    # устанавливает геттер типа hasMany возвращающий коллекцию моделей,
    # связанных с текущей через модель through
    @getter name, =>
      delete @[ name ]
      list = @[ through ]
      @[ name ] = model.where correct: ->
        return true for model in list when model[ key ] is @
        false
      @[ name ].subscribeTo @[ through ], 'update.length.add',    ( model ) -> @add    model[ key ]
      @[ name ].subscribeTo @[ through ], 'update.length.remove', ( model ) -> @remove model[ key ]
      @[ name ]
    @

  # работа с видами

  view: ( name ) ->
    # возвращает объект вида, либо новый, либо ранее созданный
    unless ( view = @_views[ name ] )?
      if ( view = @::_views[ name ] )?
        view = @_views[ name ] = view.clone model: @
      else console.error 'View "%s" of model "%s" does not exist', name, @_name
    view

  show: ( name, insertTo ) ->
    # вставляет html-код вида в указанное место ( это может быть селектор, html-элемент или ничего - тогда
    # вставка произойдет в элемент указанный в самом виде либо в элемент-контейнер приложения )
    # функция возвращает объект вида при успехе либо null при неудаче
    if ( view = @view( name ) )? then view.show insertTo else null

  hide: ( name, delay ) ->
    # удаляет html-код вида со страницы
    # функция возвращает объект вида при успехе либо null при неудаче
    if ( view = @view( name ) )? then view.hide delay else null

  # валидации

  validations:
    # набор валидационных проверок
    presence:  ( value, filter ) -> if filter then value? else not value?
    inclusion: ( value, filter ) -> not value? or value in filter
    exclusion: ( value, filter ) -> not value? or value not in filter
    length:    ( value, filter ) ->
      if not value? then return true else value += ''
      return false if filter.in?  and value.length not in filter.in
      return false if filter.min? and value.length < filter.min
      return false if filter.max? and value.length > filter.max
      return false if filter.is?  and value.length isnt filter.is
      true
    format:    ( value, filter ) ->
      return true if not value?
      return true if filter instanceof RegExp and filter.test value
      return true if filter is 'boolean'      and /^true|false$/.test value
      return true if filter is 'number'       and /^[0-9]+$/.test value
      return true if filter is 'letters'      and /^[A-zА-я]+$/.test value
      return true if filter is 'email'        and /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,4})+$/.test value
      false

  isValid: ->
    # проверяет валидна ли модель, вызывается перед сохранением модели на сервер если модель валидна,
    # то вызов model.isValid() вернет true, иначе false
    return false for name, value of @attributes when not @isValidAttributeValue( name, value )
    true

  isValidAttributeValue: ( name, value ) ->
    # проверяет валидно ли значение для определенного атрибута модели, вызывается при проверке
    # валидности модели, а также в методе updateProperty() перед изменением значения атрибута, если значение
    # валидно то вызов model.isValidAttributeValue( name, value )? вернет true, иначе false
    for validation, tester of @validations when ( filter = @::attributes[ name ]?[ validation ] )?
      unless tester.call @, value, filter
        console.warn 'Attribute %s of model %O has not validate %s', name, @, validation
        if notice = @::attributes[ name ].notice
          for type, params of notice
            if @Notice[ type ]? then @Notice[ type ] params
            else console.warn 'Unknown Notice type "%s"', type
        return false
    true
