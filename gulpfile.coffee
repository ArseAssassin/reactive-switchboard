gulp = require 'gulp'
sourcemaps = require 'gulp-sourcemaps'
browserify = require 'browserify'
coffee = require 'gulp-coffee'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
gutil = require 'gulp-util'
del = require 'del'

watchify = require 'watchify'

connect = require 'gulp-connect'

_ = require 'lodash'

b = browserify _.merge watchify.args,
  entries: 'examples/todo.coffee'
  transform: ['coffeeify']
  extensions: ['.coffee']
  debug: true


gulp.task 'clean', ->
  del 'dist'


gulp.task 'build', ->
  b.bundle()
    .on 'error', gutil.log.bind(gutil, 'browserify error')
    .pipe source 'switchboard.js'
    .pipe buffer()
    .pipe gulp.dest './dist'
    .pipe connect.reload()


gulp.task 'watch', ->
  b = watchify b
  gulp.watch '**/*.coffee', ['build']

gulp.task 'serve', ['watch', 'build'], ->
  connect.server
    root: 'dist'
    port: 4040
    livereload: true
