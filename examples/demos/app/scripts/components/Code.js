var dom = require('react-dom')

var board = require('reactive-switchboard')

module.exports = board.component(({ signal, slot }) => ({
        shown: signal(
            false,

            slot('toggle'),
            (current) => !current
        )
    }),
    React.createClass({
        displayName: 'Code',

        getDefaultProps() {
            return {
                expandable: true
            }
        },

        render() {
            var {wiredState: {shown}, slot, wire, expandable} = this.props;

            return <div style={{marginTop: '20px'}}>
                <hr/>

                {
                    expandable && <p>
                        <button
                            type="button"
                            onClick={wire((it) => it.to(slot('toggle')))}
                            className="btn btn-default">
                            {shown ? 'Hide source' : 'Expand source'}
                        </button>
                    </p>
                }

                <pre
                    className="jsx"
                    style={shown || !expandable ? {} : {maxHeight: '40px'}}
                    ref="pre">

                    <code>{this.props.source}</code>

                </pre>
            </div>
        },

        componentDidUpdate() {
            if (this.refs.pre) {
                hljs.highlightBlock(dom.findDOMNode(this.refs.pre));
            }
        }
    })
)
