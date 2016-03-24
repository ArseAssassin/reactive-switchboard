function createTodo(label) {
  return {
    title: label,
    id: Math.random(),
    completed: false
  }
}

module.exports = require('reactive-switchboard').create(function(ctrl) {
  var todos = window.localStorage.getItem('todos-reactive-switchboard');
  todos = todos && JSON.parse(todos) || [];

  return {
    todos: {
      signal: ctrl.signal(
        todos,

        ctrl.slot('todos.add')
        .map((it) => it.trim())
        .filter((it) => it != ''),
        (oldTodos, newTodo) => [createTodo(newTodo)].concat(oldTodos),

        ctrl.slot('todos.update'),
        (oldTodos, updatedTodo) => oldTodos.map(
          (it) => it.id == updatedTodo.id ? updatedTodo : it
        ),

        ctrl.slot('todos.remove'),
        (oldTodos, removedTodo) => oldTodos.filter((it) => it.id != removedTodo.id),

        ctrl.slot('todos.toggleAll'),
        (oldTodos, done) => oldTodos.map((it) => _.merge({}, it, {completed: done})),

        ctrl.slot('todos.clear'),
        (oldTodos) => oldTodos.filter((it) => !it.completed)
      ).doAction((todos) => {
        window.localStorage.setItem('todos-reactive-switchboard', JSON.stringify(todos))
      }),
      add:        ctrl.slot('todos.add'),
      update:     ctrl.slot('todos.update'),
      remove:     ctrl.slot('todos.remove'),
      clear:      ctrl.slot('todos.clear'),
      toggleAll:  ctrl.slot('todos.toggleAll')
    },
    mode: {
      signal: ctrl.signal(
        document.location.hash || '#/',

        kefir.fromEvents(window, 'hashchange')
        .map(() => document.location.hash)
      )
    }
  };
})
