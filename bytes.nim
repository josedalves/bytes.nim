
##-------------------------------------------------------------------------------
##bytes.nim - Pack NIM values into byte streams
##-------------------------------------------------------------------------------
##
##This module provides utilities for packing NIM values into byte streams.
##
##It is heavilty inspired by Python's "struct" module, but tries to remain
##type safe as much as possible.
##
##However, be aware that these utilities are inherently unsafe, since it
##is impossible to determine what a byte stream is until you actually unpack
##it.
##
##Here is an example of use::
##
##    ## packing an integer
##    var someinteger : int32 = 2000
##    var packed : string = pack(someinteger)
##
##    ## ... later, unpacking this integer
##    var unpacked : int32
##    unpack_into(unpacked, packed)
##    assert(unpacked == someinteger) #<- this will succeed!
##
##
##
##**THIS IS A WORK IN PROGRESS**

import streams
import macros
import strutils
export streams

#TODO: Handle endianness


#-- Pack ----------------------------------------------------------------------

proc doPack*[T : SomeNumber | Ordinal](stream : var StringStream, endianness : Endianness, value : T) = 
  ##Low level packing proc for integers, floars and enums.
  ##
  ##Don't use this directly. Use the **pack** macro below
  var buf : array[sizeof(value), uint8] = cast[array[sizeof(value), uint8]](value)
  stream.write(buf)

proc doPack*[T : array](stream : var StringStream, endianness : Endianness, value : T) = 
  ##Low level packing proc for arrays
  ##
  ##Don't use this directly. Use the **pack** macro below
  for item in value:
    doPack(stream, endianness, item)

proc doPack*[T : seq](stream : var StringStream, endianness : Endianness, value : T) = 
  ##Low level packing proc for seq
  ##
  ##Don't use this directly. Use the **pack** macro below
  var sz : int32 = int32(value.len())
  doPack(stream, endianness, sz)
  for item in value:
    doPack(stream, endianness, item)

proc doPack*[T : set](stream : var StringStream, endianness : Endianness, value : T) = 
  ##Low level packing proc for set
  ##
  ##Don't use this directly. Use the **pack** macro below
  var sz : int32 = int32(value.card())
  doPack(stream, endianness, sz)
  for item in value:
    doPack(stream, endianness, item)

proc doPack*(stream : var StringStream, endianness : Endianness, value : string) = 
  ##Low level packing proc for string
  ##
  ##Don't use this directly. Use the **pack** macro below
  var sz : int32 = int32(value.len())
  doPack(stream, endianness, sz)
  stream.write(value)

#-- Unpack --------------------------------------------------------------------

proc doUnpack*[T : SomeNumber | SomeOrdinal](stream : var StringStream, endianness : Endianness, value : var T) = 
  ##Low level unpacking proc for ints, floats, bools and enums
  ##
  ##Don't use this directly. Use the **unpack** macro below
  var n : array[sizeof(T), uint8]
  for i in 0..sizeof(T)-1:
    n[i] = cast[uint8](stream.readChar())
  value = cast[T](n)

proc doUnpack*[S, T](stream : var StringStream, endianness : Endianness, value : var array[S, T]) = 
  ##Low level unpacking proc for arrays
  ##
  ##Don't use this directly. Use the **unpack** macro below
  for i in 0..len(value)-1:
    doUnpack[T](stream, endianness, value[i])

proc doUnpack*(stream : var StringStream, endianness : Endianness, value : var string) = 
  ##Low level unpacking proc for strings
  ##
  ##Don't use this directly. Use the **unpack** macro below
  var l : int32
  value = "" #HACK!
  doUnpack(stream, endianness, l)
  for i in 0..l-1:
    value.add(stream.readChar())

proc doUnpack*[T](stream : var StringStream, endianness : Endianness, value : var seq[T]) = 
  ##Low level unpacking proc for seqs
  ##
  ##Don't use this directly. Use the **unpack** macro below
  var l : int32
  var n : T
  value = @[] #HACK!
  doUnpack(stream, endianness, l)
  for i in 0..l-1:
    doUnpack[T](stream, endianness, n)
    value.add(n)

#-- Macros --------------------------------------------------------------------

proc printTree(t : NimNode, indent = 0) = 
  ##Debugging. Ignore me!
  echo repeat("-", indent) & $t.kind & ", " & $t.typeKind
  for n in t.children:
    printTree(n, indent+1)

proc nnToStr(n : NimNode) : string = 
  return $n.toStrLit()


proc expandChildren(t : NimNode, dotexpr : NimNode) : seq[NimNode] {.compileTime.} = 
  result = @[]

  printTree(t)
  for n in t[2]:
    #echo "knd " & $n.kind
    #echo getType(n).kind
    if getType(n).kind == nnkObjectTy:
      result = result & expandChildren(getType(n), newDotExpr(dotexpr, n) ) 
    else:
      result.add(newDotExpr(dotexpr, n))

macro pack*(value : typed, endianness : typed = cpuEndian) : untyped =
  ##Pack a value
  ##
  ##This macro takes a NIM value and turns into a byte stream (string).
  ##
  ##value: The value to convert
  ##
  ##endianness (optional): Endianess to use on conversion. By default,
  ##the system's endianness is used
  ##
  var n = newNimNode(nnkStmtList, value)
  var blk = newBlockStmt(n)

  n.add(
    newVarStmt(
      newIdentNode("stream"), newCall("newStringStream")
    )
  )

  #doPack(stream, endianness, value)
  if getType(value).kind == nnkObjectTy:
    for c in expandChildren(getType(value), value):
      n.add(newCall("doPack", ident("stream"), endianness,  c))
  else:
      n.add(newCall("doPack", ident("stream"), endianness,  value))

  #stream.setPosition(0)
  n.add(
    newCall(
      newDotExpr(ident("stream"), ident("setPosition")),
      newIntLitNode(0)
    )
  )

  #stream.readAll()
  n.add(
    newCall(
      newDotExpr(ident("stream"), ident("readAll"))
    )
  )

  result = newNimNode(nnkStmtListExpr)
  result.add(blk)
  echo nnToStr(result)

macro unpack_into*(value : typed, packed : typed, endianness : typed = cpuEndian) : untyped = 
  ##Unpack a value
  ##
  ##value: The destination to unpack into (must be "var" and must be allocated)
  ##
  ##packed: The string containing the packed data
  ##
  ##endianness (optional): Endianess to use on conversion. By default,
  ##the system's endianness is used
  ##
  var n = newNimNode(nnkStmtList)
  var blk = newBlockStmt(n)

  #var stream = newStringStream()
  n.add(
    newVarStmt(
      newIdentNode("stream"), newCall("newStringStream", packed)
    )
  )

  #stream.setPosition(0)
  n.add(
    newCall(
      newDotExpr(ident("stream"), ident("setPosition")),
      newIntLitNode(0)
    )
  )

  #doUnpack
  if getType(value).kind == nnkObjectTy:
    for c in expandChildren(getType(value), value):
      n.add(newCall("doUnpack", ident("stream"), endianness, c))
  else:
    n.add(newCall("doUnpack", ident("stream"), endianness, value))

  result = newNimNode(nnkStmtListExpr)
  result.add(blk)
  echo nnToStr(result)

