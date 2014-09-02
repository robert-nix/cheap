
## Introduction

### cheap.set64Bit(is64Bit)

Make `is64Bit` true to make pointers 8 bytes, false to make pointers 4 bytes.

This does not apply retroactively to previously defined structs; it is therefore
possible to mix 64-bit and 32-bit pointers in the same heap.

*"Pointer? Heap? Wtf?"*  The `cheap` object has a single, virtual heap
implemented as a doubly linked list of `block` objects.  These blocks have a
virtual start and end address (between [2^16, 2^31 - 2^16]) and contain an
ArrayBuffer representing allocated memory.  Even though any pointer into this
virtual heap can occupy at most 31 bits, it can be helpful to have 8-byte
pointers for mocking 64-bit C structures.  This library does not currently
support 64-bit integers because it's an unperformant pain in the ass, so all
pointers are read as 32-bit uints regardless of size.

Moving on, here's how to define a struct:

### cheap.struct(definition)

`definition` should be an array of member definitions.  Member definitions are
described in detail later, but as an example:

```js
var simple = cheap.struct([
  cheap.int('someInt'),
  cheap.float('someVec', 4),
  cheap.double('someNumbers')
]);
```

This is similar to, in C:

```c
struct simple {
  int someInt;
  float someVec[4];
  double *someNumbers;
};
```

To refer to the same memory with more than one type, aka union, definition
should be an object:

```js
var medium = cheap.struct({
  theInt: cheap.int(0),
  theFloat: cheap.float(0),
  theLow: cheap.int(8),
  theHigh: cheap.int(12),
  theDouble: cheap.double(8)
});
```

This is similar to, in C11:

```c
struct medium {
  union {
    int theInt;
    float theFloat;
  };
  union {
    struct {
      int theLow;
      int theHigh;
    };
    double theDouble;
  }
};
```

The object definition syntax **requires** an explicit offset for each member.
Since an object is not guaranteed to preserve the order of its members, the
array syntax is required to implicitly define member offsets.  To use the object
definition syntax, simply place the desired offset where the `memberName`
argument should be, and make the `memberName` the key to the appropriate member
definition.

## Struct member definitions

### cheap.{type}(memberName, [arrayLength])

Creates a struct member of type `{type}` with name `memberName`.  Optionally
specify arrayLength to make this an array member.

{type} may be any user-defined type (see below), or any of the default types:

- `uint`: 32-bit unsigned integer
- `int`: 32-bit signed integer
- `ushort`: 16-bit unsigned integer
- `short`: 16-bit signed integer
- `uchar`: 8-bit unsigned integer
- `char`: 8-bit signed integer
- `float`: 32-bit float
- `double`: 64-bit float
- `void`: undefined, cannot be dereferenced

### cheap.typedef(typeName, structDef)

Assigns the name `typeName` to `structDef`.  This defines the property with name
`typeName` on the `cheap` object.  To prevent name collisions, the cheap library
will never define a default property that starts with an uppercase letter on the
cheap object.  As a guideline, user-defined types should have an UpperCamelCase
name.  Once `typedef` is called, the defined type can be used in `cheap.{type}`
and `cheap.ptr` like any other type.

### cheap.ptr(typeName, memberName, [depth = 1])

Creates a struct member of a pointer to type `{typeName}` with name `memberName`
and depth (number of `*`s) `depth`.  Depth < 1 is currently Fundefined behavior.

## Struct objects

A struct object is created by `new`ing the function returned by `cheap.struct`
with a `block` (see Heap functions below) and a relative address into the block
as arguments:

```js
var block = cheap.malloc(0x1000);
var myObj = new simple(block, 0);
```

Once created, all the fields on the object can be read from and written to:

```js
myObj.someInt; // 0
myObj.someInt = 123;
myObj.someInt; // 123
// Let's overflow int32:
myObj.someInt = 1e10;
myObj.someInt; // 1410065408
// Array example:
myObj.someVec(2); // 0
myObj.someVec(2, 2.3);
myObj.someVec(2); // 2.29999...
// And we can escape the bounds of the array easily:
myObj.someVec(200, 1);
myObj.someVec(200); // 1
// But Fundefined behavior may occur:
myObj.someVec(1000, 1);
myObj.someVec(1000); // undefined
// Make someNumbers point to after the array (plus a few bytes for alignment)
myObj.someNumbers = cheap.ptr(block).add((cheap.sizeof(simple)+7)&-8);
myObj.someNumbers.set(23, 45);
myObj.someNumbers.deref(23); // 45
```

There is no type checking on value assignments.  Numeric types are implicitly
converted between one another by virtue of everything in javascript being a
double; assignments simply overflow when writing to words of too-short width.

### obj.{simple member}

Both basic and complex types can be read from and assigned to simple members of
struct objects.  Complex types are assigned using `cheap.memcpy`, so the
assigning member should be relocatable.

### obj.{array member}

Basic and complex array types are read and written using the member as a
`function(idx, [val])`:  `idx` is the array index, and, if writing to the array,
`val` is the desired value.

### obj.{pointer member}

The member is a `ptr` object.

### ptr.deref(idx, *)

Dereferences the ptr, subtracting 1 from its depth (i.e. the number of '*'s) and
returning the typed value if depth reaches 0.  `idx` acts the same as in an
array member.  If multiple arguments are supplied, each is treated as an `idx`
to dereference a the corresponding ptr.

### ptr.set(idx, val)

Sets the value at ptr[idx] to val.

### ptr.cast(type)

Casts the ptr to `type`.  If `type` is a string, it is interpreted as a defined
type and a series of '*'s afterwards will translate to pointer depth.  If no
'*'s are present in `type`, the depth will remain the same.  `type` may also be
a struct definition, in which case only the type may be changed.

## Struct helpers

### cheap.sizeof(type)

Gets the size of a type.  `type` may be a string representing one of the above
default types or a struct definition as returned by `cheap.struct`.

### cheap.alignof(type)

Gets the required alignment of a type.  `type` has the same requirements as
`cheap.sizeof`.

### cheap.strideof

Gets the array stride of a type, according to its size and alignment
requirements.  Rounds up `sizeof(type)` to the nearest multiple of
`alignof(type)`.

### cheap.ref(locatable, [memberName])

Gets a `ptr` object representing the address of the arguments.  `locatable` may
be a `block` returned by `cheap.malloc` or a struct object.  If `memberName` is
specified, the returned `ptr` will point to the corresponding member on
`locatable`.

## Heap functions

### cheap.malloc(size)

Allocates a heap `block` of `size` bytes.  Even if the return value isn't saved,
the heap block will remain on the virtual heap until it is freed.  This makes
leaking memory quite simple.  Always free blocks once they're no longer in use.
The `a` field on blocks is part of the public interface and will not change.

### block.free()

Frees the block, removing it from the heap.

### cheap.free(address)

Searches for a block in the heap starting at `address` and frees it.  If the
address is not the start of any block, no change will occur.

### cheap.memcpy(dst, src, size)

Copies heap memory of length `size` bytes from `dst` to `src`.

### cheap.getBufferAddress(address)

Returns [heap block, relative address] for absolute address `address`.
`address` may also be a `ptr` object.

### cheap.copyBuffer(buf)

Copies an ArrayBuffer `buf` onto the heap and returns the newly allocated block.
Useful for interacting with binary files, in particular.
