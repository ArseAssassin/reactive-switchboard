kefir = require 'kefir'
r = require 'ramda'
React = require 'react'

snd = (a, b) -> b

switchboardSlot = ->
  emitter = null
  stream = kefir.stream (_emitter) ->
    emitter = _emitter

  stream.emit = (x) -> emitter?.emit x; @
  stream.emit.emit = stream.emit
  stream.error = (x) -> emitter?.error x; @
  stream.emitEvent = (x) -> emitter?.emitEvent x; @
  stream.end = (x) -> emitter?.end()

  stream.setName 'switchboardSlot'

kefir.emitter = switchboardSlot

switchboardSlot.prepend = (fn, slot) ->
  e = switchboardSlot()
  slot.onEnd () -> e.end()
  fn(e).to slot

  e

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
  onEnd = switchboardSlot()

  o =
    signal: (value, reducers...) ->
      s = signal.create value, reducers...
      s.takeUntilBy onEnd

    slot: (name) ->
      slots[name] ||= switchboardSlot()

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

      onEnd.end()

  [o, fn? o]


module.exports =
  create: (fn) ->
    throw new Error('create() has been deprecated in favor of model (https://github.com/ArseAssassin/reactive-switchboard/issues/11)')

  model: (fn) =>
    [ctrl, b] = board.create(fn)

    if b.endBy
      b.endBy.take(1).onValue ctrl.end
    else
      b.endBy = kefir.never()

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

  slot: switchboardSlot

  component: (wireState, component) =>
    if !component
      component = wireState
      wireState = undefined

    if !component or !component.call
      throw new Error "Calling switchboard.component with a non-function #{component} - should be called with a render function"

    if component.prototype.render
      throw new Error "Calling switchboard.component with a React component - should be called with a render function"

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
        @_alive = switchboardSlot()
        @_receiveProps = switchboardSlot()
        @_lifecycle = switchboardSlot()
        @isAlive = @_alive.scan snd, true
        @dead = @isAlive.filter (it) -> it == false
        @_propStream = @_receiveProps
                        .scan snd, @props

        @ctrl = board.create()[0]

        @ctrl.propsProperty = @_propStream
        @ctrl.lifecycle = @_lifecycle
        updateBy = @_propStream

        @ctrl.isAlive = @isAlive
        @ctrl.switchboard = @context.switchboard

        streams = []
        initialState = {}
        wiredState = wireState?(@ctrl)

        for k, stream of wiredState
          if !stream or !stream.onValue
            throw new Error("#{componentName}.#{k} is not a stream - returned a non-stream value from wireState: #{String(stream)}")

          if k == 'updateBy'
            updateBy = stream
          else
            do (k, stream) =>
              try
                stream
                .takeUntilBy(@dead)
                .onError (it) ->
                  console.error "#{componentName}.#{k} produced an error: #{String(it)}"
              catch e
                console.error "Error thrown when listening to #{componentName}.#{k}", e
                throw e

              streams.push stream.map (it) -> [k, it]

        if streams.length
          @updates = kefir.merge(streams)
            .takeUntilBy @dead
            .scan (state, [name, value]) ->
              r.assoc name, value, state
            , {}
            .onValue (state) =>
              @wiredState = state

              if initialStateDone
                @updateState()

        if @context.wiredStates and wiredState
          @savedWiredState =
            signals: wiredState
            values: initialState
            component: @

          @context.wiredStates.push @savedWiredState

        initialStateDone = true

        keys = r.keys @wiredState
        for k of wiredState or {}
          if k != 'updateBy' and !r.contains k, keys
            console.warn "wireState for #{componentName} didn't produce an initial value for #{k} - might not be a Kefir property"

        updateBy.onValue @updateState

        @wiredState

      updateState: ->
        @_dirty = true

        if @_updateState
          clearTimeout @_updateState

        @_updateState = setTimeout () =>
                          if @_dirty && @isMounted()
                            @forceUpdate()
                        , 0

      shouldComponentUpdate: ->
        false

      componentWillReceiveProps: (nextProps) ->
        @_lifecycle.emit 'componentWillReceiveProps'
        try
          @_receiveProps.emit nextProps
        catch e
          console.error "Component #{componentName} threw an error when receiving props"
          throw e

      componentWillMount: ->
        @_lifecycle.emit 'componentWillMount'

      componentDidMount: ->
        @_lifecycle.emit 'componentDidMount'

      componentWillUnmount: ->
        @_lifecycle.emit 'componentWillUnmount'
        @end()

      componendDidUpdate: ->
        @_lifecycle.emit 'componentDidUpdate'
        @_dirty = false

      end: ->
        @_alive.emit false
        @_alive.end()
        @_lifecycle.end()
        @_receiveProps.end()
        @ctrl.end()

        if @context.wiredStates
          @context.wiredStates.splice @context.wiredStates.indexOf(@savedWiredState), 1
          delete @savedWiredState


      componentWillUpdate: ->
        @_lifecycle.emit 'componentDidUpdate'
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
              @_wires.push wire = switchboardSlot()
              wire.wire arg

            wire.emit args...
        else
          throw new Error("wire received #{arg} as argument - expected function, slot or string")

        invocation

      clearWires: ->
        while @_wires.length
          @_wires.pop().end()

      render: ->
        internals = {
          wire:         @wire
          wiredState:   @wiredState
          slot:         @ctrl.safeSlot componentName
          switchboard:  @context.switchboard,
        }
        intersection = r.intersection(r.keys(internals), r.keys(@props))

        if intersection.length > 0
          console.warn "Switchboard child component #{componentName} received clashing props from parent component: #{intersection.join(', ')}"

        component(r.merge internals, @props)

