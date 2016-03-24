kefir = require 'kefir'
_ = require 'lodash'

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
    board.create(fn)[1]

  component: (wireState, component) => 
    React.createClass
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

        @ctrl.propsProperty = (names...) => 
          @_propStream
            .map (it) -> _.pick it, names

        @ctrl.stateProperty = (names...) ->
          @_receiveState
            .map (it) -> _.pick it, names

        @ctrl.isAlive = @isAlive

        oldSignal = @ctrl.signal
        @ctrl.signal = (value, reducers...) => 
          oldSignal(value, reducers...).takeUntilBy @dead


        streams = []
        initialState = {}
        for k, stream of wireState(@ctrl)
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
            .skipDuplicates(_.isEqual)
            .scan (state, [name, value]) ->
              _.assign {}, state, "#{name}": value
            , {}
            .skipDuplicates(_.isEqual)
            .wire (stream) =>
              stream.to @_receiveState
              stream.holdLatestWhile blocked
              .onValue (state) =>
                @setState state

        initialState

      componentWillReceiveProps: (nextProps) ->
        @_receiveProps.emit nextProps
      
      componentWillUnmount: ->
        @_alive.emit false
        @_blockers?.end()
        @_alive.end()
        @_receiveProps.end()
        @ctrl.end()

      componentDidMount: ->
        @_blockers?.emit false

      componentWillUpdate: ->
        @_blockers?.emit true
        # @clearWires()

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
          _.merge {wire: @wire, wiredState: @state, slot: @ctrl.slot}, @props

