kefir = require 'kefir'
r = require 'ramda'
React = require 'react'

snd = (a, b) -> b

kefir.emitter = ->
  emitter = null
  stream = kefir.stream (_emitter) ->
    emitter = _emitter

  stream.emit = (x) -> emitter?.emit x; @
  stream.emit.emit = stream.emit
  stream.error = (x) -> emitter?.error x; @
  stream.emitEvent = (x) -> emitter?.emitEvent x; @
  stream.end = (x) -> emitter?.end()

  stream.setName 'emitter'


kefir.Observable.prototype.doAction = (f) ->
  @map (it) ->
    f it
    it

kefir.Observable.prototype.not = ->
  @map (it) -> !it

kefir.Observable.prototype.holdLatestWhile = (obs) ->
  emitter = null
  isBlocked = true
  value = null
  tryFlush = ->
    if !isBlocked and value != null and emitter
      valueToEmit = value
      value = null
      emitter.emit valueToEmit

  setIsFree = (it) ->
    isBlocked = it
    tryFlush()

  obs.onValue setIsFree

  @withHandler (_emitter, event) ->
    emitter = _emitter
    if event.type == 'end'
      obs.offValue setIsFree
      emitter.end()
    else if event.type == 'value'
      value = event.value
      tryFlush()
  .setName 'holdLatestWhile'

kefir.Observable.prototype.rescue = (f) ->
  @withHandler (emitter, event) ->
    if event.type == 'end'
      emitter.end()
    else if event.type == 'value'
      emitter.emit event.value
    else if event.type == 'error'
      emitter.emit f event.value

kefir.Observable.prototype.cancel = ->
  @map (e) ->
    e.preventDefault()
    e

kefir.Observable.prototype.set = (value) ->
  @map -> value

kefir.Observable.prototype.extract = ->
  @map (e) -> e.target.value

kefir.Observable.prototype.wire = (fn) -> fn @

kefir.Observable.prototype.to = (slots...) ->
  for slot in slots
    if !slot
      throw new Error "to received invalid slot #{slot}"
    if !slot.emit
      throw new Error "Expected slot to be an emitter, received #{slot?.toString()}"
  @onValue (it) ->
    slots.forEach (slot) ->
      slot.emit it


signal = create: (value, reducers...) ->
  reducers = [].concat(reducers).reduce (r, nextValue) ->
    if nextValue.call
      r[r.length-1].push nextValue
      r
    else
      r.concat [[nextValue]]
  , []

  kefir.merge(
    [kefir.constant(value)].concat reducers.map ([stream, f]) ->
      f ||= (oldValue, newValue) -> newValue

      stream.map (newValue) ->
        f value, newValue
  ).doAction (newValue) ->
    value = newValue
  .toProperty()


board = create: (fn) ->
  slots = {}
  o =
    signal: (value, reducers...) ->
      signal.create value, reducers...

    slot: (name) ->
      slots[name] ||= kefir.emitter()

    safeSlot: (componentName) -> (name) ->
      if !slots[name]
        throw new Error("Invalid slot used '#{name}' when rendering #{componentName} - slot not defined in wireState")

      slots[name]

    consume: (consumers) ->
      for name, fn of consumers
        do (name, fn) ->
          o.slot(name).onValue (it) -> fn it

    end: () =>
      for name, slot of slots
        slot.end()

  [o, fn? o]


