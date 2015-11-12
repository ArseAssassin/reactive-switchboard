react = require 'react'
_ = require 'lodash'

REACT_ELEMENTS = 'a abbr address area article aside audio b base bdi bdo big blockquote body br button canvas caption cite code col colgroup data datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hr html i iframe img input ins kbd keygen label legend li link main map mark menu menuitem meta meter nav noscript object ol optgroup option output p param picture pre progress q rp rt ruby s samp script section select small source span strong style sub summary sup table tbody td textarea tfoot th thead time title tr track u ul var video wbr'

dom = {}

REACT_ELEMENTS.split(' ').forEach (it) ->
  dom[it] = (attr, children...) ->
    react.createElement it, attr, children...

module.exports =
  dom: dom

  h: (selector, props={}, children...) ->
    selectors = selector.split(' ')

    if !children.length
      children = undefined

    while selectors.length
      [name, classes...] = selectors.pop().split '.'
      name ||= 'div'
      elem = dom[name]
      if !elem
        throw new Error "undefined element #{name}"
      current = elem _.merge {}, props,
        children: children
        className: classes.join(' ') + (props?.className and (' ' + props?.className) or '')
      children = current
      props = {}

    current


  defineComponent: (component) ->
    react.createFactory react.createClass component
