# reactive-switchboard

Declarative state handling for React.

# What does it look like?

```coffeescript

# a switchboard manages application state
switchboard = require('reactive-switchboard').create ->

  # switchboard's properties can be accessed by components
  @currentUser =
    # signals are mutable values
    signal: @signal(
      {} # we define the initial value
      
      # we fold over kefir streams to mutate the initial value
      kefir.fromPromise $.ajax '/api/session'
      .map (session) -> session.user
      
      # a function is used to fold the new value over the old value
      (oldUser, newUser) ->
        newUser
    )

Auth = defineComponent
  # created switchboard exposes a mixin to access its values
  mixins: [switchboard.mixin] 
  
  # wireState declaration replaces imperative setState calls
  wireState: ->
    # state is declared using signals
    user: @board.currentUser.signal
    
  render: ->
    # state is used to access signal values
    if @state.user._id
      @props.children
    else
      null
``` 

# Installation

```
npm install --save reactive-switchboard kefir lodash
```

# API Documentation

This is a list of public API methods and properties that reactive-switchboard exposes.

## ```reactive-switchboard```

```reactive-switchboard.create(fn)``` is used to construct a new switchboard. It accepts a single function as an argument which is called with the created ```switchboard``` bound to ```this``` after initialization. It returns an object with two properties: ```board``` is a reference to the newly created ```switchboard``` and ```mixin``` is used to import its definitions to React components.

## ```switchboard```

```switchboard.signal(initialValue, [stream, [fn], ...])``` is used to create a new signal (a mutable value). The first argument is the initial value which will be immediately available. It accepts a variable number of Kefir streams which will be used to update the signal every time they produce a value. If the stream is followed by a function, it will be used to fold the new value into the signal's current value. ```fn``` has the type signature ```(oldValue, newValue) ->``` and returns the updated value for the signal. If ```fn``` is not defined, ```newValue``` is used as is. Returns a Kefir property.

```switchboard.slot(name)``` returns a ```slot``` to which values can be pushed and from which they can be pulled. Typically this is used to pull updates from a component to a signal.

## ```switchboard.mixin```

```switchboard.wireState``` is used by the ```switchboard``` to declare the component state. It should return an object where each key refers to a name in the object's state and value is a Kefir property, typically created by ```signal```. Any time a property changes the component is updated with the new state.

```switchboard.signal(initialValue, [stream, [fn], ...])``` see ```switchboard```

```switchboard.slot(name)``` see ```switchboard```

```switchboard.wire(fn)``` returns a function that is used to push values to a new Kefir stream. ```fn``` is called with a newly created Kefir stream bound to ```this```. The stream can then be merged to a slot to update the value of a signal every time the returned function is called.

```switchboard.propsProperty(name, [name, ...])``` returns a stream of property updates 
