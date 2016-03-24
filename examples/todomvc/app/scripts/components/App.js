const board = require('reactive-switchboard'),
      Header = require('./Header'),
      Todo = require('./Todo'),
      Footer = require('./Footer')
      ;


module.exports = board.component(
  (ctrl) => ({
    todos: model.todos.signal,
    mode:  model.mode.signal
  }),
  ({ wiredState, wire }) => {
    const {todos, mode} = wiredState,
          filteredTodos = todos.filter((it) =>
            mode == '#/'                           ||
            mode == '#/active'    && !it.completed ||
            mode == '#/completed' &&  it.completed
          ),
          allChecked = todos.filter((it) => !it.completed).length == 0
          ;

    return <section className="todoapp">
      <Header />
      {
        filteredTodos.length == 0 ? undefined : <section className="main">
          <input
            className="toggle-all"
            type="checkbox"
            checked={allChecked}
            autoFocus
            onChange={wire((stream) => {
              stream
                .map((event) => event.target.checked)
                .to(model.todos.toggleAll)
            })}/>

          <ul className="todo-list">
            {filteredTodos.map((it) =>
              <Todo todo={it} key={it.id} />
            )}
          </ul>
        </section>
      }
      {todos.length == 0 ? undefined : <Footer selectedMode={mode} />}
    </section>
  }
)


