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

kefir.Observable.prototype.wire = (self, fn) ->
  if fn
    @state = self.state
    @props = self.props
    @slot = self.slot
    @board = self.board
    fn.call @
  else
    self.call @

kefir.Observable.prototype.to = (slots...) ->
  for slot in slots
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

  fn?.call o
  o


module.exports = create: (fn) ->
  board = board.create(fn)

  board: board
  mixin:
    getInitialState: ->
      @board = board

      @_alive = kefir.emitter()
      @_rerender = kefir.emitter()
      @_receiveProps = kefir.emitter()
      @_receiveState = kefir.emitter()
      @_wires = []

      @isAlive = @_alive.scan snd, true
      @dead = @isAlive.filter (it) -> it == false
      @_propStream = @_receiveProps
      .scan snd, @props

      @slots = {}

      self = @

      streams = []

      initialState = {}

      @wiring = true
      for k, stream of @wireState?()
        @wiring = false
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
        .wire ->
          @to self._receiveState
          @holdLatestWhile blocked
          .onValue (state) ->
            self.setState state

      initialState

    propsProperty: (names...) ->
      @_propStream
        .map (it) -> _.pick it, names


    stateProperty: (names...) ->
      @_receiveState
        .map (it) -> _.pick it, names

    componentWillReceiveProps: (nextProps) ->
      @_receiveProps.emit nextProps

    signal: (value, reducers...) ->
      signal.create(value, reducers...).takeUntilBy @dead

    wire: (fn) ->
      if !fn
        throw new Error "wire takes function as argument, received #{fn?.toString()}"
      @_wires.push wire = kefir.emitter()
      wire.wire @, fn

      wire.emit

    slot: (name) ->
      @slots[name] ||= kefir.emitter()

    componentWillUnmount: ->
      @_alive.emit false
      @_blockers?.end()
      @_alive.end()
      @_rerender.end()
      @_receiveProps.end()

      for k, v of @slots
        v.end()

    componentDidMount: ->
      @_blockers?.emit false

    clearWires: ->
      while @_wires.length
        @_wires.pop().end()

    componentWillUpdate: ->
      @_blockers?.emit true
      @_rerender.emit true
      @clearWires()

    componentDidUpdate: ->
      @_blockers?.emit false
