var _ = require('lodash')
var kefir = require('kefir')

var Route = require('route-parser')

var React = require('react');
var ReactDOM = require('react-dom');
var dom = React.DOM;
var {defineComponent} = require('reactive-switchboard/lib/contrib/utils');

var Board = require('reactive-switchboard').create(function() {
  this.path = {
    signal: this.signal(
      document.location.pathname,

      this.slot('path.update')
      .doAction((path) => window.history.pushState(null, null, path)),

      kefir.fromEvents(window, 'popstate')
      .map(() => document.location.pathname)
    ),
    update: this.slot('path.update')
  }
})

var Link = defineComponent({
  mixins: [Board.mixin],
  render: function() {
    var self = this;
    return dom.a(
      _.merge({}, this.props, {
        onClick: this.wire((stream) =>
          stream.doAction((event) => event.preventDefault())
          .map(() => self.props.href)
          .to(self.board.path.update)
        )
      })
    )
  }
})

var Router = defineComponent({
  mixins: [Board.mixin],
  wireState: function() {
    return {
      path: this.board.path.signal
    }
  },
  getDefaultProps: function() {
    return {
      notFound: () => dom.h1(null, '404')
    };
  },
  render: function() {
    return (
      _.find(this.props.children.map((child) => child(this.state.path))) ||
      this.props.notFound()
    );
  }
})

var makeRoute = (path, render) => {
  var route = new Route(path)
  return (path) => {
    var result = route.match(path)
    if (result) {
      return render(result)
    }
  }
}

var App = React.createClass({
  render: function() {
    return dom.div(null,
      Link({href: '/'}, 'Home'),
      ' ',
      Link({href: '/about-us'}, 'About us'),
      Router(null,
        makeRoute(
          '/',
          () => dom.div(null, 'Front page')
        ),
        makeRoute(
          '/about-us',
          () => dom.div(null, 'About us')
        ),
        makeRoute(
          '/blog/:postId',
          (params) => dom.div(null, `Blog post ${params.postId}`)
        )
      )
    )
  }

})

ReactDOM.render(React.createElement(App), document.getElementById('host'))
