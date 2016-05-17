var board = require('reactive-switchboard')

module.exports = board.component(
    ({ slot, signal, stateProperty }) => ({
        counter: signal(
            0,

            kefir.interval(1000)
                .filterBy(stateProperty.map((it) => !it.paused)),
            (it) => it + 1,

            slot('counter.reset'),
            () => 0
        ),
        paused: signal(
            false,

            slot('paused.toggle'),
            (it) => !it
        )
    }),
    function TimerDemo({ wiredState: { counter, paused }, wire, slot }) {
        return <div>
            <p>{ counter } seconds have passed</p>
            <button
                onClick={wire((it) => it.to(slot('paused.toggle')))}
                className="btn btn-default">
                { paused ? 'Start' : 'Pause' }
            </button>
            { ' ' }
            <button
                onClick={wire((it) => it.to(slot('counter.reset')))}
                className="btn btn-default">
                Reset
            </button>
        </div>
    }
)

