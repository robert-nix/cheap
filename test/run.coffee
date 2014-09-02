require 'should'

# avoid committing 2GiB of memory on travis:
require './heap' if process?.env?.TEST_HEAP

# main tests
require './malloc'
require './struct'

C = require '../src/cheap'

# misc tests
describe 'copyBuffer', ->
  it 'should copy an ArrayBuffer to a valid heap location', ->
    buf = new ArrayBuffer 256
    ui8view = new Uint8Array buf
    for i in [0..255]
      ui8view[i] = i
    block = C.copyBuffer buf
    block.a.should.be.ok
    for i in [0..255]
      block.ui8[i].should.be.exactly(i)
    block.free()
describe 'set64Bit', ->
  it 'should set the correct pointer size', ->
    block = C.malloc 0x100
    C.set64Bit false
    type32 = C.struct [
      C.ptr 'int', 'pi32'
    ]
    C.set64Bit true
    type64 = C.struct [
      C.ptr 'int', 'pi32'
    ]
    C.sizeof(type32).should.not.equal(C.sizeof(type64))
    C.sizeof(type32).should.be.exactly(4)
    C.sizeof(type64).should.be.exactly(8)
    block.free()

VectorPool = require './vector_pool'

describe 'VectorPool', ->
  pool = null
  it 'should be constructible', ->
    pool = new VectorPool 1e6
    pool.size.should.be.exactly 1e6
  it 'should allow creating vectors', ->
    for i in [0..1e6-1]
      pool.create 0.3, 0.7, 1.2, 0.8
    null
  it 'should allow deleting vectors', ->
    for i in [0..1e6-1] by 2
      pool.remove i
    null
  it 'should still allow creating vectors', ->
    for i in [0..1e5-1]
      pool.create 0.3, 0.7, 1.2, 0.8
    null
  it 'should allow iterating vectors', ->
    sum = 0
    n = 0
    quota = 1e6 / 2 + 1e5
    pool.iterate (vec, i) ->
      sum += vec.x + vec.y + vec.z + vec.w
      n++
    n.should.be.exactly quota
    Math.abs(3 * quota - sum).should.be.lessThan 0.5
  it 'should be destructible', ->
    pool.destroy()
    (C._heapList?).should.be.false
