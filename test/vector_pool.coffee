C = require '../src/cheap'

Vec4 = C.struct {
  'x': C.float 0
  'y': C.float 4
  'z': C.float 8
  'w': C.float 12
  'next': C.int 0
  'valid': C.int 4
}
C.typedef 'Vec4', Vec4

CPool = C.struct [
  C.int 'firstIdx'
  C.ptr 'Vec4', 'data'
]
CPoolData = C.struct [
  C.Vec4 'data', 1
]

class VectorPool
  constructor: (@size) ->
    @block = C.malloc (@size + 1) * C.strideof Vec4
    @pool = new CPool @block, 0
    @data = new CPoolData @block, 0x10
    @pool.firstIdx = 0
    i = 0
    until i is @size - 1
      vec = @at i
      vec.next = i + 1
      vec.valid = -1
      i++
    vec = @at i
    vec.next = -1
    vec.valid = -1

  destroy: -> @block.free()

  create: (x, y, z, w) ->
    idx = @pool.firstIdx
    vec = @at idx
    @pool.firstIdx = vec.next
    vec.x = x
    vec.y = y
    vec.z = z
    vec.w = w
    null

  remove: (idx) ->
    first = @pool.firstIdx
    vec = @at idx
    vec.next = first
    vec.valid = -1
    @pool.firstIdx = idx

  at: (idx) -> @data.data idx

  iterate: (cb) ->
    i = 0
    until i is @size
      vec = @at(i)
      # 0xffffffff is a denormal float, so... hax!
      cb vec, i if vec.valid isnt -1
      i++
    null

module.exports = VectorPool
