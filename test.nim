
import bytes
import random
import strutils

randomize()

template testOrdinal(typ : untyped, tname : string = "", rangemax : int = 1_000_000, ) = 
  var n : typ = 0
  var un : typ = 0
  var i : int64 = 0
  var s : string

  echo "Starting test $1, $2 iterations" % [tname, $rangemax]

  for i in 1..rangemax:
    n = cast[typ](random(high(int)))
    s = pack(n)
    unpack_into(un, s)
    assert(n == un)

  echo "Passed"

proc testString(lenrange : Slice = 0..100, iterations : int = 1_000_000) = 
  var n : string
  var s : string
  var un : string

  echo "Testing string"

  proc generateGibberish() = 
    var ln : int = random(lenrange)
    n = ""
    for i in 0..ln-1:
      n = n & chr(random(int(high(uint8))))

  proc checkStrings(s1, s2 : string) : bool = 
    if len(s1) != len(s2):
      echo "Lengths differ"
      return false

    for i in 0..len(s1)-1:
      if s1[i] != s2[i]:
        echo "Strings differ"
        return false
    return true

  for i in 1..iterations:
    generateGibberish()
    s = pack(n)
    unpack_into(un, s)
    assert(checkStrings(n, un))

  echo "Passed"

proc generateGibberishSeq[T](lenrange : Slice, o : var seq[T]) = 
  var ln : int = random(lenrange)
  o = @[]
  for i in 0..ln-1:
    o.add(cast[T](random(high(int))))

proc checkSeqs[T](s1, s2 : seq[T]) : bool = 
  if len(s1) != len(s2):
    echo "Lengths differ"
    return false

  for i in 0..len(s1)-1:
    if s1[i] != s2[i]:
      echo "Seqs differ"
      return false
  return true

template testSeq(typ : untyped, tname : string, lenrange : Slice = 0..100, iterations : int = 1_000_000) = 
  var n : seq[typ]
  var s : string
  var un : seq[typ]

  echo "Testing sequence of type $1" % tname

  for i in 1..iterations:
    generateGibberishSeq(lenrange, n)
    s = pack(n)
    unpack_into(un, s)
    assert(checkSeqs(n, un))

  echo "Passed"


testOrdinal(uint32, "uint32")
testOrdinal(int32, "int32")

testOrdinal(uint16, "uint16")
testOrdinal(int16, "int16")

testOrdinal(uint8, "uint8")
testOrdinal(int8, "int8")

testString()

testSeq(uint8, "uint8")
testSeq(int8, "int8")

testSeq(uint16, "uint16")
testSeq(int16, "int16")

testSeq(uint32, "uint32")
testSeq(int32, "int32")

