Benchtable = require 'benchtable'
VectorPool = require './vector_pool'

log = (s) -> console.log s
if document?
  log = (s) -> document.write '<p>' + s + '</p>'

pools = {}
plains = {}
for size in [1e3, 1e5, 1e6]
  pools[size] = pool = new VectorPool size
  plains[size] = []
  for i in [0..size-1]
    pool.create Math.random(), Math.random(), Math.random(), Math.random()
    plains[size].push {x:Math.random(), y:Math.random(), z:Math.random(), w:Math.random()}
  for i in [0..size-1]
    # holes!
    continue if Math.random() < 0.9
    pool.remove i
    delete plains[size][i]

new Benchtable()
# init tests
.addFunction('VectorPool init', (poolSize) ->
  tmp = new VectorPool poolSize
  for i in [0..poolSize-1] by 1
    tmp.create Math.random(), Math.random(), Math.random(), Math.random()
  tmp.destroy()
)
.addFunction('plain init', (poolSize) ->
  tmp = []
  for i in [0..poolSize-1] by 1
    tmp.push {x:Math.random(), y:Math.random(), z:Math.random(), w:Math.random()}
  null
)
# read
.addFunction('VectorPool seq read', (poolSize) ->
  pool = pools[poolSize]
  sum = 0
  for i in [0..poolSize-1] by 1
    vec = pool.at i
    continue if not vec?
    sum += vec.x + vec.y + vec.z + vec.w
  null
)
.addFunction('plain seq read', (poolSize) ->
  arr = plains[poolSize]
  sum = 0
  for i in [0..poolSize-1] by 1
    vec = arr[i]
    continue if not vec?
    sum += vec.x + vec.y + vec.z + vec.w
  null
)
.addFunction('VectorPool rand read', (poolSize) ->
  pool = pools[poolSize]
  sum = 0
  for i in [0..poolSize-1] by 1
    vec = pool.at 0|(Math.random()*poolSize)
    continue if not vec?
    sum += vec.x + vec.y + vec.z + vec.w
  null
)
.addFunction('plain rand read', (poolSize) ->
  arr = plains[poolSize]
  sum = 0
  for i in [0..poolSize-1] by 1
    vec = arr[0|(Math.random()*poolSize)]
    continue if not vec?
    sum += vec.x + vec.y + vec.z + vec.w
  null
)
# write
.addFunction('VectorPool seq write', (poolSize) ->
  pool = pools[poolSize]
  for i in [0..poolSize-1] by 1
    vec = pool.at i
    continue if not vec?
    x = vec.y
    y = vec.z
    z = vec.x
    w = -vec.w
    pool.set i, x, y, z, w
  null
)
.addFunction('plain seq write', (poolSize) ->
  arr = plains[poolSize]
  for i in [0..poolSize-1] by 1
    vec = arr[i]
    continue if not vec?
    tmp = vec.x
    vec.x = vec.y
    vec.y = vec.z
    vec.z = tmp
    vec.w = -vec.w
  null
)
.addFunction('VectorPool rand write', (poolSize) ->
  pool = pools[poolSize]
  for i in [0..poolSize-1] by 1
    vec = pool.at 0|(Math.random()*poolSize)
    continue if not vec?
    x = vec.y
    y = vec.z
    z = vec.x
    w = -vec.w
    pool.set i, x, y, z, w
  null
)
.addFunction('plain rand write', (poolSize) ->
  arr = plains[poolSize]
  for i in [0..poolSize-1] by 1
    vec = arr[0|(Math.random()*poolSize)]
    continue if not vec?
    tmp = vec.x
    vec.x = vec.y
    vec.y = vec.z
    vec.z = tmp
    vec.w = -vec.w
  null
)
# create+delete
.addFunction('VectorPool lifetime sim', (poolSize) ->
  pool = pools[poolSize]
  quota = poolSize / 10 - 1
  for i in [0..quota] by 1
    idx = 0|(Math.random()*poolSize)
    until pool.valid idx
      idx = (idx + 1) % poolSize
    pool.remove idx
  for i in [0..quota] by 1
    pool.create Math.random(), Math.random(), Math.random(), Math.random()
  null
)
.addFunction('plain lifetime sim', (poolSize) ->  
  # this is mildly unfair since a proper pool object should be used here
  arr = plains[poolSize]
  quota = poolSize / 10 - 1
  deleted = []
  for i in [0..quota] by 1
    idx = 0|(Math.random()*poolSize)
    until arr[idx]?
      idx = (idx + 1) % poolSize
    delete arr[idx]
    deleted.push idx
  for i in [0..quota] by 1
    arr[deleted.pop()] = {x:Math.random(), y:Math.random(), z:Math.random(), w:Math.random()}
  null
)
.addInput('1e3', [1e3])
.addInput('1e5', [1e5])
.addInput('1e6', [1e6])
.on('cycle', (e) -> log String e.target)
.on('complete', ->
  console.log @table.toString()
).run()
