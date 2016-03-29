var board = require('reactive-switchboard')

module.exports = board.component(
    ({ slot, signal, stateProperty }) => ({
        value: signal(0,
            slot('inc'),
            (it) => it + 1,

            slot('dec'),
            (it) => it - 1
        )
    }),
    function BasicDemo({ wiredState, wire, slot }) {
        return <div>
            <button
                type="button"
                className="btn btn-danger"
                onClick={wire((it) => it.to(slot('dec')))}>
                -
            </button>
            {' '}
            {wiredState.value}
            {' '}
            <button
                type="button"
                className="btn btn-success"
                onClick={wire((it) => it.to(slot('inc')))}>
                +
            </button>
        </div>
    }
)
