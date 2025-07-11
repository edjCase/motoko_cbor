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

/// CBOR (Concise Binary Object Representation) encoder for Motoko.
///
/// This module provides functionality for encoding Motoko values to CBOR binary format
/// according to RFC 7049. CBOR is a binary data serialization format that aims to be
/// small, fast, and structured.
///
/// Key features:
/// * Convert Motoko values to CBOR binary format
/// * Support for all major CBOR types (integers, text, arrays, maps, tags, floats, simple values)
/// * Efficient encoding with minimal memory overhead
/// * Streaming encoding to buffers
/// * Comprehensive error handling
///
/// Example usage:
/// ```motoko
/// import CBOR "mo:cbor";
/// import Result "mo:base/Result";
///
/// // Encode a simple value
/// let value : CBOR.Value = #majorType0(42);
/// let result = CBOR.toBytes(value);
///
/// // Encode complex nested structures
/// let complexValue : CBOR.Value = #majorType5([
///   (#majorType3("name"), #majorType3("John")),
///   (#majorType3("age"), #majorType0(30))
/// ]);
/// let bytes = CBOR.toBytes(complexValue);
/// ```
module {
  /// Encodes a CBOR value into a byte array.
  /// This is the main encoding function that converts any CBOR value to its binary representation.
  ///
  /// The function creates a temporary buffer, encodes the value into it, and returns the
  /// resulting byte array. For better performance with large data or multiple encodings,
  /// consider using `toBytesBuffer` with a reusable buffer.
  ///
  /// Parameters:
  /// * `value`: The CBOR value to encode
  ///
  /// Returns:
  /// * `#ok([Nat8])`: Successfully encoded bytes
  /// * `#err(Types.EncodingError)`: Encoding failed with error details
  ///
  /// Example:
  /// ```motoko
  /// let value : Types.Value = #majorType0(123);
  /// let result = toBytes(value);
  /// switch (result) {
  ///   case (#ok(bytes)) { /* Use encoded bytes */ };
  ///   case (#err(error)) { /* Handle error */ };
  /// };
  /// ```
  public func toBytes(value : Types.Value) : Result.Result<[Nat8], Types.EncodingError> {
    let buffer = Buffer.Buffer<Nat8>(10);
    switch (toBytesBuffer(buffer, value)) {
      case (#ok(_)) #ok(Buffer.toArray(buffer));
      case (#err(e)) #err(e);
    };
  };

  /// Encodes a CBOR value into a provided buffer and returns the number of bytes written.
  /// This function is more efficient than `toBytes` when you need to control the buffer
  /// or when encoding multiple values sequentially.
  ///
  /// The function appends the encoded bytes to the existing buffer contents and returns
  /// the total number of bytes added. This allows for efficient batch encoding and
  /// memory management.
  ///
  /// Parameters:
  /// * `buffer`: The buffer to append encoded bytes to
  /// * `value`: The CBOR value to encode
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded, returns number of bytes written
  /// * `#err(Types.EncodingError)`: Encoding failed with error details
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(100);
  /// let value : Types.Value = #majorType0(123);
  /// let result = toBytesBuffer(buffer, value);
  /// switch (result) {
  ///   case (#ok(bytesWritten)) { /* bytesWritten indicates how many bytes were added */ };
  ///   case (#err(error)) { /* Handle error */ };
  /// };
  /// ```
  public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, value : Types.Value) : Result.Result<Nat, Types.EncodingError> {
    switch (value) {
      case (#majorType0(t0)) toBytesType0(buffer, t0);
      case (#majorType1(t1)) toBytesType1(buffer, t1);
      case (#majorType2(t2)) toBytesType2(buffer, t2);
      case (#majorType3(t3)) toBytesType3(buffer, t3);
      case (#majorType4(t4)) toBytesType4(buffer, t4);
      case (#majorType5(t5)) toBytesType5(buffer, t5);
      case (#majorType6(t6)) toBytesType6(buffer, t6.tag, t6.value);
      case (#majorType7(t7)) {
        switch (t7) {
          case (#_break) return #err(#invalidValue("Break is not allowed as a value"));
          case (#_null) toBytesType7(buffer, #_null);
          case (#_undefined) toBytesType7(buffer, #_undefined);
          case (#bool(b)) toBytesType7(buffer, #bool(b));
          case (#float(f)) toBytesType7(buffer, #float(f));
          case (#integer(i)) toBytesType7(buffer, #integer(i));
        };
      };
    };
  };

  /// Encodes a Major Type 0 (unsigned integer) CBOR value.
  /// Major Type 0 represents unsigned integers from 0 to 2^64 - 1.
  ///
  /// The encoding uses the most compact representation possible:
  /// * Values 0-23: Encoded directly in the initial byte
  /// * Values 24-255: Encoded with 1 additional byte
  /// * Values 256-65535: Encoded with 2 additional bytes
  /// * Values 65536-4294967295: Encoded with 4 additional bytes
  /// * Values 4294967296 and above: Encoded with 8 additional bytes
  ///
  /// Parameters:
  /// * `buffer`: The buffer to write encoded bytes to
  /// * `value`: The unsigned integer value to encode (0 to 2^64 - 1)
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded the value, returns number of bytes written
  /// * `#err(Types.EncodingError)`: Encoding failed (shouldn't happen for valid inputs)
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let result = toBytesType0(buffer, 123);
  /// // buffer now contains the encoded CBOR for unsigned integer 123
  /// ```
  public func toBytesType0(buffer : Buffer.Buffer<Nat8>, value : Nat64) : Result.Result<Nat, Types.EncodingError> {
    let initialSize = buffer.size();
    encodeNatHeaderInternal(buffer, 0, value);
    return #ok(buffer.size() - initialSize);
  };

  /// Encodes a Major Type 1 (negative integer) CBOR value.
  /// Major Type 1 represents negative integers from -2^64 to -1.
  ///
  /// The encoding converts the negative integer to its positive representation
  /// by computing (-1 - value) and then encoding that as an unsigned integer.
  /// This allows efficient encoding of negative numbers while maintaining
  /// proper ordering.
  ///
  /// Parameters:
  /// * `buffer`: The buffer to write encoded bytes to
  /// * `value`: The negative integer value to encode (-2^64 to -1)
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded the value, returns number of bytes written
  /// * `#err(Types.EncodingError)`: Encoding failed if value is out of range
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let result = toBytesType1(buffer, -10);
  /// // buffer now contains the encoded CBOR for negative integer -10
  /// ```
  public func toBytesType1(buffer : Buffer.Buffer<Nat8>, value : Int) : Result.Result<Nat, Types.EncodingError> {
    let maxValue : Int = -1;
    let minValue : Int = -0x10000000000000000;
    if (value > maxValue or value < minValue) {
      return #err(#invalidValue("Major type 1 values must be between -2^64 and -1"));
    };
    // Convert negative number (-1 - N) to Nat (N) to store as bytes
    let natValue : Nat = Int.abs(value + 1);
    let initialSize = buffer.size();
    encodeNatHeaderInternal(buffer, 1, Nat64.fromNat(natValue));
    return #ok(buffer.size() - initialSize);
  };

  /// Encodes a Major Type 2 (byte string) CBOR value.
  /// Major Type 2 represents byte strings (sequences of raw bytes).
  ///
  /// The encoding includes a header specifying the length of the byte string
  /// followed by the actual bytes. The header uses the most compact representation
  /// possible for the length value.
  ///
  /// Parameters:
  /// * `buffer`: The buffer to write encoded bytes to
  /// * `value`: The byte array to encode
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded the value, returns number of bytes written
  /// * `#err(Types.EncodingError)`: Encoding failed (shouldn't happen for valid inputs)
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let byteString : [Nat8] = [0x01, 0x02, 0x03];
  /// let result = toBytesType2(buffer, byteString);
  /// // buffer now contains the encoded CBOR for byte string [0x01, 0x02, 0x03]
  /// ```
  public func toBytesType2(buffer : Buffer.Buffer<Nat8>, value : [Nat8]) : Result.Result<Nat, Types.EncodingError> {
    // Value is header bits + value bytes
    // Header is major type and value byte length
    let initialSize = buffer.size();
    let byteLength : Nat64 = Nat64.fromNat(value.size());
    encodeNatHeaderInternal(buffer, 2, byteLength);
    for (b in Iter.fromArray(value)) {
      buffer.add(b);
    };
    #ok(buffer.size() - initialSize);
  };

  /// Encodes a Major Type 3 (text string) CBOR value.
  /// Major Type 3 represents text strings (UTF-8 encoded).
  ///
  /// The encoding includes a header specifying the byte length of the UTF-8 encoded
  /// text followed by the actual UTF-8 bytes. The header uses the most compact
  /// representation possible for the length value.
  ///
  /// Parameters:
  /// * `buffer`: The buffer to write encoded bytes to
  /// * `value`: The text string to encode
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded the value, returns number of bytes written
  /// * `#err(Types.EncodingError)`: Encoding failed (shouldn't happen for valid inputs)
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let result = toBytesType3(buffer, "Hello, CBOR!");
  /// // buffer now contains the encoded CBOR for text string "Hello, CBOR!"
  /// ```
  public func toBytesType3(buffer : Buffer.Buffer<Nat8>, value : Text) : Result.Result<Nat, Types.EncodingError> {

    // Value is header bits + utf8 encoded string bytes
    // Header is major type and utf8 byte length
    let initialSize = buffer.size();
    let utf8Bytes = Text.encodeUtf8(value);
    let byteLength : Nat64 = Nat64.fromNat(utf8Bytes.size());
    encodeNatHeaderInternal(buffer, 3, byteLength);
    for (utf8Byte in utf8Bytes.vals()) {
      buffer.add(utf8Byte);
    };
    #ok(buffer.size() - initialSize);
  };

  /// Encodes a Major Type 4 (array) CBOR value.
  /// Major Type 4 represents arrays (ordered sequences of CBOR values).
  ///
  /// The encoding includes a header specifying the number of elements in the array
  /// followed by the encoded elements concatenated together. Each element is encoded
  /// recursively using the appropriate encoding function for its type.
  ///
  /// Parameters:
  /// * `buffer`: The buffer to write encoded bytes to
  /// * `value`: The array of CBOR values to encode
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded the value, returns number of bytes written
  /// * `#err(Types.EncodingError)`: Encoding failed if any element fails to encode
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let array : [Types.Value] = [#majorType0(1), #majorType0(2), #majorType0(3)];
  /// let result = toBytesType4(buffer, array);
  /// // buffer now contains the encoded CBOR for array [1, 2, 3]
  /// ```
  public func toBytesType4(buffer : Buffer.Buffer<Nat8>, value : [Types.Value]) : Result.Result<Nat, Types.EncodingError> {
    let initialSize = buffer.size();
    let arrayLength : Nat64 = Nat64.fromNat(value.size());
    encodeNatHeaderInternal(buffer, 4, arrayLength);
    // Value is header bits + concatenated encoded cbor values
    // Header is major type and array length
    for (v in Iter.fromArray(value)) {
      switch (toBytesBuffer(buffer, v)) {
        case (#err(e)) return #err(e);
        case (#ok(_)) {};
      };
    };
    #ok(buffer.size() - initialSize);
  };

  /// Encodes a Major Type 5 (map) CBOR value.
  /// Major Type 5 represents maps (collections of key-value pairs).
  ///
  /// The encoding includes a header specifying the number of key-value pairs in the map
  /// followed by the encoded key-value pairs concatenated together. Each key and value
  /// is encoded recursively using the appropriate encoding function for its type.
  ///
  /// Parameters:
  /// * `buffer`: The buffer to write encoded bytes to
  /// * `value`: The array of key-value pairs to encode
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded the value, returns number of bytes written
  /// * `#err(Types.EncodingError)`: Encoding failed if any key or value fails to encode
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let map : [(Types.Value, Types.Value)] = [
  ///   (#majorType3("key1"), #majorType0(1)),
  ///   (#majorType3("key2"), #majorType0(2))
  /// ];
  /// let result = toBytesType5(buffer, map);
  /// // buffer now contains the encoded CBOR for map {"key1": 1, "key2": 2}
  /// ```
  public func toBytesType5(buffer : Buffer.Buffer<Nat8>, value : [(Types.Value, Types.Value)]) : Result.Result<Nat, Types.EncodingError> {
    let initialSize = buffer.size();
    let arrayLength : Nat64 = Nat64.fromNat(value.size());
    encodeNatHeaderInternal(buffer, 5, arrayLength);
    // Value is header bits + concatenated encoded cbor key value map pairs
    // Header is major type and map key length
    for ((k, v) in Iter.fromArray(value)) {
      switch (toBytesBuffer(buffer, k)) {
        case (#err(e)) return #err(e);
        case (#ok(_)) {};
      };
      switch (toBytesBuffer(buffer, v)) {
        case (#err(e)) return #err(e);
        case (#ok(_)) {};
      };
    };
    #ok(buffer.size() - initialSize);
  };

  /// Encodes a Major Type 6 (tag) CBOR value.
  /// Major Type 6 represents tagged values (semantic annotations).
  ///
  /// Tags provide additional semantic meaning to CBOR values. Common tags include:
  /// * Tag 0: Standard date/time string
  /// * Tag 1: Epoch-based date/time
  /// * Tag 2: Positive bignum
  /// * Tag 3: Negative bignum
  /// * Tag 32: URI
  /// * Tag 33: Base64 URL
  /// * Tag 34: Base64
  ///
  /// Parameters:
  /// * `buffer`: The buffer to write encoded bytes to
  /// * `tag`: The tag number indicating the semantic meaning
  /// * `value`: The tagged CBOR value
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded the value, returns number of bytes written
  /// * `#err(Types.EncodingError)`: Encoding failed if the tagged value fails to encode
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let tag : Nat64 = 1;
  /// let taggedValue : Types.Value = #majorType3("2023-06-30T12:30:00Z");
  /// let result = toBytesType6(buffer, tag, taggedValue);
  /// // buffer now contains the encoded CBOR for tagged value 1("2023-06-30T12:30:00Z")
  /// ```
  public func toBytesType6(buffer : Buffer.Buffer<Nat8>, tag : Nat64, value : Types.Value) : Result.Result<Nat, Types.EncodingError> {
    let initialSize = buffer.size();
    encodeNatHeaderInternal(buffer, 6, tag);
    // Value is header bits + concatenated encoded cbor value
    // Header is major type and tag value
    switch (toBytesBuffer(buffer, value)) {
      case (#ok(_)) #ok(buffer.size() - initialSize);
      case (#err(e)) #err(e);
    };
  };

  /// Encodes a Major Type 7 (float or simple values) CBOR value.
  /// Major Type 7 represents floating-point numbers and simple values.
  ///
  /// This type includes:
  /// * Boolean values (true/false)
  /// * Null and undefined values
  /// * Floating-point numbers (half, single, double precision)
  /// * Simple integer values (0-255)
  ///
  /// Parameters:
  /// * `buffer`: The buffer to write encoded bytes to
  /// * `value`: The simple value or float to encode
  ///
  /// Returns:
  /// * `#ok(Nat)`: Successfully encoded the value, returns number of bytes written
  /// * `#err(Types.EncodingError)`: Encoding failed if the value is invalid
  ///
  /// Example:
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// let result = toBytesType7(buffer, #bool(true));
  /// // buffer now contains the encoded CBOR for boolean true
  /// ```
  public func toBytesType7(buffer : Buffer.Buffer<Nat8>, value : { #integer : Nat8; #bool : Bool; #_null; #_undefined; #float : FloatX.FloatX }) : Result.Result<Nat, Types.EncodingError> {
    let initialSize = buffer.size();
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
    #ok(buffer.size() - initialSize);
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
