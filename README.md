## Funding

This library was originally incentivized by [ICDevs](https://ICDevs.org). You
can view more about the bounty on the
[forum](https://forum.dfinity.org/t/icdevs-org-bounty-18-cbor-and-candid-motoko-parser-3-000/11398)
or [website](https://icdevs.org/bounties/2022/02/22/CBOR-and-Candid-Motoko-Parser.html). The
bounty was funded by The ICDevs.org commuity and the award paid to
@Gekctek. If you use this library and gain value from it, please consider
a [donation](https://icdevs.org/donations.html) to ICDevs.

# Overview

This is a library that is written in Motoko that enables the encoding and decoding of CBOR between bytes and a CBOR variant type

# Package

### MOPS

```
mops install cbor
```

To setup MOPS package manage, follow the instructions from the [MOPS Site](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/)

# Usage

### Cbor Bytes -> Cbor Object

```
import Types "mo:cbor/Types";
import Decoder "mo:cbor/Decoder";

let bytes: [Nat8] = [0xbf, 0x63, 0x46, 0x75, 0x6e, 0xf5, 0x63, 0x41, 0x6d, 0x74, 0x21, 0xff];
let cbor: Types.Value = switch(Decoder.decodeBytes(bytes)) {
    case (#err(e)) ...;
    case (#ok(c)) c;
};
```

### Cbor Object -> Cbor Bytes

```
import Types "mo:cbor/Types";
import Encoder "mo:cbor/Encoder";

let bytes: Types.Value = #majorType5([
    (#majorType3("Fun"), #majorType7(#bool(true))),
    (#majorType3("Amt"), #majorType1(-2))
]);
let bytes: [Nat8] = switch(Encoder.encode(bytes)) {
    case (#err(e)) ...;
    case (#ok(c)) c;
};

```

### Custom Type -> Cbor Bytes

_Not Yet Implemented_
use `to_candid(...)`. See https://internetcomputer.org/docs/current/developer-docs/build/cdks/motoko-dfinity/language-manual#candid-serialization

### Cbor Bytes -> Custom Type

_Not Yet Implemented_
use `from_candid(...)`. See https://internetcomputer.org/docs/current/developer-docs/build/cdks/motoko-dfinity/language-manual#candid-serialization

# API

## Decoder.mo

`decode(blob: Blob) : Result.Result<Types.Value, Types.DecodingError>`

Decodes a blob into a cbor value variant

`decodeBytes(bytes: Iter.Iter<Nat8>) : Result.Result<Types.Value, Types.DecodingError>`

Decodes a series of bytes into a cbor value variant

## Encoder.mo

`encode(value: Types.Value) : Result.Result<[Nat8], Types.EncodingError>`

Encodes a cbor value into a byte array

`encodeToBuffer(buffer: Buffer.Buffer<Nat8>, value: Types.Value) : Result.Result<(), Types.EncodingError>`

Encodes a cbor value into the supplied byte buffer

# FloatX: Half(16), Single(32), Double(64)

Due to the lack of float functionality (`float <-> bytes`, `half`, `single`) and external reference was used for these. `xtended-numbers` in vessel or `github.com/gekctek/motoko_numbers`

# Testing

```
mops test
```