C = require '../src/cheap'

fround = (x) ->
  f32 = new Float32Array 1
  f32[0] = x
  f32[0]

describe 'struct', ->
  basicTest = null
  block = null
  obj = null
  it 'returns a class which can be applied to a buffer', ->
    basicTest = C.struct [
      # intentionally create holes in the struct
      C.uchar 'ui8'
      C.uint 'ui32'
      C.char 'i8'
      C.int 'i32'
      C.ushort 'ui16'
      C.float 'f32'
      C.short 'i16'
      C.double 'f64'
    ]
    basicTest.should.be.a.Function;
    C.offsetof(basicTest, 'ui8').should.be.exactly 0
    C.offsetof(basicTest, 'ui32').should.be.exactly 4
    C.offsetof(basicTest, 'i32').should.be.exactly 12
    block = C.malloc 0x1000
    obj = new basicTest block, 0
    obj.should.be.an.Object;
  it 'should allow basic types to be read', ->
    for t in ['ui8', 'ui32', 'i8', 'i32', 'ui16', 'f32', 'i16', 'f64']
      obj[t].should.be.a.Number
  it 'should allow basic types to be read and write', ->
    for t in ['ui8', 'ui32', 'i8', 'i32', 'ui16', 'f32', 'i16', 'f64']
      val = Math.random() * 128
      val = 0|val if t[0] isnt 'f'
      val = fround val if t is 'f32'
      obj[t] = val
      obj[t].should.be.exactly val
  it 'should allow the same data to be accessed under two different types', ->
    # test the define-by-offset struct declaration syntax
    aliasTest = C.struct
      'ui32': C.uint 0
      'f32': C.float 0
      'ui8': C.uchar 2
    obj = new aliasTest block, 0
    obj.f32 = 1
    obj.ui32.should.be.exactly 0x3f800000
    obj.ui8.should.be.exactly 0x80
  it 'should allow basic array types to be read and write', ->
    arrayTest = C.struct [
      C.uint 'ui32', 4
      C.int 'i32', 4
      C.ushort 'ui16', 4
      C.short 'i16', 4
      C.uchar 'ui8', 4
      C.char 'i8', 4
      C.float 'f32', 4
      C.double 'f64', 4
    ]
    obj = new arrayTest block, 0
    deferred = []
    for td in [[0x80000000, 'ui32', 'i32'], [0x8000, 'ui16', 'i16'], [0x80, 'ui8', 'i8']]
      max = td[0]
      for t in td.slice 1
        for i in [0..3]
          val = 0|(Math.random() * max)
          obj[t](i, val)
          do (t, i, val) ->
            deferred.push -> obj[t](i).should.be.exactly val
    for i in [0..3]
      val = Math.random()
      obj.f32 i, val
      obj.f64 i, val
      do (i, val) ->
        deferred.push -> obj.f32(i).should.be.exactly fround val
        deferred.push -> obj.f64(i).should.be.exactly val
    # test for member overlaps
    fn() for fn in deferred
    null
  it 'should allow basic pointer types to be read and write', ->
    pointerTest = C.struct [
      C.ptr 'float', 'pf32'
    ]
    obj = new pointerTest block, 0
    obj.pf32 = C.ref(obj).add(C.sizeof pointerTest)
    deferred = []
    for i in [0..15]
      val = fround Math.random()
      obj.pf32.set i, val
      do (i, val) ->
        deferred.push -> obj.pf32.deref(i).should.be.exactly val
    fn() for fn in deferred
    null
  subTest = null
  it 'should allow complex value types to be read and write', ->
    subTest = C.struct [
      C.int 'a', 2
      C.float 'vec', 4
    ]
    C.typedef 'SubTest', subTest
    complexTest = C.struct [
      C.SubTest 'inner'
    ]
    objA = new complexTest block, 0
    objB = new complexTest block, C.strideof complexTest
    deferred = []
    for i in [0..3]
      val = Math.random()
      objB.inner.vec i, val
      do (i, val) ->
        deferred.push -> objA.inner.vec(i).should.be.exactly fround val
    objA.inner = objB.inner
    fn() for fn in deferred
    null
  it 'should allow complex array types to be read and write', ->
    complexTest = C.struct [
      C.SubTest 'inner', 4
    ]
    objA = new complexTest block, 0
    objB = new complexTest block, C.strideof complexTest
    deferred = []
    for j in [0..3]
      for i in [0..3]
        val = Math.random()
        objB.inner(j).vec i, val
        do (j, i, val) ->
          deferred.push -> objA.inner(j).vec(i).should.be.exactly fround val
    for i in [0..3]
      objA.inner(i, objB.inner(i))
    fn() for fn in deferred
    null
  it 'should allow complex pointer types to be read and write', ->
    complexTest = C.struct [
      C.ptr 'SubTest', 'inner'
    ]
    objA = new complexTest block, 0
    objB = new subTest block, C.strideof complexTest
    tailPtr = C.ref(objB).add(C.strideof subTest)
    objB.vec 0, 2.3
    objA.inner = C.ref objB
    objA.inner.deref(0).vec(0).should.be.exactly fround 2.3
    objA.inner = tailPtr
    deferred = []
    for j in [0..15]
      for i in [0..3]
        val = Math.random()
        objA.inner.deref(j).vec(i, val)
        do (j, i, val) ->
          deferred.push ->
            objA.inner.deref(j).vec(i).should.be.exactly fround val
    fn() for fn in deferred
    null
  it 'should handle nested pointers', ->
    aTest = C.struct [
      C.ptr 'float', 'one'
      C.ptr 'float', 'two'
    ]
    bTest = C.struct [
      C.ptr 'float', 'data', 2
    ]
    aObj = new aTest block, 0
    bObj = new bTest block, C.strideof aTest
    data = C.ref(bObj).add(C.strideof bTest).cast('float*')
    data.set(0, 2.3)
    data.set(1, 3.4)
    aObj.one = data
    aObj.two = data.add(4)
    bObj.data = C.ref(aObj, 'one')
    # not too comprehensive, but meh!
    bObj.data.deref(0, 0).should.be.exactly(fround 2.3)
    bObj.data.deref(0, 1).should.be.exactly(fround 3.4)
    bObj.data.deref(1, 0).should.be.exactly(fround 3.4)
    block.free()
