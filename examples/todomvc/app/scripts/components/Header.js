var board = require('reactive-switchboard');

const KEY_ENTER = 13;

module.exports = board.component(
  (ctrl) => ({
    newTodo: ctrl.signal('',
      ctrl.slot('todo.update'),
      ctrl.slot('todo.add').set('')
    )
  }),
  ({ wire, slot, wiredState }) => {
    const {newTodo} = wiredState;

    return <header className="header">
      <h1>todos</h1>
      <input
        className="new-todo"
        placeholder="What needs to be done?"
        value={newTodo}
        onKeyDown={wire((stream) => {
          stream
          .filter((event) => event.keyCode == KEY_ENTER)
          .set(newTodo)
          .to(slot('todo.add'), todos.todos.add)
        })}
        onChange={wire((stream) => stream.extract().to(slot('todo.update')))}
        autofocus/>
    </header>
  }
)
