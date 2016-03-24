const KEY_ENTER = 13;

const board = require('reactive-switchboard');

module.exports = board.component(
  (ctrl) => ({
    editing: ctrl.signal(
      false,
      ctrl.slot('editing.start').set(true),
      ctrl.slot('editing.stop').set(false)
    ),
    updatedTodo: ctrl.signal(
      undefined,
      ctrl.slot('todo.update'),
      ctrl.propsProperty('todo').set(undefined)
    )
  }),
  ({ slot, wire, wiredState, todo }) => {
    const {editing, updatedTodo} = wiredState,
          stopEdit = (stream) =>
            stream
            .map((it) => _.merge({}, todo, {title: updatedTodo}))
            .to(todos.todos.update, slot('editing.stop'))

    return <li
      className={todo.completed && 'completed' || editing && 'editing' || ''}
      onDoubleClick={wire((stream) =>
        stream
        .filter(() => !todo.completed)
        .to(slot('editing.start'))
      )}
      >
      <div className="view">
        <input
          className="toggle"
          type="checkbox"
          checked={todo.completed}
          onChange={wire((stream) =>
            stream.set(
              _.merge({}, todo, {completed: !todo.completed})
            ).to(todos.todos.update)
          )}/>

        <label>{todo.title}</label>
        <button
          className="destroy"
          onClick={wire((stream) =>
            stream.set(todo).to(todos.todos.remove)
          )}/>
      </div>
      {!editing ? undefined :
        <input
          className="edit"
          value={updatedTodo != undefined && updatedTodo || todo.title}
          autoFocus
          onKeyDown={wire((stream) =>
            stream
            .filter((event) => event.keyCode == KEY_ENTER)
            .wire(stopEdit)
          )}
          onBlur={wire(stopEdit)}
          onChange={wire((stream) => stream.extract().to(slot('todo.update')))}/>}
    </li>
  }
);
