C = require '../src/cheap'

describe 'heap', ->
  it 'should allow many allocs and frees', ->
    # a little functional test of the heap, ignoring fragmentation: allocate
    # many evenly sized blocks, randomly free them, and allocate some more
    size = 64*1024*1024
    quota = 128 # go for a few times the available heap size
    blocks = []
    while quota > 0
      while blocks.length < 31
        blocks.push C.malloc size
        quota--
      while blocks.length > 17
        idx = 0|Math.random() * blocks.length
        blocks[idx].free()
        blocks.splice idx, 1
    for block in blocks
      block.free()
    (C._heapLast?).should.be.false
    blocks = null
