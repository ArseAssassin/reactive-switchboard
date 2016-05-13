var fs = require('fs')

var board = require('reactive-switchboard');

var RestDemo = require('./demos/RestDemo');
var BasicDemo = require('./demos/BasicDemo');
var Timer = require('./demos/Timer');
var StringTransformer = require('./demos/StringTransformer');
var FirebaseDemo = require('./demos/FirebaseDemo');
var MouseTracker = require('./demos/MouseTracker')
var FormValidation = require('./demos/FormValidation')
var Combinators = require('./demos/Combinators')

var Code = require('./Code')

var makeDemo = (url, title, component, description) => ({
    url, title, component, description,
    source: sources[url]
})

var sources = {
    '/basic': fs.readFileSync(__dirname + '/demos/BasicDemo.js', 'utf-8'),
    '/form-validation': fs.readFileSync(__dirname + '/demos/FormValidation.js', 'utf-8'),
    '/string': fs.readFileSync(__dirname + '/demos/StringTransformer.js', 'utf-8'),
    '/mouse': fs.readFileSync(__dirname + '/demos/MouseTracker.js', 'utf-8'),
    '/timer': fs.readFileSync(__dirname + '/demos/Timer.js', 'utf-8'),
    '/rest': fs.readFileSync(__dirname + '/demos/RestDemo.js', 'utf-8'),
    '/firebase': fs.readFileSync(__dirname + '/demos/FirebaseDemo.js', 'utf-8'),
    '/combinators': fs.readFileSync(__dirname + '/demos/Combinators.js', 'utf-8'),
}

var demos = [
    makeDemo('/basic', 'Basic signal handling', <BasicDemo />, <p>
        This demonstrates the basics of reactive-switchboard by creating a simple counter that can be incremented and decremented using streams. We define a single component with a signal and use the slots <code>inc</code> and <code>dec</code> to change its value.
        </p>),
    makeDemo('/form-validation', 'Form validation', <FormValidation />, <p>
        This demonstrates working with time using Kefir streams. Form validation is debounced for 500ms to allow user to stop typing before errors are updated.
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
    makeDemo('/combinators', 'Combinators', <Combinators />, <div>
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
    function Link({ href, children, wire, switchboard }) {
        return <a href={`#${href}`}
            onClick={wire((it) =>
                it.cancel()
                .set(href)
                .to(switchboard.updateUrl)
            )}
            >
            {children}
        </a>
    }
)

var Route = board.component(
    ({ switchboard }) => ({path: switchboard.url}),
    function Route({ href, children, wiredState }) {
        return <div>
            {wiredState.path === '#' + href ? children : null}
        </div>
    }
)


module.exports = () => model.inject(<div className="container" style={{maxWidth: '1024px'}}>
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
            {demos.map(({url, title, component, description, source}) =>
                <Route key={url} href={url}>
                    <h4 key="title">{title}</h4>
                    <div key="description">{description}</div>
                    <div key="demo">{component}</div>
                    <Code source={source} />
                </Route>
            )}

        </div>
    </div>
</div>)
