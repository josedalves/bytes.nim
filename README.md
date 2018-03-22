
# bytes.nim - Pack NIM values into byte streams

This module provides utilities for packing NIM values into byte streams.

It is heavily inspired by Python's "struct" module, but tries to remain
type safe and idiomatic as much as possible.

**NOTE** This is a work in progress. Features, such as endianess support, 
support for more types (namely tuples) and ref/ptr support are not yet
implemented.

Also, if anything goes wrong with the macro, the error descriptiong is
**EXTREMELY** unfriendly (working on that).

Caveat programmer!

# Installing

To install:

    nimble install

To generate documentation:

   nim doc bytes.nim

A file named "bytes.html" will be generated

# Testing

Proper unit tests haven't been developed, but a test script is included.

To test:
    nim c -r tests.nim

If all tests pass, program exits with code 0.

# Using

A simple example - packing and unpacking an integer:

    ## packing an integer
    var someinteger : int32 = 2000
    var packed : string = pack(someinteger)
    
    ## ... later, unpacking this integer
    var unpacked : int32
    unpack_into(unpacked, packed)
    assert(unpacked == someinteger) #<- this will succeed!

A more complex example - packing and unpacking an object:

    ## An example object:
    type
        MyObject = object
            a : int
            b : string
            c : seq[int]

    var mo : MyObject

    ## Populating object with values
    mo.a = 200
    mo.b = "blah blah blah"
    mo.c = @[10, 20, 30]

    ## Packing
    var packed = pack(mo)

    ## Unpacking
    var unpacked : MyObject
    unpack_into(unpacked, packed)

The pack/unpack functions are smart enough to deal with nested objects:

    ## An example object:
    type
        MyObject = object
            field : float
        YourObject = object
            somefield : int

        TheObjects = object
            m : MyObject
            y : YourObject

    var to : TheObjects
    to.m.filed = 3.2
    to.y.somefiled = 400

    var packed = pack(to)
    var unpacked : TheObjects
    unpack_into(unpacked, packed)

    ## These must not fail!!!
    assert(to.m.field == unpacked.m.field)
    assert(to.y.somefield == unpacked.m.somefield)

