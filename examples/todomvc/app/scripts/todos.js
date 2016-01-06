function createTodo(label) {
  return {
    title: label,
    id: Math.random(),
    completed: false
  }
}

module.exports = require('reactive-switchboard').create(function() {
  var todos = window.localStorage.getItem('todos-reactive-switchboard');
  todos = todos && JSON.parse(todos) || [];

  this.todos = {
    signal: this.signal(
      todos,

      this.slot('todos.add')
      .map((it) => it.trim())
      .filter((it) => it != ''),
      (oldTodos, newTodo) => [createTodo(newTodo)].concat(oldTodos),

      this.slot('todos.update'),
      (oldTodos, updatedTodo) => oldTodos.map(
        (it) => it.id == updatedTodo.id ? updatedTodo : it
      ),

      this.slot('todos.remove'),
      (oldTodos, removedTodo) => oldTodos.filter((it) => it.id != removedTodo.id),

      this.slot('todos.toggleAll'),
      (oldTodos, done) => oldTodos.map((it) => _.merge({}, it, {completed: done})),

      this.slot('todos.clear'),
      (oldTodos) => oldTodos.filter((it) => !it.completed)
    ).doAction((todos) => {
      window.localStorage.setItem('todos-reactive-switchboard', JSON.stringify(todos))
    }),
    add:        this.slot('todos.add'),
    update:     this.slot('todos.update'),
    remove:     this.slot('todos.remove'),
    clear:      this.slot('todos.clear'),
    toggleAll:  this.slot('todos.toggleAll')
  }

  this.mode = {
    signal: this.signal(
      document.location.hash || '#/',

      kefir.fromEvents(window, 'hashchange')
      .map(() => document.location.hash)
    )
  }
})
