/**
 * cheap.js - C-like memory layout for javascript
 * version 0.1.0
 * Copyright 2014 Robert Nix
 * MIT License
 */
(function() {
  var C, addressMax, addressMin, block, makeAccessors, makeStructMember, pointerShift, pointerSize, ptr,
    __slice = [].slice;

  C = {};

  makeStructMember = function(typeName, pointerDepth, memberName, arrayLength, offset) {
    return {
      typeName: typeName,
      pointerDepth: pointerDepth,
      memberName: memberName,
      offset: offset,
      arrayLength: arrayLength,
      isArray: arrayLength != null
    };
  };

  C._typedefs = {};

  C.typedef = function(typeName, structDef) {
    if (typeName in C) {
      throw new Error('name collides');
    }
    C._typedefs[typeName] = structDef;
    return C[typeName] = function(memberName, arrayLength) {
      if (typeof memberName === 'string') {
        return makeStructMember(typeName, 0, memberName, arrayLength);
      } else {
        return makeStructMember(typeName, 0, void 0, arrayLength, memberName);
      }
    };
  };

  C.ptr = function(typeName, memberName, pointerDepth) {
    if (pointerDepth == null) {
      pointerDepth = 1;
    }
    return makeStructMember(typeName, pointerDepth, memberName);
  };

  C.typedef('uint');

  C.typedef('int');

  C.typedef('ushort');

  C.typedef('short');

  C.typedef('uchar');

  C.typedef('char');

  C.typedef('float');

  C.typedef('double');

  C.typedef('void');

  pointerSize = 4;

  pointerShift = 2;

  C.set64Bit = function(is64Bit) {
    if (is64Bit) {
      pointerSize = 8;
      return pointerShift = 3;
    } else {
      pointerSize = 4;
      return pointerShift = 2;
    }
  };

  C._typeNameToId = function(n) {
    switch (n) {
      case 'uint':
        return 0;
      case 'int':
        return 1;
      case 'ushort':
        return 2;
      case 'short':
        return 3;
      case 'uchar':
        return 4;
      case 'char':
        return 5;
      case 'float':
        return 6;
      case 'double':
        return 7;
      default:
        return -1;
    }
  };

  C._arrayName = function(t) {
    switch (t) {
      case 0:
      case 'uint':
        return 'ui32';
      case 1:
      case 'int':
        return 'i32';
      case 2:
      case 'ushort':
        return 'ui16';
      case 3:
      case 'short':
        return 'i16';
      case 4:
      case 'uchar':
        return 'ui8';
      case 5:
      case 'char':
        return 'i8';
      case 6:
      case 'float':
        return 'f32';
      case 7:
      case 'double':
        return 'f64';
      default:
        return 'ui32';
    }
  };

  C._arrayElSize = function(t) {
    switch (t) {
      case 0:
      case 'uint':
      case 1:
      case 'int':
        return 4;
      case 2:
      case 'ushort':
      case 3:
      case 'short':
        return 2;
      case 4:
      case 'uchar':
      case 5:
      case 'char':
        return 1;
      case 6:
      case 'float':
        return 4;
      case 7:
      case 'double':
        return 8;
      default:
        return pointerSize;
    }
  };

  C._arrayElShift = function(t) {
    switch (t) {
      case 0:
      case 'uint':
      case 1:
      case 'int':
      case 6:
      case 'float':
        return 2;
      case 2:
      case 'ushort':
      case 3:
      case 'short':
        return 1;
      case 4:
      case 'uchar':
      case 5:
      case 'char':
        return 0;
      case 7:
      case 'double':
        return 3;
      default:
        return pointerShift;
    }
  };

  C.sizeof = function(type) {
    if (typeof type === 'string') {
      switch (type) {
        case 'char':
        case 'uchar':
          return 1;
        case 'short':
        case 'ushort':
          return 2;
        case 'int':
        case 'uint':
        case 'float':
          return 4;
        case 'double':
          return 8;
        case 'void*':
          return pointerSize;
        default:
          return 1;
      }
    } else {
      return type.__size;
    }
  };

  C.strideof = function(type) {
    if (typeof type === 'string') {
      return C.sizeof(type);
    } else {
      return (type.__size + type.__align - 1) & -type.__align;
    }
  };

  C.alignof = function(type) {
    if (typeof type === 'string') {
      return C.sizeof(type);
    } else {
      return type.__align;
    }
  };

  makeAccessors = function(def) {
    var T, align, arr, basic, cName, elShift, member, offset, pd, size, stride, type, typeId;
    offset = def.offset, member = def.member, type = def.type, stride = def.stride, align = def.align, size = def.size;
    basic = typeof type === 'string';
    typeId = C._typeNameToId(type);
    arr = C._arrayName(type);
    elShift = C._arrayElShift(type);
    if (member.pointerDepth === 0 && !member.isArray) {
      if (basic) {
        return {
          get: function() {
            return this.__b[arr][(this.__a + offset) >> elShift];
          },
          set: function(x) {
            return this.__b[arr][(this.__a + offset) >> elShift] = x;
          }
        };
      } else {
        cName = '__c_' + member.memberName;
        return {
          get: function() {
            var res;
            if (this[cName] != null) {
              return this[cName];
            } else {
              res = new type.__ctor(this.__b, this.__a + offset);
              this[cName] = res;
              return res;
            }
          },
          set: function(x) {
            return C.memcpy(this.__b, this.__a + offset, x.__b, x.__a, size);
          }
        };
      }
    } else if (member.pointerDepth === 0) {
      if (basic) {
        return {
          get: function() {
            var bIdx;
            bIdx = (this.__a + offset) >> elShift;
            return (function(_this) {
              return function(idx, val) {
                if (val == null) {
                  return _this.__b[arr][bIdx + idx];
                } else {
                  return _this.__b[arr][bIdx + idx] = val;
                }
              };
            })(this);
          }
        };
      } else {
        return {
          get: function() {
            return (function(_this) {
              return function(idx, val) {
                var bOff;
                bOff = _this.__a + offset + idx * stride;
                if (val == null) {
                  return new type.__ctor(_this.__b, bOff);
                } else {
                  return C.memcpy(_this.__b, bOff, val.__b, val.__a, size);
                }
              };
            })(this);
          }
        };
      }
    } else {
      T = typeId;
      if (T < 0) {
        T = type;
      }
      pd = member.pointerDepth;
      return {
        get: function() {
          var addr;
          addr = this.__b.ui32[(this.__a + offset) / 4];
          return new ptr(addr, T, pd);
        },
        set: function(x) {
          return this.__b.ui32[(this.__a + offset) / 4] = x.a;
        }
      };
    }
  };

  C.struct = function(def) {
    var align, end, member, name, offset, size, stride, struct, type, _i, _len, _type;
    struct = function() {
      return struct.__ctor.apply(this, arguments);
    };
    struct.__size = 0;
    struct.__align = 1;
    if (Array.isArray(def)) {
      for (_i = 0, _len = def.length; _i < _len; _i++) {
        member = def[_i];
        type = C._typedefs[member.typeName] || member.typeName;
        _type = type;
        if (member.pointerDepth > 0) {
          _type = 'void*';
        }
        size = C.sizeof(_type);
        align = C.alignof(_type);
        stride = (size + align - 1) & -align;
        if (member.isArray) {
          size += stride * (member.arrayLength - 1);
        }
        struct.__size = (struct.__size + align - 1) & -align;
        offset = struct.__size;
        struct.__size += size;
        if (align > struct.__align) {
          struct.__align = align;
        }
        struct[member.memberName] = {
          offset: offset,
          member: member,
          type: type,
          stride: stride,
          align: align,
          size: size
        };
      }
    } else {
      for (name in def) {
        member = def[name];
        type = C._typedefs[member.typeName] || member.typeName;
        _type = type;
        if (member.pointerDepth > 0) {
          _type = 'void*';
        }
        member.memberName = name;
        size = C.sizeof(_type);
        align = C.alignof(_type);
        stride = (size + align - 1) & -align;
        if (member.isArray) {
          size += stride * (member.arrayLength - 1);
        }
        offset = member.offset;
        end = offset + size;
        if (end > struct.__size) {
          struct.__size = end;
        }
        if (align > struct.__align) {
          struct.__align = align;
        }
        struct[member.memberName] = {
          offset: offset,
          member: member,
          type: type,
          stride: stride,
          align: align,
          size: size
        };
      }
    }
    struct.__ctor = function(buffer, address) {
      this.__b = buffer;
      this.__a = address;
      return this;
    };
    struct.__ctor.prototype = (function() {
      var k, result, v;
      result = {
        __t: struct
      };
      for (k in struct) {
        v = struct[k];
        if (k.substr(0, 2) !== '__') {
          Object.defineProperty(result, k, makeAccessors(v));
        }
      }
      return result;
    })();
    struct.prototype = struct.__ctor.prototype;
    return struct;
  };

  C._heapLast = null;

  block = function(addr, size, prev, next) {
    var buf;
    this.a = addr;
    this.l = size;
    this.e = addr + size;
    this.prev = prev;
    if (prev != null) {
      prev.next = this;
    }
    this.next = next;
    if (next != null) {
      next.prev = this;
    }
    this.buf = buf = new ArrayBuffer(size);
    this.ui32 = new Uint32Array(buf);
    this.i32 = new Int32Array(buf);
    this.ui16 = new Uint16Array(buf);
    this.i16 = new Int16Array(buf);
    this.ui8 = new Uint8Array(buf);
    this.i8 = new Int8Array(buf);
    this.f32 = new Float32Array(buf);
    this.f64 = new Float64Array(buf);
    return this;
  };

  block.prototype.free = function() {
    if (this === C._heapLast) {
      C._heapLast = this.prev;
    }
    if (this.prev != null) {
      this.prev.next = this.next;
    }
    if (this.next != null) {
      this.next.prev = this.prev;
    }
  };

  addressMin = 0x00010000;

  addressMax = 0x7fff0000;

  C.malloc = function(size) {
    var addr, b, curr, min, room, _ref;
    if (size < 0) {
      throw new Error('invalid allocation size');
    }
    size = (size + 0xf) & -0x10;
    if (C._heapLast === null) {
      if (size + addressMin > addressMax) {
        throw new Error('invalid allocation size');
      }
      return C._heapLast = new block(addressMin, size, null, null);
    } else {
      curr = C._heapLast;
      if (size + curr.e <= addressMax) {
        addr = curr.e;
        return C._heapLast = new block(addr, size, curr, null);
      } else {
        b = null;
        while (true) {
          min = ((_ref = curr.prev) != null ? _ref.e : void 0) || addressMin;
          room = curr.a - min;
          if (room >= size) {
            addr = curr.a - size;
            b = new block(addr, size, curr.prev, curr);
            break;
          }
          curr = curr.prev;
          if (curr == null) {
            throw new Error('heap space not available');
          }
        }
        return b;
      }
    }
  };

  C.free = function(addr) {
    var curr;
    if (typeof addr === 'object') {
      return addr.free();
    }
    if (addr < addressMin) {
      return;
    }
    if (addr >= addressMax) {
      return;
    }
    curr = C._heapLast;
    while (true) {
      if (curr == null) {
        break;
      }
      if (curr.a === addr) {
        return curr.free();
      }
      curr = curr.prev;
    }
  };

  C.getBufferAddress = function(addr) {
    var curr;
    if (typeof addr === 'object') {
      addr = addr.a;
    }
    curr = C._heapLast;
    while (true) {
      if (curr == null) {
        break;
      }
      if (curr.e > addr && curr.a <= addr) {
        return [curr, addr - curr.a];
      }
      curr = curr.prev;
    }
    return [null, 0];
  };

  C._getHeapValue = function(addr, t) {
    var buf, rva, _ref;
    _ref = C.getBufferAddress(addr), buf = _ref[0], rva = _ref[1];
    switch (t) {
      case 0:
        return buf.ui32[0 | rva / 4];
      case 1:
        return buf.i32[0 | rva / 4];
      case 2:
        return buf.ui16[0 | rva / 2];
      case 3:
        return buf.i16[0 | rva / 2];
      case 4:
        return buf.ui8[0 | rva];
      case 5:
        return buf.i8[0 | rva];
      case 6:
        return buf.f32[0 | rva / 4];
      case 7:
        return buf.f64[0 | rva / 8];
      default:
        return buf.ui32[0 | rva / 4];
    }
  };

  C._setHeapValue = function(addr, t, v) {
    var buf, rva, _ref;
    _ref = C.getBufferAddress(addr), buf = _ref[0], rva = _ref[1];
    switch (t) {
      case 0:
        return buf.ui32[0 | rva / 4] = v;
      case 1:
        return buf.i32[0 | rva / 4] = v;
      case 2:
        return buf.ui16[0 | rva / 2] = v;
      case 3:
        return buf.i16[0 | rva / 2] = v;
      case 4:
        return buf.ui8[0 | rva] = v;
      case 5:
        return buf.i8[0 | rva] = v;
      case 6:
        return buf.f32[0 | rva / 4] = v;
      case 7:
        return buf.f64[0 | rva / 8] = v;
      default:
        return buf.ui32[0 | rva / 4] = v;
    }
  };

  C.memcpy = function(dstBuf, dstRva, srcBuf, srcRva, size) {
    var dstAddr, srcAddr, _ref, _ref1;
    if (size == null) {
      dstAddr = dstBuf;
      srcAddr = dstRva;
      size = srcBuf;
      _ref = C.getBufferAddress(dstAddr), dstBuf = _ref[0], dstRva = _ref[1];
      _ref1 = C.getBufferAddress(srcAddr), srcBuf = _ref1[0], srcRva = _ref1[1];
    }
    return dstBuf.ui8.set(srcBuf.ui8.subarray(srcRva, srcRva + size), dstRva);
  };

  C.copyBuffer = function(buf) {
    var res;
    res = C.malloc(buf.byteLength);
    res.ui8.set(new Uint8Array(buf), 0);
    return res;
  };

  ptr = function(a, t, p) {
    this.a = a;
    this.t = t;
    this.p = p;
    return this;
  };

  ptr.prototype.deref = function() {
    var buf, currAddr, head, nextDepth, nextObj, nextPtr, rva, tail, _ref;
    head = arguments[0], tail = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    nextDepth = this.p - 1;
    currAddr = this.a;
    head || (head = 0);
    if (nextDepth === 0) {
      if (typeof this.t === 'number') {
        return C._getHeapValue(currAddr + head * C._arrayElSize(this.t), this.t);
      } else {
        _ref = C.getBufferAddress(currAddr + head * C.sizeof(this.t)), buf = _ref[0], rva = _ref[1];
        return new this.t(buf, rva);
      }
    } else {
      nextPtr = C._getHeapValue(currAddr + head * pointerSize, 0);
      nextObj = new ptr(nextPtr, this.t, nextDepth);
      if (tail.length > 0) {
        return this.deref.apply(nextObj, tail);
      } else {
        return nextObj;
      }
    }
  };

  ptr.prototype.set = function(idx, val) {
    var currAddr, dstBuf, dstRva, nextDepth, _ref;
    nextDepth = this.p - 1;
    currAddr = this.a;
    if (nextDepth < 0) {
      throw new Error('bad pointer');
    }
    if (nextDepth === 0) {
      if (typeof this.t === 'number') {
        return C._setHeapValue(currAddr + idx * C._arrayElSize(this.t), this.t, val);
      } else {
        _ref = C.getBufferAddress(currAddr + idx * C.sizeof(this.t)), dstBuf = _ref[0], dstRva = _ref[1];
        return C.memcpy(dstBuf, dstRva, val.__b, val.__a, C.sizeof(this.t));
      }
    } else {
      return C._setHeapValue(currAddr + idx * pointerSize, 0, val.a);
    }
  };

  ptr.prototype.cast = function(type) {
    var p, tId;
    if (typeof type === 'string') {
      type = type.split('*');
      p = type.length - 1;
      if (p === 0) {
        p = this.p;
      }
      tId = C._typeNameToId(type[0]);
      if (tId < 0) {
        tId = C._typeDefs[type[0]];
      }
      return new ptr(this.a, tId, p);
    } else {
      return new ptr(this.a, type, this.p);
    }
  };

  C.ref = function(locatable, memberName) {
    var a, p, t;
    if (locatable.__t != null) {
      t = locatable.__t;
      a = locatable.__a + locatable.__b.a;
      p = 1;
      if (memberName != null) {
        a += t[memberName].offset;
        p += t[memberName].pointerDepth;
        t = t[memberName].type;
      }
      return new ptr(a, t, p);
    } else {
      return new ptr(locatable.a, 'void*', 1);
    }
  };

  ptr.prototype.add = function(offset) {
    return new ptr(this.a + offset, this.t, this.p);
  };

  if (typeof module === 'object' && typeof module.exports === 'object') {
    module.exports = C;
  } else if (typeof define === 'function' && define.amd) {
    define(['cheap'], function() {
      return this.cheap = C;
    });
  } else {
    this.cheap = C;
  }

}).call(this);
