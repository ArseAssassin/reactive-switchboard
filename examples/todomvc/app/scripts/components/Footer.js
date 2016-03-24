const board = require('reactive-switchboard');

module.exports = board.component(
  () => ({
    todos: todos.todos.signal
  }),
  ({wiredState, wire, selectedMode}) => {
    const {todos} = wiredState,
          left = todos.filter((it) => !it.completed).length,
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
          onClick={wire((stream) => {
            stream.to(todos.todos.clear)
          })}>Clear completed</button>
      }
    </footer>

  }
)
