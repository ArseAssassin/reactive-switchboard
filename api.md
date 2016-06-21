# API Documentation

This is a list of public API methods and properties that reactive-switchboard exposes.

## ```reactive-switchboard```

`reactive-switchboard.component([wireState,] component)` creates a switchboard-enabled React component. `wireState` is a function that receives a `switchboard` object as an argument and returns an object which will be used to wire the component's state.

`wireState` will receive an object as an argument with the following properties:

* ```signal(initialValue, [stream, [fn], ...])``` is used to create a new signal (a mutable value). The first argument is the initial value which will be immediately available. It accepts a variable number of Kefir streams which will be used to update the signal every time they produce a value. If the stream is followed by a function, it will be used to fold the new value into the signal's current value. `fn` has the type signature `(oldValue, newValue) ->` and returns the updated value for the signal. If `fn` is not defined, `newValue` is used as is. Returns a Kefir property.

* ```slot(name)``` returns a ```slot``` to which values can be pushed and from which they can be pulled. Typically this is used to pull updates from a component to a signal.

* `stateProperty` is a Kefir property of the component's wired state

* `propsProperty` is a Kefir property of the props passed to the component

* `switchboard` reference to a switchboard object if one has been injected into this component

`component` will receive the following props:

* `wiredState` latest values of every signal returned from `wireState`. If `wireState` is omitted, this will be `undefined`

* `wire((stream) => ...)` accepts `fn` as an argument. When the returned function is invoked, the value is pushed into `stream`. Used to wire callback values into slots

* `slot(name)` returns a slot with `name`. Can be used to update signals defined in `wireState`

* `switchboard` reference to a switchboard object if one has been injected into this component

```javascript
switchboard.component(
    ({ slot, signal, stateProperty }) => ({
        value: signal(0, // start with 0

            slot('inc'), // when the `inc` slot receives a value
            (it) => it + 1, // increment counter by one

            slot('dec'), // when the `dec` slot receives a value
            (it) => it - 1 // decrement counter by one
        )
    }),
    function BasicDemo({ wiredState, wire, slot }) {
        return <div>
            <button
                type="button"
                className="btn btn-danger"
                /* when `onClick` is called, push the event to slot `dec` */
                onClick={wire((it) => it.to(slot('dec')))}>
                -
            </button>
            {/* component receives signals as a prop via `wiredState` */}
            {wiredState.value}
            <button
                type="button"
                className="btn btn-success"
                /* when `onClick` is called, push the event to slot `inc` */
                onClick={wire((it) => it.to(slot('inc')))}>
                +
            </button>
        </div>
    }
)
```


`reactive-switchboard.create(({ slot, signal }) => ...)` is used to construct a new switchboard. Accepts a function as an argument. The function is invoked with an object with the following properties:

```signal(initialValue, [stream, [fn], ...])``` is used to create a new signal (a mutable value). The first argument is the initial value which will be immediately available. It accepts a variable number of Kefir streams which will be used to update the signal every time they produce a value. If the stream is followed by a function, it will be used to fold the new value into the signal's current value. `fn` has the type signature `(oldValue, newValue) ->` and returns the updated value for the signal. If `fn` is not defined, `newValue` is used as is. Returns a Kefir property.

```slot(name)``` returns a ```slot``` to which values can be pushed and from which they can be pulled. Typically this is used to pull updates from a component to a signal.

```javascript
switchboard.create(({ slot, signal }) => ({
    counter: signal(
        0,

        slot('increment'),
        (it) => it + 1
    )
}))
```

`switchboard.inject(component)` injects the switchboard object into the `component`. Makes `switchboard` available in the component's `wireState` and props.

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
