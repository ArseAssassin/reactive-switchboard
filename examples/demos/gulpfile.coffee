url = require 'url'

gulp = require 'gulp'

_ = require 'lodash'

sequence = require 'gulp-sequence'
merge = require 'merge-stream'
gulpif = require 'gulp-if'
connect = require 'gulp-connect'
rewrite = require 'connect-modrewrite'
proxy = require 'proxy-middleware'

browserify = require 'browserify'
watchify = require 'watchify'
babelify = require 'babelify'

include = require 'gulp-include'

bundler = browserify _.merge watchify.args,
  entries: 'app/scripts/index.js'
  extensions: ['.js']
  debug: true
.transform babelify
.transform require 'brfs'


sources =
  styles:   'app/styles'
  scripts:  'app/scripts'
  views:    'app/views'
  images:   'app/images'
  config:   'app/config'
  fonts:    'app/fonts'
  bower:    'app/bower_components'
  lib:      'lib'
  shared:   'shared'

target =
  dist: './dist'
  views: './dist/views'
  public: './dist/public'
  styles: './dist/public/styles'
  scripts: './dist/public/scripts'
  images: './dist/public/images'
  publicViews: './dist/public/views'


gulp.task 'clean', ->
  del = require 'del'
  del ['dist/*']


gulp.task 'static:copy', ->
  gulp.src [
    sources.app + '/*.{ico,png,text,.htaccess}'
    sources.fonts + '**/*'
  ], base: sources.app
  .pipe gulp.dest target.public

ENVIRONMENT = process.env.NODE_ENV || 'development'
PRODUCTION_MODE = 'beta stage'.split(' ').indexOf(process.env.NODE_ENV) > -1

ifProduction = (step) ->
  gulpif PRODUCTION_MODE, step

ifNotProduction = (step) ->
  gulpif !PRODUCTION_MODE, step


gulp.task 'lib:copy', ->
  gulp.src sources.lib + '/**/*', base: './'
    .pipe gulp.dest target.dist


gulp.task 'html:copy', ->
  replace = require 'gulp-replace'
  preprocess = require 'gulp-preprocess'
  buildId = Math.random().toString(32).split('.')[1]

  merge(
    gulp.src sources.views + '/index.html'
      .pipe replace /\$BUILD_ID/g, buildId
      .pipe preprocess context: NODE_ENV: ENVIRONMENT
      .pipe gulp.dest target.publicViews

    gulp.src sources.views + '/**/*', base: sources.views
      .pipe replace /\$BUILD_ID/g, buildId
      .pipe preprocess context: NODE_ENV: ENVIRONMENT
      .pipe gulp.dest target.views
  )


gulp.task 'images:optimize', ->
  imagemin = require 'gulp-imagemin'

  gulp.src sources.images + '/**/*', base: sources.images
    .pipe ifProduction imagemin cache: false
    .pipe gulp.dest target.images


gulp.task 'js:build', ->
  buffer = require 'vinyl-buffer'
  source = require 'vinyl-source-stream'
  bundler.bundle()
    .on 'error', (err) ->
      console.error err
      @emit 'end'
  .pipe source 'scripts.js'
  .pipe buffer()
  .pipe gulp.dest target.scripts
  .pipe connect.reload()


gulp.task 'less:build', ->
  less = require 'gulp-less'
  combineMq = require 'gulp-combine-mq'
  csso = require 'gulp-csso'
  autoprefixer = require 'gulp-autoprefixer'

  gulp.src sources.styles + '/style.less'
    .pipe less paths: [sources.styles + '**/*']
    .on 'error', (err) ->
      console.error err
      @emit 'end'
    .pipe autoprefixer
      browsers: ['last 3 versions', '> 1%', 'ie >= 9']
    .pipe ifProduction combineMq
      beautify: false
    .pipe ifProduction csso()
    .pipe gulp.dest target.styles
    .pipe connect.reload()


gulp.task 'watch', ['build'], ->
  bundler = watchify bundler

  gulp.watch 'app/**/*.coffee', ['js:build']
  gulp.watch sources.views    + '/**/*', ['html:copy']
  gulp.watch sources.scripts  + '/**/*', ['js:build']
  gulp.watch sources.shared   + '/**/*', ['js:build']
  gulp.watch sources.config   + '/**/*', ['js:build']
  gulp.watch sources.styles   + '/**/*', ['less:build']
  gulp.watch sources.images   + '/**/*', ['images:optimize']
  gulp.watch sources.app      + '/index.html', ['html:copy']


gulp.task 'serve', ['watch'], ->
  proxyOptions = url.parse 'http://localhost:9000/api'
  proxyOptions.route = '/api'
  connect.server
    root: 'dist/public'
    port: 3001
    livereload:
        port: 35730
    middleware: ->
      [
        proxy(proxyOptions)
        rewrite ['^[^.]*$ /views/index.html']
      ]


gulp.task 'copy', ['static:copy', 'lib:copy', 'html:copy']
gulp.task 'optimize', ['images:optimize']
gulp.task 'source:build', ['less:build', 'js:build']
gulp.task 'build', sequence(['clean'], ['source:build', 'copy', 'optimize'])
gulp.task 'default', ['build']
