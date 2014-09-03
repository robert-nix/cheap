# cheap.js - C-like memory layout for javascript
# Copyright 2014 Robert Nix
C = {}

# Returns objects for struct member definitions
makeStructMember = (typeName, pointerDepth, memberName, arrayLength, offset) ->
  { typeName, pointerDepth, memberName, offset, arrayLength, isArray: arrayLength? }

C._typedefs = {}
C.typedef = (typeName, structDef) ->
  throw new Error 'name collides' if typeName of C
  C._typedefs[typeName] = structDef
  C[typeName] = (memberName, arrayLength) ->
    if typeof memberName is 'string'
      makeStructMember typeName, 0, memberName, arrayLength
    else
      makeStructMember typeName, 0, undefined, arrayLength, memberName

C.ptr = (typeName, memberName, pointerDepth = 1) ->
  makeStructMember typeName, pointerDepth, memberName

C.typedef 'uint' # 0
C.typedef 'int' # 1
C.typedef 'ushort' # 2
C.typedef 'short' # 3
C.typedef 'uchar' # 4
C.typedef 'char' # 5
C.typedef 'float' # 6
C.typedef 'double' # 7
C.typedef 'void'

pointerSize = 4
pointerShift = 2

C.set64Bit = (is64Bit) ->
  if is64Bit
    pointerSize = 8
    pointerShift = 3
  else
    pointerSize = 4
    pointerShift = 2

C._typeNameToId = (n) ->
  switch n
    when 'uint' then 0
    when 'int' then 1
    when 'ushort' then 2
    when 'short' then 3
    when 'uchar' then 4
    when 'char' then 5
    when 'float' then 6
    when 'double' then 7
    else -1


C._arrayName = (t) ->
  switch t
    when 0, 'uint' then 'ui32'
    when 1, 'int' then 'i32'
    when 2, 'ushort' then 'ui16'
    when 3, 'short' then 'i16'
    when 4, 'uchar' then 'ui8'
    when 5, 'char' then 'i8'
    when 6, 'float' then 'f32'
    when 7, 'double' then 'f64'
    else 'ui32'

C._arrayElSize = (t) ->
  switch t
    when 0, 'uint', 1, 'int' then 4
    when 2, 'ushort', 3, 'short' then 2
    when 4, 'uchar', 5, 'char' then 1
    when 6, 'float' then 4
    when 7, 'double' then 8
    else pointerSize

C._arrayElShift = (t) ->
  switch t
    when 0, 'uint', 1, 'int', 6, 'float' then 2
    when 2, 'ushort', 3, 'short' then 1
    when 4, 'uchar', 5, 'char' then 0
    when 7, 'double' then 3
    else pointerShift

C.sizeof = (type) ->
  if typeof type is 'string'
    switch type
      when 'char', 'uchar' then 1
      when 'short', 'ushort' then 2
      when 'int', 'uint', 'float' then 4
      when 'double' then 8
      when 'void*' then pointerSize
      else 1 # void
  else
    type.__size

C.strideof = (type) ->
  if typeof type is 'string'
    C.sizeof type
  else
    (type.__size + type.__align - 1) & -type.__align

C.alignof = (type) ->
  if typeof type is 'string'
    C.sizeof type
  else
    type.__align

C.offsetof = (type, member) -> type[member].offset

makeAccessors = (def) ->
  { offset, member, type, stride, align, size } = def
  basic = typeof type is 'string'
  typeId = C._typeNameToId type
  arr = C._arrayName type
  elShift = C._arrayElShift type
  if member.pointerDepth is 0 and not member.isArray
    if basic
      # basic value type:
      {
        get: -> @__b[arr][(@__a+offset) >> elShift]
        set: (x) -> @__b[arr][(@__a+offset) >> elShift] = x
      }
    else
      # complex value type:
      cName = '__c_' + member.memberName # for caching
      {
        get: ->
          if @[cName]?
            @[cName]
          else
            res = new type.__ctor(@__b, @__a+offset)
            @[cName] = res
            res
        set: (x) -> C.memcpy @__b, @__a+offset, x.__b, x.__a, size
      }
  else if member.pointerDepth is 0
    if basic
      # basic array type
      {
        get: ->
          bIdx = (@__a+offset) >> elShift
          {__b} = @
          (idx, val) ->
            if not val?
              __b[arr][bIdx+idx]
            else
              __b[arr][bIdx+idx] = val
      }
    else
      # complex array type
      {
        get: ->
          bOff = @__a+offset
          {__b} = @
          (idx, val) ->
            if not val?
              new type.__ctor(__b, bOff+idx*stride)
            else
              C.memcpy __b, bOff+idx*stride, val.__b, val.__a, size
      }
  else
    # pointer type:
    T = typeId
    if T < 0
      T = type
    pd = member.pointerDepth
    {
      get: ->
        addr = @__b.ui32[(@__a+offset)/4]
        new ptr addr, T, pd
      set: (x) ->
        @__b.ui32[(@__a+offset)/4] = x.a
    }


