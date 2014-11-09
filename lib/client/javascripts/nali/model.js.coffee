Nali.extend Model:

  extension: ->
    if @_name isnt 'Model'
      @table       = @tables[ @_name ] ?= []
      @table.index = {}
      @parseRelations()
      @adapt()
    @

  cloning: ->
    @views = {}

  tables:      {}
  hasOne:      []
  hasMany:     []
  attributes:  {}
  updated:     0
  noticesWait: []
  destroyed:   false

  adapt: ->
    for name, method of @ when /^_\w+/.test name
      do ( name, method ) =>
        if typeof method is 'function'
          @[ name[ 1.. ] ] = ( args... ) -> @[ name ] args...
    @adaptViews()
    @

  adaptViews: ->
    @views = {}
    for name, view of @View.extensions when name.indexOf( @_name ) >= 0
      do ( name, view ) =>
        @views[ short = view._shortName ] = view
        unless @[ short ]?
          @[ short ] = ->
            @show short
            @
    @

  notice: ( params ) ->
    # добавляет уведомление в очередь на выполнение, запускает выполнение очереди
    @noticesWait.push params
    @runNotices()
    @

  runNotices: ->
    # запускает выполнение уведомлений на существующих моделях
    for item, index in @noticesWait[ 0.. ]
      if model = @extensions[ item.model ].find item.id
        model[ item.notice ] item.params
        @noticesWait.splice @noticesWait.indexOf( item ), 1
    @

  # работа с моделями

  accessing: ->
    # устанавливает геттеры доступа к атрибутам и связям
    @access @attributes
    @setRelations()
    @

  force: ( params = {} ) ->
    # создает новую модель с заданными атрибутами
    attributes         = @defaultAttributes()
    attributes[ name ] = value for name, value of params
    attributes[ name ] = @normalizeValue value for name, value of attributes
    @clone( attributes: attributes ).accessing()

  save: ( success, failure ) ->
    # отправляет на сервер запрос на сохранение модели, вызывает success в случае успеха и failure при неудаче
    if @isValid()
      @query "#{ @_name.lower() }s.save", @attributes,
        ( { attributes, created, updated } ) =>
          @update( attributes, updated, created ).write()
          success? @
    else failure? @
    @

  sync: ( { _name, attributes, created, updated, destroyed } ) ->
    # синхронизирует пришедшую с сервера модель с локальной, либо создает новую
    if model = @extensions[ _name ].find attributes.id
      if destroyed then model.remove()
      else model.update attributes, updated, created
    else
      model = @extensions[ _name ].new attributes
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

  write: ->
    # добавляет модель в локальную таблицу, генерирует событие create
    @table.index[ @id ] = @ if @id and not @table.index[ @id ]
    unless @ in @table
      @table.push @
      @onCreate?()
      @Model.trigger "create.#{ @_name.lower() }", @
      @Model.runNotices()
    @

  remove: ->
    # удаляет модель из локальной таблицы, генерирует событие destroy
    if @ in @table
      @destroyed = true
      delete @table.index[ @id ]
      @table.splice @table.indexOf( @ ), 1
      @trigger 'destroy'
      @onDestroy?()
      @unsubscribeAll()
    @

  new: ( attributes ) ->
    # создает модель, не сохраняя её на сервере
    @force attributes

  create: ( attributes, success, failure ) ->
    # создает модель, и сохраняет её на сервере, вызывает success в случае успеха и failure при неудаче
    @new( attributes ).save success, failure

  update: ( attributes, updated = 0, created = 0 ) ->
    # обновляет атрибуты модели, проверяя их валидность, генерирует событие update
    if not updated or updated > @updated
      @created = created if created
      changed = []
      changed.push name for name, value of attributes when @updateAttribute name, value
      if changed.length
        @updated = updated if updated
        @onUpdate? changed
        @trigger 'update', changed
        @Model.trigger "update.#{ @_name.lower() }", @
    @

  updateAttribute: ( name, value ) ->
    # обновляет один атрибут модели, проверяя его валидность, генерирует событие update.attributeName
    value = @normalizeValue value
    if @attributes[ name ] isnt value and @isValidAttributeValue( name, value )
      @attributes[ name ] = value
      @[ 'onUpdate' + name.capitalize() ]?()
      @trigger "update.#{ name }"
      true
    else false

  destroy: ( success, failure ) ->
    # отправляет на сервер запрос на удаление модели, вызывает success в случае успеха и failure при неудаче
    @query @_name.lower() + 's.destroy', @attributes, success, failure
    @

  # поиск моделей

  find: ( id ) ->
    # находит модель по её id используя индекс
    @table.index[ id ]

  where: ( filters ) ->
    # возвращает коллекцию моделей соответствующих фильтру
    collection = @Collection.new @, filters
    collection.add model for model in @table when model.isCorrect filters
    if @forced and not collection.length
      attributes = {}
      attributes[ key ] = value for key, value of filters when typeof value in [ 'number', 'string' ]
      collection.add @new attributes
    collection

  all: ->
    @where id: /./

  # работа с аттрибутами

  guid: ->
    # генерирует случайный идентификатор
    date = new Date().getTime()
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, ( sub ) ->
      rand = ( date + Math.random() * 16 ) % 16 | 0
      date = Math.floor date / 16
      ( if sub is 'x' then rand else ( rand & 0x7 | 0x8 ) ).toString 16

  defaultAttributes: ->
    # возвращает объект аттрибутов по умолчанию
    attributes = id: @guid()
    for name, value of @attributes
      if value instanceof Object
        attributes[ name ] = if value.default? then value.default else null
      else attributes[ name ] = value
    attributes

  normalizeValue: ( value ) ->
    # приводит значения к нормальному виду, если в строке только числа - преобразуется к числу
    # т.е. строка '123' становится числом 123, '123.5' становится 123.5, а '123abc' остается строкой
    if typeof value is 'string'
      value = "#{ value }".trim()
      if value is ( ( correct = + value ) + '' ) then correct else value
    else value

  isCorrect: ( filters = {} ) ->
    # проверяет соответствие аттрибутов модели определенному набору фильтров, возвращает true либо false
    return filters.call @ if typeof filters is 'function'
    return false unless Object.keys( filters ).length
    return false for name, filter of filters when not @isCorrectAttribute @attributes[ name ], filter
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
    else if filter instanceof Array
      '' + attribute in filter or + attribute in filter
    else false

  # работа со связями

  parseRelations: ( type, options ) ->
    # производит разбор связей
    @relations = {}
    for type in [ 'belongsTo', 'hasOne', 'hasMany' ]
      for options in [].concat( @[ type ] ) when @[ type ]?
        params = @[ 'parse' + type.capitalize() ] @parseInitialRelationParams options
        section = type + if params.through? then 'Through' else ''
        ( @relations[ section ] ?= [] ).push params
    @

  parseInitialRelationParams: ( options ) ->
    # дает начальные параметры настроек связи
    if typeof options is 'object'
      params         = name: Object.keys( options )[0]
      params.through = through if through = options[ params.name ].through
      params.key     = key     if key     = options[ params.name ].key
      params.model   = @Model.extensions[ model.capitalize() ] if model = options[ params.name ].model
    else
      params = name: options
    params

  parseBelongsTo: ( params ) ->
    # производит разбор связей belongsTo
    params.model ?= @Model.extensions[ params.name.capitalize() ]
    params.key   ?= params.name.lower() + '_id'
    params

  parseHasOne: ( params ) ->
    # производит разбор связей hasOne
    params.model ?= @Model.extensions[ params.name.capitalize() ]
    params.key   ?= ( if params.through then params.name else @_name + '_id' ).lower()
    params

  parseHasMany: ( params ) ->
    # производит разбор связей hasMany
    params.model ?= @Model.extensions[ params.name[ ...-1 ].capitalize() ]
    params.key   ?= ( if params.through then params.name[ ...-1 ] else @_name + '_id' ).lower()
    params

  setRelations: ->
    # запускает установку связей у модели
    @setRelationsType type for type in [ 'belongsTo', 'hasOne', 'hasMany', 'hasOneThrough', 'hasManyThrough' ]
    @

  setRelationsType: ( type ) ->
    # запускает установку связей определенного типа
    if params = @relations[ type ]
      @[ 'set' + type.capitalize() ] param for param in params
    @

  setBelongsTo: ( { key, model, name, through } ) ->
    # устанавливает геттер типа belongsTo возвращающий связанную модель
    @getter name, => model.find @[ key ]
    @

  setHasOne: ( { key, model, name, through } ) ->
    # устанавливает геттер типа hasOne возвращающий связанную модель
    @getter name, =>
      delete @[ name ]
      ( filters = {} )[ key ] = @id
      collection = model.where filters
      @getter name, => collection.first()
      @[ name ]
    @

  setHasMany: ( { key, model, name, through } ) ->
    # устанавливает геттер типа hasMany возвращающий коллекцию связанных моделей
    @getter name, =>
      delete @[ name ]
      ( filters = {} )[ key ] = @id
      @[ name ] = model.where filters
    @

  setHasOneThrough: ( { key, model, name, through } ) ->
    # устанавливает геттер типа hasOne возвращающий модель,
    # связанную с текущей через модель through
    @getter name, =>
      delete @[ name ]
      @getter name, => @[ through ][ key ]
      @[ name ]
    @

  setHasManyThrough: ( { key, model, name, through } ) ->
    # устанавливает геттер типа hasMany возвращающий коллекцию моделей,
    # связанных с текущей через модель through
    @getter name, =>
      delete @[ name ]
      @[ name ] = @Collection.new model, ->
        return true for model in @[ through ] when model[ key ] is @
        false
      @[ name ].add @[ through ].pluck key
      @[ name ].subscribeTo @[ through ], 'update.length.add',    ( collection, model ) -> @add    model[ key ]
      @[ name ].subscribeTo @[ through ], 'update.length.remove', ( collection, model ) -> @remove model[ key ]
      @[ name ]
    @

  # работа с видами

  view: ( name ) ->
    # возвращает объект вида, либо новый, либо ранее созданный
    unless ( view = @views[ name ] )?
      if ( view = @::views[ name ] )?
        view = @views[ name ] = view.clone model: @
      else console.error "View %s of model %O does not exist", name, @
    view

  show: ( name, insertTo ) ->
    # вставляет html-код вида в указанное место ( это может быть селектор, html-элемент или ничего - тогда
    # вставка произойдет в элемент указанный в самом виде либо в элемент-контейнер приложения )
    # функция возвращает объект вида при успехе либо null при неудаче
    if ( view = @view( name ) )? then view.show insertTo else null

  hide: ( name ) ->
    # удаляет html-код вида со страницы
    # функция возвращает объект вида при успехе либо null при неудаче
    if ( view = @view( name ) )? then view.hide() else null

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
    # валидности модели, а также в методе updateAttribute() перед изменением значения атрибута, если значение
    # валидно то вызов model.isValidAttributeValue( name, value )? вернет true, иначе false
    for validation, tester of @validations when ( filter = @::attributes[ name ]?[ validation ] )?
      unless tester.call @, value, filter
        console.warn 'Attribute %s of model %O has not validate %s', name, @, validation
        for type in [ 'info', 'warning', 'error' ] when ( message = @::attributes[ name ][ type ] )?
          @Notice[ type ] message: message
        return false
    true
