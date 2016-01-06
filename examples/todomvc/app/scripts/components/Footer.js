module.exports = React.createClass({
  mixins: [todos.mixin],
  wireState: function() {
    return {
      todos: this.board.todos.signal
    }
  },
  render: function() {
    const {todos} = this.state,
          left = todos.filter((it) => !it.completed).length,
          {selectedMode} = this.props,
          makeFilter = (label, mode, href) => <li>
            <a
              className={selectedMode == href && 'selected'}
              href={href}>
              {label}
            </a>
          </li>

    return <footer className="footer">
      <span className="todo-count"><strong>{left}</strong> item{left != 1 && 's'} left</span>


      <ul className="filters">
        {makeFilter('All',        'all',       '#/')}
        {makeFilter('Active',     'active',    '#/active')}
        {makeFilter('Completed',  'completed', '#/completed')}
      </ul>

      {left == todos.length ? undefined :
        <button className="clear-completed"
          onClick={this.wire((stream) => {
            stream.to(this.board.todos.clear)
          })}>Clear completed</button>
      }
    </footer>

  }
})