C.struct = (def) ->
  struct = ->
    struct.__ctor.apply this, arguments
  struct.__size = 0
  struct.__align = 1
  if Array.isArray def
    for member in def
      type = C._typedefs[member.typeName] or member.typeName
      _type = type
      _type = 'void*' if member.pointerDepth > 0
      size = C.sizeof _type
      align = C.alignof _type
      stride = (size + align - 1) &-align
      if member.isArray
        size += stride * (member.arrayLength - 1)
      struct.__size = (struct.__size + align - 1) & -align
      offset = struct.__size
      struct.__size += size
      if align > struct.__align
        struct.__align = align
      struct[member.memberName] = { offset, member, type, stride, align, size }
  else
    for name, member of def
      type = C._typedefs[member.typeName] or member.typeName
      _type = type
      _type = 'void*' if member.pointerDepth > 0
      member.memberName = name
      size = C.sizeof _type
      align = C.alignof _type
      stride = (size + align - 1) &-align
      if member.isArray
        size += stride * (member.arrayLength - 1)
      offset = member.offset
      end = offset + size
      if end > struct.__size
        struct.__size = end
      if align > struct.__align
        struct.__align = align
      struct[member.memberName] = { offset, member, type, stride, align, size }
  struct.__ctor = (buffer, address) ->
    @__b = buffer
    @__a = address
    @
  struct.__ctor.prototype = do->
    result = { __t: struct }
    for k, v of struct when k.substr(0,2) isnt '__'
      Object.defineProperty result, k, makeAccessors v
    result
  struct.prototype = struct.__ctor.prototype
  struct

C._heapLast = null
block = (addr, size, prev, next) ->
  @a = addr
  @l = size
  @e = addr + size
  @prev = prev
  if prev?
    prev.next = @
  @next = next
  if next?
    next.prev = @
  # create all views up front:
  @buf = buf = new ArrayBuffer(size)
  @ui32 = new Uint32Array(buf)
  @i32 = new Int32Array(buf)
  @ui16 = new Uint16Array(buf)
  @i16 = new Int16Array(buf)
  @ui8 = new Uint8Array(buf)
  @i8 = new Int8Array(buf)
  @f32 = new Float32Array(buf)
  @f64 = new Float64Array(buf)
  @

block.prototype.free = ->
  if @ is C._heapLast
    C._heapLast = @prev
  if @prev?
    @prev.next = @next
  if @next?
    @next.prev = @prev
  return

# pad to help mitigate null pointer+math derefs
addressMin = 0x00010000
addressMax = 0x7fff0000

C.malloc = (size) ->
  if size < 0
    throw new Error 'invalid allocation size'
  # round up so that the underlying TypedArrays are accessible; 16 because I
  # like round numbers
  size = (size + 0xf) & -0x10
  if C._heapLast == null
    if size+addressMin > addressMax
      throw new Error 'invalid allocation size'
    C._heapLast = new block(addressMin, size, null, null)
  else
    curr = C._heapLast
    if size+curr.e <= addressMax
      addr = curr.e
      C._heapLast = new block(addr, size, curr, null)
    else
      b = null
      loop
        min = curr.prev?.e or addressMin
        room = curr.a - min
        if room >= size
          addr = curr.a - size
          b = new block(addr, size, curr.prev, curr)
          break
        curr = curr.prev
        if not curr?
          # yeah, fragmentation can get us here easily, but 2gigs of VA space
          # seems bountiful for this purpose, and I'd rather not overengineer it
          throw new Error 'heap space not available'
      return b

C.free = (addr) ->
  if typeof addr is 'object'
    return addr.free()
  return if addr < addressMin
  return if addr >= addressMax
  curr = C._heapLast
  loop
    break if not curr?
    if curr.a is addr
      return curr.free()
    curr = curr.prev

