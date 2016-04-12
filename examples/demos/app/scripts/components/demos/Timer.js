var board = require('reactive-switchboard')

module.exports = board.component(
    ({ slot, signal, stateProperty }) => ({
        interval: signal(
            1000,

            slot('interval.update')
            // parse as number
            .map(Number)
            // filter out NaN
            .filter(isFinite)
        )
    }),
    function TimerDemo({ wiredState, wire, slot }) {
        return <div>
            <label>
                Interval
                <input
                    className="form-control"
                    type="number"
                    value={wiredState.interval}
                    onChange={wire((it) => it.extract().to(slot('interval.update')))} />
            </label>
            <Timer {...wiredState} />
        </div>
    }
)

var Timer = board.component(
    ({ slot, signal, propsProperty }) => ({
        value: signal(0,

            // when receiving new props
            propsProperty
            // get interval
            .map((it) => it.interval)
            // make sure it's > 100ms
            .filter((it) => it >= 100)
            // create a new timer to increment counter
            .flatMapLatest((interval) => kefir.withInterval(interval, (it) => it.emit())),

            (it) => it + 1
        )
    }),
    ({ wiredState, interval }) => <div>
        {interval < 100 && <div>Interval too small, use value >100ms</div>}
        Counter: {wiredState.value}
    </div>
)
