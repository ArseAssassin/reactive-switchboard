var board = require('reactive-switchboard')
var kefir = require('kefir')

var Code = require('../Code')

module.exports = board.component(
    ({ slot, signal, stateProperty }) => ({
        mouse: signal({x: 0, y:0, isDown: false},

            kefir.fromEvents(window, 'mousemove'),
            // when mouse moves, update `x` and `y`
            ({isDown}, e) => ({x: e.clientX, y: e.clientY, isDown}),

            kefir.fromEvents(window, 'mousedown').map((it) => true)
            // merge mouseup stream to mousedown
            .merge(kefir.fromEvents(window, 'mouseup').map((it) => false)),
            ({x, y}, isDown) => ({ x, y, isDown })
        )
    }),
    function BasicDemo({ wiredState, wire, slot }) {
        return <div>
            <Code source={JSON.stringify(wiredState.mouse)} expandable={ false } />
        </div>
    }
)