C.getBufferAddress = (addr) ->
  if typeof addr is 'object'
    # grab address from ptr objects
    addr = addr.a
  curr = C._heapLast
  loop
    break if not curr?
    if curr.e > addr and curr.a <= addr
      return [curr, addr - curr.a]
    curr = curr.prev
  # i feel bad about not throwing here where the errant stack is, but C.
  return [null, 0]

C._getHeapValue = (addr, t) ->
  [buf, rva] = C.getBufferAddress addr
  switch t
    when 0 then buf.ui32[0|rva/4]
    when 1 then buf.i32[0|rva/4]
    when 2 then buf.ui16[0|rva/2]
    when 3 then buf.i16[0|rva/2]
    when 4 then buf.ui8[0|rva]
    when 5 then buf.i8[0|rva]
    when 6 then buf.f32[0|rva/4]
    when 7 then buf.f64[0|rva/8]
    else buf.ui32[0|rva/4]

C._setHeapValue = (addr, t, v) ->
  [buf, rva] = C.getBufferAddress addr
  switch t
    when 0 then buf.ui32[0|rva/4] = v
    when 1 then buf.i32[0|rva/4] = v
    when 2 then buf.ui16[0|rva/2] = v
    when 3 then buf.i16[0|rva/2] = v
    when 4 then buf.ui8[0|rva] = v
    when 5 then buf.i8[0|rva] = v
    when 6 then buf.f32[0|rva/4] = v
    when 7 then buf.f64[0|rva/8] = v
    else buf.ui32[0|rva/4] = v

C.memcpy = (dstBuf, dstRva, srcBuf, srcRva, size) ->
  if not size?
    dstAddr = dstBuf
    srcAddr = dstRva
    size = srcBuf
    [dstBuf, dstRva] = C.getBufferAddress dstAddr
    [srcBuf, srcRva] = C.getBufferAddress srcAddr
  dstBuf.ui8.set srcBuf.ui8.subarray(srcRva, srcRva + size), dstRva

C.copyBuffer = (buf) ->
  res = C.malloc buf.byteLength
  res.ui8.set new Uint8Array(buf), 0
  res

ptr = (a, t, p) ->
  @a = a
  @t = t
  @p = p
  @

ptr.prototype.deref = (head, tail...) ->
  nextDepth = @p - 1
  currAddr = @a
  head or= 0
  if nextDepth is 0
    if typeof @t is 'number'
      C._getHeapValue currAddr + head * C._arrayElSize(@t), @t
    else
      [buf, rva] = C.getBufferAddress currAddr + head * C.sizeof(@t)
      new @t buf, rva
  else
    nextPtr = C._getHeapValue currAddr + head * pointerSize, 0
    nextObj = new ptr nextPtr, @t, nextDepth # Object.create Object.getPrototypeOf @
    # nextObj.t = @t
    # nextObj.p = nextDepth
    # nextObj.a = nextPtr
    if tail.length > 0
      @deref.apply nextObj, tail
    else
      nextObj

ptr.prototype.set = (idx, val) ->
  nextDepth = @p - 1
  currAddr = @a
  throw new Error 'bad pointer' if nextDepth < 0
  if nextDepth is 0
    if typeof @t is 'number'
      C._setHeapValue currAddr + idx * C._arrayElSize(@t), @t, val
    else
      [dstBuf, dstRva] = C.getBufferAddress currAddr + idx * C.sizeof(@t)
      C.memcpy dstBuf, dstRva, val.__b, val.__a, C.sizeof(@t)
  else
    C._setHeapValue currAddr + idx * pointerSize, 0, val.a

ptr.prototype.cast = (type) ->
  if typeof type is 'string'
    type = type.split '*'
    p = type.length - 1
    p = @p if p is 0
    tId = C._typeNameToId type[0]
    tId = C._typeDefs[type[0]] if tId < 0
    new ptr @a, tId, p
  else
    new ptr @a, type, @p

C.ref = (locatable, memberName) ->
  if locatable.__t?
    t = locatable.__t
    a = locatable.__a + locatable.__b.a
    p = 1
    if memberName?
      a += t[memberName].offset
      p += t[memberName].pointerDepth
      t = t[memberName].type
    new ptr a, t, p
  else
    new ptr locatable.a, 'void*', 1
ptr.prototype.add = (offset) ->
  new ptr @a + offset, @t, @p

if typeof module is 'object' and typeof module.exports is 'object'
  # node/browserify
  module.exports = C
else if typeof define == 'function' && define.amd
  # amd
  define ['cheap'], -> @cheap = C
else
  # window/etc.
  @cheap = C
