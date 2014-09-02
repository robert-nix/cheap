C = require '../src/cheap'

describe 'malloc', ->
  block = null
  it 'should create a correctly-sized block', ->
    block = C.malloc 0x123
    block.l.should.be.above 0x123
  it 'should create a freeable block', ->
    C._heapLast.should.equal block
    block.free()
    (C._heapLast?).should.be.false
  it 'should fail to allocate bad numbers', ->
    (-> C.malloc -1).should.throw /alloc/
    # this is 512MiB, half the ArrayBuffer max size on v8
    (-> (C.malloc 0x20000000).free()).should.not.throw()
    (C._heapLast?).should.be.false

describe 'free', ->
  it 'should free correct addresses', ->
    block = C.malloc 100
    C.free block.a
    (C._heapLast?).should.be.false
  it 'should not affect invalid addresses', ->
    block = C.malloc 100
    C.free block.a + 1
    C.free 0
    C.free -1
    C.free block.e + 1
    (C._heapLast?).should.be.true
    block.free()
    (C._heapLast?).should.be.false
