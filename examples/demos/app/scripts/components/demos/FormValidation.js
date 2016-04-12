var board = require('reactive-switchboard')

module.exports = board.component(
    ({ slot, signal }) => ({
        date: signal('', slot('date.update')),
        errors: signal(
            ['Date is required'],

            slot('date.update')
            .debounce(500) // update only when no input in 500ms
            .map((it) => {
                if (it === '') {
                    return ['Date is required']
                } else {
                    var date = new Date(it)

                    if (isNaN(date)) {
                        return ['Not a valid date']
                    } else if (date.getFullYear() < 2015) {
                        return ['Date needs to be newer than 2014']
                    } else if (date.getFullYear() > new Date().getFullYear()) {
                        return ["Date must not be in a future year"]
                    } else {
                        return [];
                    }
                }
            })
        ),
    }),
    function BasicDemo({ wiredState: { date, errors }, wire, slot }) {
        return <div>
            <p>
                <input
                    className="input form-control"
                    value={date}
                    placeholder="Date e.g. 2016-04-12"
                    /* `extract` extracts the text value from the `change` event */
                    onChange={wire((it) => it.extract().to(slot('date.update')))} />
            </p>

            { errors.map((it) => <p className="text-danger">{it}</p>) }

            <p>
                <button
                    type="button"
                    className="btn btn-success"
                    disabled={errors.length > 0}>

                    Submit

                </button>
            </p>
        </div>
    }
)
