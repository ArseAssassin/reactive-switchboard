var board = require('reactive-switchboard');

var RestDemo = require('./demos/RestDemo');
var BasicDemo = require('./demos/BasicDemo');
var Timer = require('./demos/Timer');
var StringTransformer = require('./demos/StringTransformer');
var FirebaseDemo = require('./demos/FirebaseDemo');
var MouseTracker = require('./demos/MouseTracker')

var makeDemo = (url, title, component, description) => ({
    url, title, component, description
})

var demos = [
    makeDemo('/basic', 'Basic signal handling', <BasicDemo />, <p>
        This demonstrates the basics of reactive-switchboard by creating a simple counter that can be incremented and decremented using streams. We define a single component with a signal and use the slots <code>inc</code> and <code>dec</code> to change its value.
        </p>),
    makeDemo('/string', 'String transformer', <StringTransformer/>, <p>
        This demonstrates how to pass data between components without using props. <code>string</code> is defined in an external model that can be used to wire state to any component.
        </p>),
    makeDemo('/mouse', 'Mouse tracker', <MouseTracker />, <div>
        <p>This demo combines streams from several DOM events to keep track of the mouse state.</p>
    </div>),
    makeDemo('/timer', 'Timer', <Timer />, <div>
        <p>Play around with the value of <code>interval</code> and see how the counter reacts.</p>

        <p>This is a simple timer component that demonstrates using <code>propsProperty</code> for reacting to changes in component props. Our parent component defines the signal <code>interval</code> that is passed to the child component - the child component then validates the value and uses it to create a new timer that is used to increment the counter.</p>
    </div>),
    makeDemo('/rest', 'GitHub search', <RestDemo />, <p>
        This demonstrates how to use <code>stateProperty</code> to react to changes in the component state. We have two signals <code>query</code> and <code>type</code> that are used to query a REST API and asynchronously update the results.
    </p>),
    makeDemo('/firebase', 'Chat', <FirebaseDemo />, <p>
        This demonstrates working with external APIs. Component listens to <code>value</code> events from Firebase and updates the chat log with the latest messages.
    </p>),
]

var model = board.create(({ signal, slot }) => ({
    url: signal(
        document.location.hash || '#/',
        slot('url.update')
        .map((it) => '#' + it)
        .doAction((it) => {
            document.location.hash = it;
        })
    ),
    updateUrl: slot('url.update')
}));

var Link = board.component(
    function Link({ href, children, wire }) {
        return <a href={`#${href}`}
            onClick={wire((it) =>
                it.cancel()
                .set(href)
                .to(model.updateUrl)
            )}
            >
            {children}
        </a>
    }
)

var Route = board.component(
    () => ({path: model.url}),
    function Route({ href, children, wiredState }) {
        return <div>
            {wiredState.path === '#' + href ? children : null}
        </div>
    }
)


module.exports = () => <div className="container" style={{maxWidth: '600px'}}>
    <div className="panel panel-default">
        <div className="panel-heading">
            <h1><Link href="/">Reactive Switchboard Examples</Link></h1>
        </div>

        <div className="panel-body">
            <h2>Contents</h2>

            <ul>
                {demos.map(({url, title}) =>
                    <li key={url}><Link href={url}>{title}</Link></li>
                )}
            </ul>

            <Route href="/">
                <p>This is a collection of examples for reactive-switchboard.</p>
            </Route>
            {demos.map(({url, title, component, description}) =>
                <Route key={url} href={url}>
                    <h4 key="title">{title}</h4>
                    <div key="description">{description}</div>
                    <div key="demo">{component}</div>
                </Route>
            )}

        </div>
    </div>
</div>