module.exports =
  create: (fn) ->
    throw new Error('create() has been deprecated in favor of model (https://github.com/ArseAssassin/reactive-switchboard/issues/11)')

  model: (fn) =>
    b = board.create(fn)[1]
    b.inject = (element, wiredStates) =>
      React.createElement React.createClass
        displayName: 'ReactiveSwitchboardInjector'

        childContextTypes:
          switchboard: React.PropTypes.object
          wiredStates: React.PropTypes.array

        getChildContext: () =>
          switchboard: b
          wiredStates: wiredStates

        render: () => element

    validate = (signals, fn) =>
      r.pipe(
        r.map((it) => r.zip(r.values(it.values), r.values(it.signals)))
        r.unnest()
        r.filter(([value]) => !fn(value))
        r.map((it) => it[1].changes())
      )(signals)

    b.validateSignals = (component, validator, cb) =>
      { renderToString } = require 'react-dom/server'
      wiredStates = []
      result = renderToString(b.inject(component, wiredStates))
      invalidSignals = validate(wiredStates, validator)

      [wiredStates...].forEach((it) => it.component.end())

      if (invalidSignals.length)
        kefir.zip(invalidSignals.map((it) => it.filter(validator))).take(1).onValue(() => b.validateSignals(component, validator, cb))
      else
        cb(result)

    b

  slot:
    prepend: (fn, slot) ->
      e = kefir.emitter()
      slot.onEnd () -> e.end()
      fn(e).to slot

      e

  component: (wireState, component) =>
    if !component
      component = wireState
      wireState = undefined

    componentName = component.displayName || component.name || 'AnonymousSwitchboardComponent'

    React.createClass
      displayName: componentName

      contextTypes:
        switchboard: React.PropTypes.object
        wiredStates: React.PropTypes.array

      getInitialState: ->
        @_wires = []
        @wiredState = {}

        @_dirty = false
        @_alive = kefir.emitter()
        @_receiveProps = kefir.emitter()
        @isAlive = @_alive.scan snd, true
        @dead = @isAlive.filter (it) -> it == false
        @_propStream = @_receiveProps
                        .scan snd, @props

        @ctrl = board.create()[0]

        @ctrl.propsProperty = @_propStream

        @ctrl.isAlive = @isAlive
        @ctrl.switchboard = @context.switchboard

        streams = []
        initialState = {}
        wiredState = wireState?(@ctrl)

        for k, stream of wiredState
          do (k, stream) ->
            streams.push stream.map (it) -> [k, it]

        if streams.length
          @updates = kefir.merge(streams)
            .takeUntilBy @dead
            .scan (state, [name, value]) ->
              r.merge state, "#{name}": value
            , {}
            .onValue (state) =>
              @wiredState = state

              if initialStateDone
                @_dirty = true

                if @_updateState
                  clearTimeout @_updateState

                @_updateState = setTimeout () =>
                                  if @_dirty
                                    @forceUpdate()
                                , 0

        if @context.wiredStates and wiredState
          @savedWiredState =
            signals: wiredState
            values: initialState
            component: @

          @context.wiredStates.push @savedWiredState

        initialStateDone = true

        keys = r.keys @wiredState
        for k of wiredState or {}
          if !r.contains k, keys
            console.warn "wireState for #{componentName} didn't produce an initial value for #{k} - might not be a Kefir property"

        @wiredState

      componentWillReceiveProps: (nextProps) ->
        @_receiveProps.emit nextProps

      componentWillUnmount: ->
        @end()

      componendDidUpdate: ->
        @_dirty = false

      end: ->
        @_alive.emit false
        @_alive.end()
        @_receiveProps.end()
        @ctrl.end()

        if @context.wiredStates
          @context.wiredStates.splice @context.wiredStates.indexOf(@savedWiredState), 1
          delete @savedWiredState


      componentWillUpdate: ->
        @clearWires()

      wire: (arg) ->
        if typeof arg == 'string'
          invocation = (it) => @ctrl.safeSlot(componentName)(arg).emit it
        else if arg.emit
          invocation = arg.emit
        else if arg.call
          wire = undefined
          invocation = (args...) =>
            if !wire
              @_wires.push wire = kefir.emitter()
              wire.wire arg

            wire.emit args...
        else
          throw new Error("wire received #{arg} as argument - expected function, slot or string")

        invocation

      clearWires: ->
        while @_wires.length
          @_wires.pop().end()

      render: ->
        React.createElement component,
          r.merge {
            wire:         @wire
            wiredState:   @wiredState
            slot:         @ctrl.safeSlot componentName
            switchboard:  @context.switchboard,
          }, @props

