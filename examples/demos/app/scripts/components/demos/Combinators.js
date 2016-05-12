var _ = require('lodash')
var board = require('reactive-switchboard')

var toggle = (initialValue = false) => ({ signal, slot }) => ({
        switch: signal(false,
            slot('switch.toggle'),
            (bool) => !bool
        )
    }),
    ToggleButton = board.component(toggle(), ({ slot, wiredState, wire, children }) => (
        <a className={ 'btn ' + (wiredState.switch ? 'btn-primary' : 'btn-default') }
            href="#toggle"
            onClick={ wire((stream) => stream.cancel().to(slot('switch.toggle'))) }>
            { children }
        </a>
    )),
    Checkbox = board.component(toggle(), ({ slot, wiredState, wire, children }) => (
        <label>
            <input
                onChange={ wire((it) => it.to(slot('switch.toggle'))) }
                type="checkbox"
                checked={ wiredState.switch } /> { children }
        </label>
    )),
    Form = board.component(board.combine(
        toggle(),
        ({ signal, slot }) => ({ value:
            signal({
                email: 'example@example.com',
                optIn: false
            }, slot('value.update'), (oldValue, newValue) => _.assign({}, oldValue, newValue))
        })
    ), ({ slot, wiredState, wire, children }) => <div>
        <h2>Form</h2>
        { !wiredState.switch
            ? <div>
                <p>
                    <strong>Email: </strong> { wiredState.value.email }
                </p>
                <p>
                    <strong>We can send you spam: </strong> { wiredState.value.optIn ? 'Yes' : 'No' }
                </p>
            </div>
            : <form>
                <p>
                    <input
                        value={ wiredState.value.email }
                        onChange={ wire((it) =>
                            it.extract()
                                .map((value) => ({ email: value }))
                                .to(slot('value.update')))
                        } />
                </p>

                <p>
                    <label>
                        <input
                            type="checkbox"
                            checked={ wiredState.value.optIn }
                            onChange={ wire((it) =>
                                it.map((e) => ({ optIn: e.target.checked }))
                                    .to(slot('value.update')))
                            } /> We can send you spam
                    </label>
                </p>
            </form> }

            <a href="#toggle-form"
                onClick={ wire((it) => it.cancel().to(slot('switch.toggle'))) }>

                Toggle edit form
            </a>
        </div>
    )


module.exports = () => (
    <div>
        <p><ToggleButton>
            Toggle
        </ToggleButton></p>

        <p><Checkbox>
            Checked
        </Checkbox></p>

        <Form>
        </Form>
    </div>
)
