var board = require('reactive-switchboard')

// create a switchboard with signals that can be shared by components
var model = board.create(({ slot, signal }) => ({
    string: {
        signal: signal('Hello world!', slot('string.update')),
        update: slot('string.update')
    }
}))

module.exports = function StringDemo() {
    return model.inject(<div>
        <Form />
        <StringTransformer fn={(it) => it} />
        <StringTransformer fn={(it) => it.toUpperCase()} />
        <StringTransformer fn={(it) => it.toLowerCase()} />
    </div>)
}

var Form = board.component(
    ({ switchboard }) => ({string: switchboard.string.signal}),
    function Form({ wire, wiredState }) {
        return <label>
            <input
                type="text"
                placeholder="String to transform"
                className="form-control"
                value={wiredState.string}
                onChange={wire((it) => it.extract().to(model.string.update))} />
        </label>
    }
)

var StringTransformer = board.component(
    ({ switchboard }) => ({string: switchboard.string.signal.filter(Boolean)}),
    function StringTransformer({ wiredState, fn }) {
        return <div>{fn(wiredState.string)}</div>
    }
)
