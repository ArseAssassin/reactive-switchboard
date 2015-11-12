_ = require 'lodash'

module.exports = (board) -> defineComponent
  mixins: [board.mixin]
  render: ->
    dom.a _.merge {}, @props,
      onClick: @wire -> @cancel().set(@props.href).to @board.path.navigate
