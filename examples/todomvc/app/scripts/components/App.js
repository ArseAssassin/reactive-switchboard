const Header = require('./Header'),
      Todo = require('./Todo'),
      Footer = require('./Footer')
      ;


module.exports = React.createClass({
  mixins: [todos.mixin],
  wireState: function() {
    return {
      todos:        this.board.todos.signal,
      mode:         this.board.mode.signal
    }
  },
  render: function() {
    const {todos, mode} = this.state,
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
            onChange={this.wire((stream) => {
              stream.map((event) => event.target.checked)
              .to(this.board.todos.toggleAll)
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
})


