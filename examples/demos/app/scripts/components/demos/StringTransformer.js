var board = require('reactive-switchboard')

var model = board.create(({ slot, signal }) => ({
    string: {
        signal: signal('Hello world!', slot('string.update')),
        update: slot('string.update')
    }
}))

module.exports = function StringDemo() {
    return <div>
        <Form />
        <StringTransformer fn={(it) => it} />
        <StringTransformer fn={(it) => it.toUpperCase()} />
        <StringTransformer fn={(it) => it.toLowerCase()} />
    </div>
}

var Form = board.component(
    () => ({string: model.string.signal}),
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
    () => ({string: model.string.signal.filter(Boolean)}),
    function StringTransformer({ wiredState, fn }) {
        return <div>{fn(wiredState.string)}</div>
    }
)
