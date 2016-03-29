var board = require('reactive-switchboard')

module.exports = board.component(
    ({ slot, signal, stateProperty }) => ({
        interval: signal(
            1000,
            slot('interval.update')
            .map(Number)
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
            propsProperty
            .map((it) => it.interval)
            .filter((it) => it >= 100)
            .flatMapLatest((interval) => kefir.withInterval(interval, (it) => it.emit())),
            (it) => it + 1
        )
    }),
    ({ wiredState, interval }) => <div>
        {interval < 100 && <div>Interval too small, use value >100ms</div>}
        Counter: {wiredState.value}
    </div>
)
