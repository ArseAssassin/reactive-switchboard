var _ = require('lodash')
var kefir = require('kefir')

var Route = require('route-parser')

var React = require('react');
var ReactDOM = require('react-dom');
var dom = React.DOM;

var board = require('reactive-switchboard');

var Board = board.create(ctrl => ({
  path: {
    signal: ctrl.signal(
      document.location.pathname,

      ctrl.slot('path.update')
        .doAction(path => window.history.pushState(null, null, path)),

      kefir.fromEvents(window, 'popstate')
        .map(() => document.location.pathname)
    ),
    update: ctrl.slot('path.update')
  }
}))

var Link = React.createFactory(board.component(
  undefined,
  props => dom.a(
    _.merge({}, props, {
      onClick: props.wire((stream) =>
        stream.doAction((event) => event.preventDefault())
          .map(() => props.href)
          .to(Board.path.update)
      )
    })
  )
))

var Router = React.createFactory(board.component(
  () => ({
    path: Board.path.signal
  }),
  ({ children, notFound = () => dom.h1(null, '404'), wiredState }) =>
    _.find(children.map(child => child(wiredState.path))) || notFound()
))

var makeRoute = (path, render) => {
  var route = new Route(path)
  return path => {
    var result = route.match(path)
    return result && render(result)
  }
}

var App = () =>
  dom.div(null,
    Link({href: '/'}, 'Home'),
    ' ',
    Link({href: '/blog/2'}, 'Blog'),
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
        params => dom.div(null, `Blog post ${params.postId}`)
      )
    )
  )

ReactDOM.render(React.createElement(App), document.getElementById('host'))
