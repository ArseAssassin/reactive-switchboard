var board = require('reactive-switchboard')
var reqwest = require('reqwest')
var kefir = require('kefir')

module.exports = board.component(
    ({ slot, signal, stateProperty }) => ({
        type: signal(
            'repositories',
            slot('type.update')
        ),
        query: signal(
            'reactive-switchboard',
            slot('query.update')
        ),
        results: signal(
            {loading: true, items: [], error: undefined},

            stateProperty
            .filter((it) => it.query.length > 2)
            .skipDuplicates((a, b) => a.query === b.query && a.type === b.type)
            .debounce(300)
            .flatMapLatest(({ query, type }) =>
                kefir
                .constant({loading: true})
                .merge(
                    kefir.fromPromise(reqwest({
                        url: 'https://api.github.com/search/' + type,
                        data: {
                            q: query,
                            limit: 10
                        }
                    })).rescue((it) => ({error: it.status}))
                )
            ),
            (current, response) => response.loading
                ? {loading: true,  items: current.items,        error: undefined}
                : {loading: false, items: response.items || [], error: response.error}
        )
    }),
    function RestDemo({ wiredState, wire, slot }) {
        const {results, query, type} = wiredState;

        return <div>
            <div className="nav nav-tabs">
                {'Repositories Users'.split(' ').map((tab) =>
                    <li className={tab.toLowerCase() == type && 'active'}
                        key={tab}>
                        <a
                            href={'#' + tab}
                            onClick={wire((it) =>
                                it
                                .cancel()
                                .set(tab.toLowerCase())
                                .to(slot('type.update'))
                            )}>
                            {tab}
                        </a>
                    </li>
                )}
            </div>


            <p>
                <input
                    type="text"
                    className="input form-control"
                    value={query}
                    placeholder="Query e.g. reactive-switchboard"
                    onChange={wire((it) => it.extract().to(slot('query.update')))}
                    />
            </p>

            { results.loading && <div style={{textAlign: 'center'}}>
                <img src="http://cdnjs.cloudflare.com/ajax/libs/semantic-ui/0.16.1/images/loader-large.gif"/>
            </div>}
            { results.error === 403
                ? <p>Status error 403: too many requests</p>
                : results.items.length == 0 &&
                    !results.loading &&
                    'No results'
            }

            {
                results.items.map((it) => <div key={it.id}>
                    {
                        <a
                            href={it.html_url}
                            style={{
                                display: 'block'
                            }}
                            target="_blank">
                            <div className="row">
                                <div className="col-xs-3">
                                    <img
                                        style={{maxWidth: '100%'}}
                                        src={it.avatar_url || it.owner.avatar_url} />
                                </div>

                                <div className="col-xs-9">
                                    <h1>{it.name || it.login}</h1>
                                    { it.owner && <author>by {it.owner.login}</author> }
                                </div>
                            </div>
                        </a>
                    }


                </div>)
            }
        </div>
    }
)
