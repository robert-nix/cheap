C = require '../src/cheap'

# VectorPool is a basic class for storing a large amount of 4-element vectors
# in contiguous memory.  This is primarily an example of making things not slow;
# keep in mind, however, that memory usage even when using the 'pretty'
# accessors is much lower than using plain objects, although GC pressure is
# a bit higher than using plain typed arrays due to temporary objects.

Vec4 = C.struct {
  'x': C.float 0
  'y': C.float 4
  'z': C.float 8
  'w': C.float 12
  'next': C.int 0
  'valid': C.int 4
}

# name some useful numbers
# since all the offsets are at multiple of 4s, we can save ourselves unnecessary
# math when indexing into the typed arrays by dividing everything by 4 now:
o_x = Vec4.x.offset >> 2
o_y = Vec4.y.offset >> 2
o_z = Vec4.z.offset >> 2
o_w = Vec4.w.offset >> 2
o_next = Vec4.next.offset >> 2
o_valid = Vec4.valid.offset >> 2
stride = C.strideof(Vec4) >> 2

# Take a look at http://gameprogrammingpatterns.com/object-pool.html for an
# explanation of this class pattern.  I have coupled the pool very tightly with
# the Vec4 class for performance considerations, but it's perfectly fine to
# return the plain cheap struct objects if you're not concerned with tight
# loops.
class VectorPool
  constructor: (@size) ->
    @block = C.malloc @size * stride * 4
    @_fb = @block.f32
    @_ib = @block.i32
    @first = 0
    i = 0
    beforeLast = @size - 1
    until i is beforeLast
      idx = i * stride
      @_ib[idx + o_next] = i + 1
      # instead of using an extra bool field, use a denormal float value as a
      # sentinel:
      @_ib[idx + o_valid] = -1
      i++
    idx = beforeLast * stride
    @_ib[idx + o_next] = -1
    @_ib[idx + o_valid] = -1

  destroy: ->
    @block.free()
    delete @block
    delete @_fb
    delete @_ib

  create: (x, y, z, w) ->
    throw 'pool is full' if @first < 0
    idx = @first * stride
    @first = @_ib[idx + o_next]
    @_fb[idx + o_x] = x
    @_fb[idx + o_y] = y
    @_fb[idx + o_z] = z
    @_fb[idx + o_w] = w
    null

  at: (i) ->
    idx = i * stride
    return if @_ib[idx + o_valid] is -1
    {
      x: @_fb[idx + o_x]
      y: @_fb[idx + o_y]
      z: @_fb[idx + o_z]
      w: @_fb[idx + o_w]
    }

  set: (i, x, y, z, w) ->
    idx = i * stride
    return if @_ib[idx + o_valid] is -1
    @_fb[idx + o_x] = x
    @_fb[idx + o_y] = y
    @_fb[idx + o_z] = z
    @_fb[idx + o_w] = w

  remove: (i) ->
    idx = i * stride
    @_ib[idx + o_next] = @first
    @_ib[idx + o_valid] = -1
    @first = i

  valid: (i) ->
    idx = i * stride
    return @_ib[idx + o_valid] isnt -1

  sum: (i) ->
    idx = i * stride
    @_fb[idx + o_x] + @_fb[idx + o_y] + @_fb[idx + o_z] + @_fb[idx + o_w]

  iterate: (cb) ->
    i = 0
    until i is @size
      idx = i * stride
      if @_ib[idx + o_valid] isnt -1
        cb @_fb[idx + o_x], @_fb[idx + o_y], @_fb[idx + o_z], @_fb[idx + o_w], i
      i++
    null

module.exports = VectorPool
