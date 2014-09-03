# a quick script for determining memory usage of the two vector storage
# strategies

VectorPool = require './vector_pool'

# TypedArrays don't show up in JS heap stats, so we have to use the resident set
# size (noisy because heap allocations are bulked):
last = process.memoryUsage().rss
delta = ->
  curr = process.memoryUsage().rss
  res = curr - last
  last = curr
  res

console.log 'start', delta()

arrs = []
pools = []
arrstats = {}
poolstats = {}

test = (poolSize) ->
  arr = []
  arrs.push arr
  for i in [0..poolSize-1] by 1
    arr.push {x:Math.random(), y:Math.random(), z:Math.random(), w:Math.random()}

  arrstats[poolSize] or= 0
  arrstats[poolSize] += delta()

  pool = new VectorPool poolSize
  pools.push pool
  for i in [0..poolSize-1] by 1
    pool.create Math.random(), Math.random(), Math.random(), Math.random()

  poolstats[poolSize] or= 0
  poolstats[poolSize] += delta()

  delta()

test 1e6
test 2e6
test 3e6

console.log 'end', delta()

arrstat = for k,v of arrstats
  "{#{k},#{v}}"
poolstat = for k,v of poolstats
  "{#{k},#{v}}"

console.log '#arr'
console.log arrstat.join ","
console.log '#pool'
console.log poolstat.join ","

# now pop this into something to do a linear regression
