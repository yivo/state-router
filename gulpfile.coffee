gulp        = require 'gulp'
connect     = require 'gulp-connect'
concat      = require 'gulp-concat'
coffee      = require 'gulp-coffee'
preprocess  = require 'gulp-preprocess'
iife        = require 'gulp-iife'
uglify      = require 'gulp-uglify'
rename      = require 'gulp-rename'
del         = require 'del'
plumber     = require 'gulp-plumber'
connect     = require 'gulp-connect'

gulp.task 'default', ['build', 'watch', 'server'], ->

gulp.task 'build', ->
  global = 'StateRouter'
  dependencies = [
    {name: 'lodash', as: '_'}
    {name: 'jquery', as: '$'}
    {name: 'XRegExp', as: 'XRegExp'}
    {name: 'yess'}
    {name: 'coffee-concerns'}
    {name: 'strict-parameters', as: 'StrictParameters'}
    {name: 'pub-sub', as: 'PublisherSubscriber'}
  ]

  gulp.src('source/_manifest.coffee')
  .pipe plumber()
  .pipe preprocess()
  .pipe iife {dependencies, global}
  .pipe concat('state-router.coffee')
  .pipe gulp.dest('build')
  .pipe coffee()
  .pipe concat('state-router.js')
  .pipe gulp.dest('build')

gulp.task 'build-min', ['build'], ->
  gulp.src('build/state-router.js')
  .pipe uglify()
  .pipe rename('state-router.min.js')
  .pipe gulp.dest('build')

gulp.task 'watch', ->
  gulp.watch 'source/**/*', ['build']

gulp.task 'server', ->
  connect.server fallback: 'index.html'

gulp.task 'coffeespec', ->
  del.sync 'spec/**/*.js'
  gulp.src('coffeespec/**/*.coffee')
  .pipe preprocess()
  .pipe coffee(bare: yes)
  .pipe gulp.dest('spec')