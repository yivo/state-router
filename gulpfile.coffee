gulp            = require 'gulp'
connect         = require 'gulp-connect'
concat          = require 'gulp-concat'
coffee          = require 'gulp-coffee'
coffeeComments  = require 'gulp-coffee-comments'
preprocess      = require 'gulp-preprocess'
iife            = require 'gulp-iife-wrap'
uglify          = require 'gulp-uglify'
rename          = require 'gulp-rename'
del             = require 'del'
plumber         = require 'gulp-plumber'
connect         = require 'gulp-connect'

gulp.task 'default', ['build', 'watch', 'server'], ->

gulp.task 'build', ->
  global       = 'StateRouter'
  dependencies = [
    {require: 'lodash'}
    {require: 'jquery',               global: '$'}
    {require: 'XRegExp',              global: 'XRegExp', argument: 'XRegExpExports'}
    {require: 'yess',                 global: '_'}
    {require: 'coffee-concerns',      global: 'Concerns'}
    {require: 'callbacks',            global: 'Callbacks'}
    {require: 'construct-with',       global: 'ConstructWith'}
    {require: 'publisher-subscriber', global: 'PublisherSubscriber'}
    {require: 'property-accessors',   global: 'PropertyAccessors'}
    {require: 'core-object',          global: 'CoreObject'}
  ]

  gulp.src('source/__manifest__.coffee')
  .pipe plumber()
  .pipe preprocess()
  .pipe iife {dependencies, global}
  .pipe concat('state-router.coffee')
  .pipe gulp.dest('build')
  .pipe coffeeComments()
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
  del.sync 'spec/**/*'
  gulp.src('coffeespec/**/*.coffee')
    .pipe coffee(bare: yes)
    .pipe gulp.dest('spec')
  gulp.src('coffeespec/support/jasmine.json')
    .pipe gulp.dest('spec/support')
