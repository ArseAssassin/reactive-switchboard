var Firebase = require('firebase')
var board = require('reactive-switchboard')
var _ = require('lodash')

var myDataRef = new Firebase('https://brilliant-fire-3795.firebaseio.com/chat');


module.exports = board.component(
    ({ slot, signal }) => ({
        nameSet: signal(false, slot('name.submit').set(true)),
        name: signal('guest #' + Math.random().toString().split('.')[1].slice(0, 4), slot('name.update')),
        message: signal('', slot('message.update')),
        messages: signal([],
            kefir.fromEvents(myDataRef.limitToLast(10), 'value').map((it) => it.val())
        )
    }),
    function FirebaseDemo({ wiredState, wire, slot }) {
        const {nameSet, name, message, messages} = wiredState

        return <div>
            <form onSubmit={(e) => {
                e.preventDefault()
                if (nameSet) {
                    // values can be emitted by slots when working with imperative APIs
                    slot('message.update').emit('')
                    myDataRef.push({ date: new Date().toUTCString(), name, message })
                } else if (name) {
                    slot('name.submit').emit(true)
                }}}>

                <input
                    className="form-control"
                    placeholder={nameSet ? 'Your message' : 'Your name'}
                    value={nameSet ? message : name}
                    onChange={wire((it) => it.extract().to(slot(
                        nameSet ? 'message.update' : 'name.update')))} />

                {_.map(messages, ((it, idx) =>
                    <div key={idx}>
                        <strong>[{it.date}] {it.name} says:</strong> {it.message}
                    </div>
                ))}

            </form>
        </div>
    }
)
