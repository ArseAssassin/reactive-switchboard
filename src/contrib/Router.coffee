Route = require 'route-parser'

{defineComponent, dom} = require './utils'

module.exports = (board) ->
  defineComponent
    mixins: [board.mixin]
    wireState: ->
      path: @board.path.signal

    getDefaultProps: ->
      error: -> dom.h1 null, '404'

    render: ->
      for child in [].concat @props.children
        if !child
          continue
        response = child @state.path
        if response
          return response

      @props.error()


module.exports.route = (path, respond) ->
  route = new Route path
  (currentPath) ->
    result = route.match currentPath
    if result
      respond result
