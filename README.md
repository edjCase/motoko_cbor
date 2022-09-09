# Usage

### Cbor Bytes -> Cbor Object

```
import Types "mo:cbor/Types";
import CborDecoder "mo:cbor/CborDecoder";

let bytes: [Nat8] = [0xbf, 0x63, 0x46, 0x75, 0x6e, 0xf5, 0x63, 0x41, 0x6d, 0x74, 0x21, 0xff];
let cbor: Types.CborValue = switch(CborDecoder.decodeBytes(bytes)) {
    case (#err(e)) ...;
    case (#ok(c)) c;
};
```

### Cbor Object -> Cbor Bytes

```
import Types "mo:cbor/Types";
import CborEncoder "mo:cbor/CborEncoder";

let bytes: Types.CborValue = #majorType5([
    (#majorType3("Fun"), #majorType7(#bool(true))),
    (#majorType3("Amt"), #majorType1(-2))
]);
let bytes: [Nat8] = switch(CborEncoder.encode(bytes)) {
    case (#err(e)) ...;
    case (#ok(c)) c;
};

```

### Custom Type -> Cbor Bytes

_Not Yet Implemented_

### Cbor Bytes -> Custom Type

_Not Yet Implemented_

# FloatX: Half(16), Single(32), Double(64)

Due to the lack of float implementations both the `float <-> bytes` and `half` and `single` had to be implemented. All implemetation of this is located in the `FloatX.mo` file

# Library Devlopment:

## First time setup

To build the library, the `Vessel` library must be installed. It is used to pull down packages and locate the compiler for building.

https://github.com/dfinity/vessel

## Building

To build, run the `./build.sh` file.
It uses the entry point of

## Running

The only

## Testing

To run tests, use the `./test.sh` file.
The entry point for all tests is `test/Tests.mo` file
It will compile the tests to a wasm file and then that file will be executed.
Currently there are no testing frameworks and testing will stop at the first broken test. It will then output the error to the console

## TODO

- Better perfomance. Maybe use buffers instead of generating [Nat8] and concatinating them?
- Proper serialization. Specifiying a type and properly serializing/deserializing it. Also custom serializers to override/customize serialization
- Consistant naming and styling
