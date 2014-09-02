pkg = require './package.json'
gulp = require 'gulp'
util = require 'gulp-util'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
header = require 'gulp-header'
uglify = require 'gulp-uglify'
mocha = require 'gulp-mocha'

src = ['src/cheap.coffee']

head = """
/**
 * cheap.js - C-like memory layout for javascript
 * version #{pkg.version}
 * Copyright 2014 Robert Nix
 * MIT License
 */

"""

gulp.task 'build', ->
  gulp.src(src)
    .pipe(concat 'cheap.js')
    .pipe(coffee().on 'error', util.log)
    .pipe(header head)
    .pipe(gulp.dest 'dist')
    .pipe(concat 'cheap.min.js')
    .pipe(uglify())
    .pipe(header head)
    .pipe(gulp.dest 'dist')
  return

gulp.task 'spec', ->
  gulp.src('test/run.coffee', read: false)
    .pipe(mocha reporter: 'list')
  return

gulp.task 'default', ['spec', 'build']
