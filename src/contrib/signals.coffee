kefir = require 'kefir'

module.exports =
  path: (board) ->
    signal: board.signal(
      document.location.pathname

      kefir.fromEvents(window, 'popstate')
      -> document.location.pathname

      board.slot('path.navigate')
      .filter (it) -> window.location.pathname != it
      .doAction (path) ->
        window.history.pushState null, null, path
    )
    navigate: board.slot('path.navigate')
