const KEY_ENTER = 13;

module.exports = React.createClass({
  mixins: [todos.mixin],
  wireState: function() {
    return {
      newTodo: this.signal('',
        this.slot('todo.update'),
        this.slot('todo.add').set('')
      )
    }
  },
  render: function() {
    const {newTodo} = this.state;

    return <header className="header">
      <h1>todos</h1>
      <input
        className="new-todo"
        placeholder="What needs to be done?"
        value={newTodo}
        onKeyDown={this.wire((stream) => {
          stream
          .filter((event) => event.keyCode == KEY_ENTER)
          .set(newTodo)
          .to(this.slot('todo.add'), this.board.todos.add)
        })}
        onChange={this.wire((stream) => stream.extract().to(this.slot('todo.update')))}
        autofocus/>
    </header>
  }
})
