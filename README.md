# reactive-switchboard

Declarative state handling for React.

# What does it look like?

```js
var board = require('reactive-switchboard')

module.exports = board.component(
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
            {' '}
            {/* component receives signals as a prop via `wiredState` */}
            {wiredState.value}
            {' '}
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
# Installation

```
npm install --save reactive-switchboard kefir lodash
```

# Getting started

* [Tutorial](https://medium.com/@ArseAssassin/creating-a-url-router-with-reactive-switchboard-c327538f4518)
* [API Documentation](api.md)
* [Introduction to reactive programming](https://gist.github.com/staltz/868e7e9bc2a7b8c1f754)
* [Demos](examples/demos/)
* [TodoMVC](examples/todomvc/)

