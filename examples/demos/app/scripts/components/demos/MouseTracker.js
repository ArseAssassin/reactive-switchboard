var board = require('reactive-switchboard')
var kefir = require('kefir')

module.exports = board.component(
    ({ slot, signal, stateProperty }) => ({
        mouse: signal({x: 0, y:0, isDown: false},
            kefir.fromEvents(window, 'mousemove'),
            ({isDown}, e) => ({x: e.clientX, y: e.clientY, isDown}),

            kefir.fromEvents(window, 'mousedown').map((it) => true)
            .merge(kefir.fromEvents(window, 'mouseup').map((it) => false)),
            ({x, y}, isDown) => ({ x, y, isDown })
        )
    }),
    function BasicDemo({ wiredState, wire, slot }) {
        return <div>
            <code>{JSON.stringify(wiredState.mouse)}</code>
        </div>
    }
)
