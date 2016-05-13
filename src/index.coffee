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
      emitter.emit value
      value = null

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

    consume: (consumers) ->
      for name, fn of consumers
        do (name, fn) ->
          o.slot(name).onValue (it) -> fn it

    end: () =>
      for name, slot of slots
        slot.end()

  [o, fn? o]


module.exports =
  create: (fn) =>
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
        r.map((it) => it[1].skip(1).take(1))
      )(signals)

    b.validateSignals = (component, validator, cb) =>
      { renderToString } = require 'react-dom/server'
      wiredStates = []
      result = renderToString(b.inject(component, wiredStates))
      invalidSignals = validate(wiredStates, validator)

      [wiredStates...].forEach((it) => it.component.end())

      if (invalidSignals.length)
        kefir.zip(invalidSignals).take(1).onValue(() => b.validateSignals(component, validator, cb))
      else
        cb(result)

    b

  component: (wireState, component) =>
    if !component
      component = wireState
      wireState = undefined
    React.createClass
      displayName: component.displayName || component.name

      contextTypes:
        switchboard: React.PropTypes.object
        wiredStates: React.PropTypes.array

      getInitialState: ->
        @_wires = []

        @_alive = kefir.emitter()
        @_receiveProps = kefir.emitter()
        @_receiveState = kefir.emitter()
        @isAlive = @_alive.scan snd, true
        @dead = @isAlive.filter (it) -> it == false
        @_propStream = @_receiveProps
                        .scan snd, @props

        @ctrl = board.create()[0]

        @ctrl.propsProperty = @_propStream
        @ctrl.stateProperty = @_receiveState

        @ctrl.isAlive = @isAlive
        @ctrl.switchboard = @context.switchboard

        oldSignal = @ctrl.signal
        @ctrl.signal = (value, reducers...) =>
          oldSignal(value, reducers...).takeUntilBy @dead


        streams = []
        initialState = {}
        wiredState = wireState?(@ctrl)

        for k, stream of wiredState
          do (k, stream) ->
            stream.take(1).onValue (it) ->
              initialState[k] = it

            streams.push stream.skip(1).map (it) ->
              [k, it]

        if streams.length
          @_blockers = kefir.emitter()
          blocked = @_blockers.scan snd, true
          .skipDuplicates()

          @updates = kefir.merge(streams)
            .takeUntilBy @dead
            .skipDuplicates(r.equals)
            .scan (state, [name, value]) ->
              r.merge state, "#{name}": value
            , {}
            .skipDuplicates(r.equals)
            .holdLatestWhile blocked
            .onValue (state) =>
              @_receiveState.emit(r.merge(this.state, state))
              @setState state

        @_receiveState.emit(initialState)

        if @context.wiredStates and wiredState
          @savedWiredState =
            signals: wiredState
            values: initialState
            component: @

          @context.wiredStates.push @savedWiredState

        initialState

      componentWillReceiveProps: (nextProps) ->
        @_receiveProps.emit nextProps

      componentWillUnmount: ->
        @end()

      end: ->
        @_alive.emit false
        @_blockers?.end()
        @_alive.end()
        @_receiveProps.end()
        @ctrl.end()

        if @context.wiredStates
          @context.wiredStates.splice @context.wiredStates.indexOf(@savedWiredState), 1
          delete @savedWiredState


      componentDidMount: ->
        @_blockers?.emit false

      componentWillUpdate: ->
        @_blockers?.emit true
        @clearWires()

      componentDidUpdate: ->
        @_blockers?.emit false

      wire: (fn) ->
        if !fn
          throw new Error "wire takes function as argument, received #{fn?.toString()}"

        wire = undefined
        invocation = (args...) =>
          if !wire
            @_wires.push wire = kefir.emitter()
            wire.wire fn

          wire.emit args...

        invocation

      clearWires: ->
        while @_wires.length
          @_wires.pop().end()

      render: ->
        React.createElement component,
          r.merge {wire: @wire, wiredState: @state, slot: @ctrl.slot, switchboard: @context.switchboard}, @props

  combine: (fns...) => (ctrl) =>
    r.merge (fns.map (it) => it ctrl)...


