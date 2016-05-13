# API Documentation

This is a list of public API methods and properties that reactive-switchboard exposes.

## ```reactive-switchboard```

```reactive-switchboard.create(fn)``` is used to construct a new switchboard. It accepts a single function as an argument which is called with the created ```switchboard``` bound to ```this``` after initialization. It returns an object with two properties: ```board``` is a reference to the newly created ```switchboard``` and ```mixin``` is used to import its definitions to React components.

## ```switchboard```

```switchboard.signal(initialValue, [stream, [fn], ...])``` is used to create a new signal (a mutable value). The first argument is the initial value which will be immediately available. It accepts a variable number of Kefir streams which will be used to update the signal every time they produce a value. If the stream is followed by a function, it will be used to fold the new value into the signal's current value. ```fn``` has the type signature ```(oldValue, newValue) ->``` and returns the updated value for the signal. If ```fn``` is not defined, ```newValue``` is used as is. Returns a Kefir property.

```switchboard.slot(name)``` returns a ```slot``` to which values can be pushed and from which they can be pulled. Typically this is used to pull updates from a component to a signal.

## ```switchboard.mixin```

```component.wireState``` is used by the ```switchboard``` to declare the component state. It should return an object where each key refers to a name in the object's state and value is a Kefir property, typically created by ```signal```. Any time a property changes the component is updated with the new state.

```component.signal(initialValue, [stream, [fn], ...])``` see ```switchboard```

```component.slot(name)``` see ```switchboard```

```component.wire(fn)``` returns a function that is used to push values to a new Kefir stream. ```fn``` is called with a newly created Kefir stream bound as the first argument. The stream can then be merged to a slot to update the value of a signal every time the returned function is called.

```component.propsProperty(name, [name, ...])``` returns a stream of property updates, filtering out any keys that aren't passed as an argument. Should be used over ```this.props``` when defining signals.

```component.stateProperty(name, [name, ...])``` returns a stream of state updates, filtering out any keys that aren't passed as an argument. Useful for reacting to state updates.

```component.isAlive``` Kefir property. Returns true as long as component is mounted, switches to false as soon as it unmounts.

```component.dead``` Kefir stream. Produces a value as soon as the component unmounts. Use with ```stream.takeUntilBy``` to end a stream when component unmounts.

## Kefir additions

`reactive-switchboard` adds some convenience methods to Kefir:

`kefir.Observable.prototype.wire([self], fn)` splits a stream so that it can be directed into multiple slots. Calls `fn` with the stream being split bound to `this`. If `self` is defined, the created stream inherits `state`, `props`, `slot` and `board` properties from it.

`kefir.Observable.prototype.to(slot, [slot, ...])` when `Observable` produces a value, push it to all slots passed as argument. This needs to be called on `wires` for them to have an effect.

`kefir.Observable.prototype.extract()` extracts `event.target.value` from received DOM event.

`kefir.Observable.prototype.cancel()` cancels the received DOM event. Roughly equivalent to `@doAction (e) -> e.preventDefault()`

`kefir.Observable.prototype.set(value)` sets stream's value to constant `value`. Equivalent to `@map -> value`

`kefir.Observable.prototype.not()` inverts produced value.

`kefir.Observable.prototype.rescue(fn)` rescues an emitted error with `fn` and pushes result back into value stream.

`kefir.emitter()` returns a Kefir stream to which values can be pushed. Roughly equivalent to Rx.Subject or Bacon.Bus. Used internally to work with React's imperative API.

```kefir.Observable.prototype.doAction(fn)``` adds a side-effect to stream without adding an extra observer. Useful for working with imperative APIs.

```kefir.Observable.prototype.holdLatestWhile(obs)``` holds latest value until obs produces `false`.
