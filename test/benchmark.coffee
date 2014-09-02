Benchtable = require 'benchtable'
VectorPool = require './vector_pool'

suite = new Benchtable()

poolSize = 1e6
pool = new VectorPool poolSize
for i in [0..1e6-1]
  pool.create Math.random(), Math.random(), Math.random(), Math.random()

suite.addFunction('VectorPool init', (poolSize) ->
  tmp = new VectorPool poolSize
  for i in [0..poolSize-1] by 1
    tmp.create Math.random(), Math.random(), Math.random(), Math.random()
  tmp.destroy()
).addFunction('plain init', (poolSize) ->
  tmp = []
  for i in [0..poolSize-1] by 1
    tmp.push {x:Math.random(), y:Math.random(), z:Math.random(), w:Math.random()}
).addInput('1e3', [1e3])
.addInput('1e6', [1e6])
.on('cycle', (e) -> console.log String e.target)
.on('complete', ->
  console.log @table.toString()
).run()
