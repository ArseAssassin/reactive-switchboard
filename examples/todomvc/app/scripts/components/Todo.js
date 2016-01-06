const KEY_ENTER = 13;

module.exports = React.createClass({
  mixins: [todos.mixin],
  wireState: function() {
    return {
      editing: this.signal(
        false,
        this.slot('editing.start').set(true),
        this.slot('editing.stop').set(false)
      ),
      updatedTodo: this.signal(
        undefined,
        this.slot('todo.update'),
        this.propsProperty('todo').set(undefined)
      )
    }
  },
  render: function() {
    const {todo} = this.props,
          {editing, updatedTodo} = this.state,
          {board, slot} = this,
          stopEdit = (stream) =>
            stream
            .map((it) => _.merge({}, todo, {label: updatedTodo}))
            .to(board.todos.update, slot('editing.stop'))

    return <li
      className={todo.completed && 'completed' || editing && 'editing' || ''}
      onDoubleClick={this.wire((stream) =>
        stream
        .filter(() => !todo.completed)
        .to(this.slot('editing.start'))
      )}
      >
      <div className="view">
        <input
          className="toggle"
          type="checkbox"
          checked={todo.completed}
          onChange={this.wire((stream) =>
            stream.set(
              _.merge({}, todo, {completed: !todo.completed})
            ).to(this.board.todos.update)
          )}/>

        <label>{todo.title}</label>
        <button
          className="destroy"
          onClick={this.wire((stream) =>
            stream.set(todo).to(this.board.todos.remove)
          )}/>
      </div>
      {!editing ? undefined :
        <input
          className="edit"
          value={updatedTodo != undefined && updatedTodo || todo.title}
          autoFocus
          onKeyDown={this.wire((stream) =>
            stream
            .filter((event) => event.keyCode == KEY_ENTER)
            .wire(stopEdit)
          )}
          onBlur={this.wire(stopEdit)}
          onChange={this.wire((stream) => stream.extract().to(this.slot('todo.update')))}/>}
    </li>
  }
})
