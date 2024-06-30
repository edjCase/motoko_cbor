import NatX "mo:xtended-numbers/NatX";
import FloatX "mo:xtended-numbers/FloatX";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Types "./Types";

module {
  /// Encodes a CBOR value into a byte array.
  ///
  /// ```motoko
  /// let value : Types.Value = #majorType0(123);
  /// let result = CborEncoder.encode(value);
  /// switch (result) {
  ///   case (#ok(bytes)) { /* Use encoded bytes */ };
  ///   case (#err(error)) { /* Handle error */ };
  /// };
  /// ```
  public func encode(value : Types.Value) : Result.Result<[Nat8], Types.EncodingError> {
    let buffer = Buffer.Buffer<Nat8>(10);
    switch (encodeToBuffer(buffer, value)) {
      case (#ok) #ok(Buffer.toArray(buffer));
      case (#err(e)) #err(e);
    };
  };

  /// Encodes a CBOR value into a provided buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let value : Types.Value = #majorType0(123);
  /// let result = CborEncoder.encodeToBuffer(buffer, value);
  /// switch (result) {
  ///   case (#ok) { /* Encoding successful */ };
  ///   case (#err(error)) { /* Handle error */ };
  /// };
  /// ```
  public func encodeToBuffer(buffer : Buffer.Buffer<Nat8>, value : Types.Value) : Result.Result<(), Types.EncodingError> {
    switch (value) {
      case (#majorType0(t0)) encodeMajorType0(buffer, t0);
      case (#majorType1(t1)) encodeMajorType1(buffer, t1);
      case (#majorType2(t2)) encodeMajorType2(buffer, t2);
      case (#majorType3(t3)) encodeMajorType3(buffer, t3);
      case (#majorType4(t4)) encodeMajorType4(buffer, t4);
      case (#majorType5(t5)) encodeMajorType5(buffer, t5);
      case (#majorType6(t6)) encodeMajorType6(buffer, t6.tag, t6.value);
      case (#majorType7(t7)) {
        switch (t7) {
          case (#_break) return #err(#invalidValue("Break is not allowed as a value"));
          case (#_null) encodeMajorType7(buffer, #_null);
          case (#_undefined) encodeMajorType7(buffer, #_undefined);
          case (#bool(b)) encodeMajorType7(buffer, #bool(b));
          case (#float(f)) encodeMajorType7(buffer, #float(f));
          case (#integer(i)) encodeMajorType7(buffer, #integer(i));
        };
      };
    };
  };

  /// Encodes a Major Type 0 (unsigned integer) CBOR value.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let result = CborEncoder.encodeMajorType0(buffer, 123);
  /// // buffer now contains the encoded CBOR for unsigned integer 123
  /// ```
  public func encodeMajorType0(buffer : Buffer.Buffer<Nat8>, value : Nat64) : Result.Result<(), Types.EncodingError> {
    encodeNatHeaderInternal(buffer, 0, value);
    return #ok();
  };

  /// Encodes a Major Type 1 (negative integer) CBOR value.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let result = CborEncoder.encodeMajorType1(buffer, -10);
  /// // buffer now contains the encoded CBOR for negative integer -10
  /// ```
  public func encodeMajorType1(buffer : Buffer.Buffer<Nat8>, value : Int) : Result.Result<(), Types.EncodingError> {
    let maxValue : Int = -1;
    let minValue : Int = -0x10000000000000000;
    if (value > maxValue or value < minValue) {
      return #err(#invalidValue("Major type 1 values must be between -2^64 and -1"));
    };
    // Convert negative number (-1 - N) to Nat (N) to store as bytes
    let natValue : Nat = Int.abs(value + 1);
    encodeNatHeaderInternal(buffer, 1, Nat64.fromNat(natValue));
    return #ok();
  };

  /// Encodes a Major Type 2 (byte string) CBOR value.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let byteString : [Nat8] = [0x01, 0x02, 0x03];
  /// let result = CborEncoder.encodeMajorType2(buffer, byteString);
  /// // buffer now contains the encoded CBOR for byte string [0x01, 0x02, 0x03]
  /// ```
  public func encodeMajorType2(buffer : Buffer.Buffer<Nat8>, value : [Nat8]) : Result.Result<(), Types.EncodingError> {
    // Value is header bits + value bytes
    // Header is major type and value byte length
    let byteLength : Nat64 = Nat64.fromNat(value.size());
    encodeNatHeaderInternal(buffer, 2, byteLength);
    for (b in Iter.fromArray(value)) {
      buffer.add(b);
    };
    #ok();
  };

  /// Encodes a Major Type 3 (text string) CBOR value.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let result = CborEncoder.encodeMajorType3(buffer, "Hello, CBOR!");
  /// // buffer now contains the encoded CBOR for text string "Hello, CBOR!"
  /// ```
  public func encodeMajorType3(buffer : Buffer.Buffer<Nat8>, value : Text) : Result.Result<(), Types.EncodingError> {

    // Value is header bits + utf8 encoded string bytes
    // Header is major type and utf8 byte length
    let utf8Bytes = Text.encodeUtf8(value);
    let byteLength : Nat64 = Nat64.fromNat(utf8Bytes.size());
    encodeNatHeaderInternal(buffer, 3, byteLength);
    for (utf8Byte in utf8Bytes.vals()) {
      buffer.add(utf8Byte);
    };
    #ok();
  };

  /// Encodes a Major Type 4 (array) CBOR value.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let array : [Types.Value] = [#majorType0(1), #majorType0(2), #majorType0(3)];
  /// let result = CborEncoder.encodeMajorType4(buffer, array);
  /// // buffer now contains the encoded CBOR for array [1, 2, 3]
  /// ```
  public func encodeMajorType4(buffer : Buffer.Buffer<Nat8>, value : [Types.Value]) : Result.Result<(), Types.EncodingError> {
    let arrayLength : Nat64 = Nat64.fromNat(value.size());
    encodeNatHeaderInternal(buffer, 4, arrayLength);
    // Value is header bits + concatenated encoded cbor values
    // Header is major type and array length
    for (v in Iter.fromArray(value)) {
      switch (encodeToBuffer(buffer, v)) {
        case (#err(e)) return #err(e);
        case (#ok) {};
      };
    };
    #ok();
  };

  /// Encodes a Major Type 5 (map) CBOR value.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let map : [(Types.Value, Types.Value)] = [
  ///   (#majorType3("key1"), #majorType0(1)),
  ///   (#majorType3("key2"), #majorType0(2))
  /// ];
  /// let result = CborEncoder.encodeMajorType5(buffer, map);
  /// // buffer now contains the encoded CBOR for map {"key1": 1, "key2": 2}
  /// ```
  public func encodeMajorType5(buffer : Buffer.Buffer<Nat8>, value : [(Types.Value, Types.Value)]) : Result.Result<(), Types.EncodingError> {
    let arrayLength : Nat64 = Nat64.fromNat(value.size());
    encodeNatHeaderInternal(buffer, 5, arrayLength);
    // Value is header bits + concatenated encoded cbor key value map pairs
    // Header is major type and map key length
    for ((k, v) in Iter.fromArray(value)) {
      switch (encodeToBuffer(buffer, k)) {
        case (#err(e)) return #err(e);
        case (#ok(b)) b;
      };
      switch (encodeToBuffer(buffer, v)) {
        case (#err(e)) return #err(e);
        case (#ok(b)) b;
      };
    };
    #ok();
  };

  /// Encodes a Major Type 6 (tag) CBOR value.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let tag : Nat64 = 1;
  /// let taggedValue : Types.Value = #majorType3("2023-06-30T12:30:00Z");
  /// let result = CborEncoder.encodeMajorType6(buffer, tag, taggedValue);
  /// // buffer now contains the encoded CBOR for tagged value 1("2023-06-30T12:30:00Z")
  /// ```
  public func encodeMajorType6(buffer : Buffer.Buffer<Nat8>, tag : Nat64, value : Types.Value) : Result.Result<(), Types.EncodingError> {
    encodeNatHeaderInternal(buffer, 6, tag);
    // Value is header bits + concatenated encoded cbor value
    // Header is major type and tag value
    encodeToBuffer(buffer, value);
  };

  /// Encodes a Major Type 7 (float or simple values) CBOR value.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let result = CborEncoder.encodeMajorType7(buffer, #bool(true));
  /// // buffer now contains the encoded CBOR for boolean true
  /// ```
  public func encodeMajorType7(buffer : Buffer.Buffer<Nat8>, value : { #integer : Nat8; #bool : Bool; #_null; #_undefined; #float : FloatX.FloatX }) : Result.Result<(), Types.EncodingError> {
    let (additionalBits : Nat8, additionalBytes : ?Buffer.Buffer<Nat8>) = switch (value) {
      case (#bool(false)) (20 : Nat8, null);
      case (#bool(true)) (21 : Nat8, null);
      case (#_null) (22 : Nat8, null);
      case (#_undefined) (23 : Nat8, null);
      case (#integer(i)) {
        if (i <= 19) {
          (i, null);
        } else if (i <= 31) {
          // Invalid values, since it is redundant
          return #err(#invalidValue("Major Type 7 ineter "));
        } else {
          let innerBuffer = Buffer.Buffer<Nat8>(1);
          innerBuffer.add(i);
          (24 : Nat8, ?innerBuffer);
        };
      };
      case (#float(f)) {
        let floatBytesBuffer = Buffer.Buffer<Nat8>(8);
        FloatX.encode(floatBytesBuffer, f, #msb);
        let n : Nat8 = switch (f.precision) {
          case (#f16) 25;
          case (#f32) 26;
          case (#f64) 27;
        };
        (n, ?floatBytesBuffer);
      };
    };
    encodeRaw(buffer, 7, additionalBits, additionalBytes);
    #ok();
  };

  private func encodeRaw(buffer : Buffer.Buffer<Nat8>, majorType : Nat8, additionalBits : Nat8, additionalBytes : ?Buffer.Buffer<Nat8>) {
    let firstByte : Nat8 = majorType << 5 + additionalBits;
    // Concatenate the header byte and the additional bytes (if available)
    buffer.add(firstByte);

    switch (additionalBytes) {
      case (null) {};
      case (?bytes) {
        buffer.append(bytes);
      };
    };
  };

  private func encodeNatHeaderInternal(buffer : Buffer.Buffer<Nat8>, majorType : Nat8, value : Nat64) {
    let (additionalBits : Nat8, additionalBytes : ?Buffer.Buffer<Nat8>) = if (value <= 23) {
      (Nat8.fromNat(Nat64.toNat(value)), null);
    } else {
      let addBitsBuffer = Buffer.Buffer<Nat8>(8);
      let additionalBits : Nat8 = if (value <= 0xff) {
        addBitsBuffer.add(Nat8.fromNat(Nat64.toNat(value)));
        24;
      } else if (value <= 0xffff) {
        NatX.encodeNat16(addBitsBuffer, Nat16.fromNat(Nat64.toNat(value)), #msb);
        25 // 25 indicates 2 more bytes of info
      } else if (value <= 0xffffffff) {
        NatX.encodeNat32(addBitsBuffer, Nat32.fromNat(Nat64.toNat(value)), #msb);
        26 // 26 indicates 4 more bytes of info
      } else {
        NatX.encodeNat64(addBitsBuffer, value, #msb);
        27 // 27 indicates 8 more bytes of info
      };
      (additionalBits, ?addBitsBuffer);
    };
    encodeRaw(buffer, majorType, additionalBits, additionalBytes);
  };

};
