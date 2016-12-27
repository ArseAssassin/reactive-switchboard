# Reactive Switchboard performance

Reactive Switchboard is fairly performant out-of-the-box. By default Switchboard component rerenders every time it receives a new value from its wireState function or its parent updates. All Switchboard updates are debounced by a single frame. This ensures that **when a single value affects multiple values inside a component or a parent's update cascades to a child the component is rendered only once.** This also means that after a stream receives a new value **there's a single frame difference between the update and component rerendering.**

## Optimizing rendering performance

The best way to optimize render performance using Reactive Switchboard is to avoid unnecessary updates. The best way to do that is to make sure that your `wireState` function emits new values only when they update. You can use [kefir.skipDuplicates([fn])](https://rpominov.github.io/kefir/#skip-duplicates) to skip duplicate values from your streams. For properties that update more frequently than they need to be rendered, you can use [kefir.debounce(ms, [options])](https://rpominov.github.io/kefir/#debounce) to make sure they rerender only after `ms` milliseconds without updates.

Because any value emitted from a component's `wireState` rerenders the whole component, the best way to avoid unnecessary rendering is to split large components into small components. That is to say that instead of writing a single component that rerenders any time the application's state changes, write a number of components that update only a small part of the DOM.

### Optimizing props

By default Switchboard component updates any time it receives new props - that is to say any time its parent rerenders. To optimize updates in these cases you can return a stream called `updateBy` from `wireState`. If `updateBy` is `undefined` it will fall back to `propsProperty` - the component will update any time it receives new props. If `updateBy` is defined, the component will update any time the stream produces a value.

In order to produce a component that works similar to [React.PureComponent](https://facebook.github.io/react/docs/react-api.html#react.purecomponent), you can write something akin to this:

```js
switchboard.component(
    ({ propsProperty }) => ({
        // Ramda equality comparison (http://ramdajs.com/)
        updateBy: propsProperty.skipDuplicates(R.equals)
    })
)
```

## Avoiding memory leaks

Any Kefir property you return from a component's `wireState` will only be subscribed to as long as the component is mounted. In some cases it can be necessary to cause side-effects as a result of a component's state. In these cases you should make use of `isAlive` property passed to `wireState`. You can call `stream.takeUntilBy(isAlive.map((it) => !it)).onValue(fn)` on a stream to make sure the listener is removed when the component unmounts.

Sometimes it may be necessary to create throwaway Switchboard models. To make sure that the model gets properly garbage collected, you can return `endBy` from a `switchboard.model(fn)` - the model will be killed (slots will stop emitting, signals will be garbage collected as soon as all listeners are removed) when the `endBy` stream emits a value.
