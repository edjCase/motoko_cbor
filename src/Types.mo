import FloatX "mo:xtended-numbers/FloatX";

/// CBOR (Concise Binary Object Representation) library for Motoko.
///
/// This module provides functionality for encoding and decoding CBOR data according to RFC 7049.
/// CBOR is a binary data serialization format that aims to be small, fast, and structured.
///
/// Key features:
/// * Encode Motoko values to CBOR binary format
/// * Decode CBOR binary data to Motoko values
/// * Support for all major CBOR types (integers, text, arrays, maps, tags, floats, simple values)
/// * Extensible type system with tagged values
/// * Efficient streaming encoding/decoding
///
/// Example usage:
/// ```motoko
/// import CBOR "mo:cbor";
/// import Result "mo:base/Result";
///
/// // Encode a value to CBOR bytes
/// let value : CBOR.Value = #majorType0(42);
/// let result = CBOR.toBytes(value);
///
/// // Decode CBOR bytes back to a value
/// let bytes : [Nat8] = [0x18, 0x2a];
/// let decoded = CBOR.fromBytes(bytes.vals());
/// ```
///
/// Security considerations:
/// * CBOR data from untrusted sources should be validated
/// * Be aware of potential memory usage with large arrays/maps
/// * Consider using streaming APIs for large data sets
module {
  /// Represents a CBOR value using the major type system defined in RFC 7049.
  ///
  /// CBOR defines 8 major types (0-7), each with specific semantics:
  /// * Type 0: Unsigned integers (0 to 2^64 - 1)
  /// * Type 1: Negative integers (-2^64 to -1)
  /// * Type 2: Byte strings (raw binary data)
  /// * Type 3: Text strings (UTF-8 encoded text)
  /// * Type 4: Arrays (ordered sequences of values)
  /// * Type 5: Maps (key-value pairs)
  /// * Type 6: Tagged values (semantic annotations)
  /// * Type 7: Floats and simple values (booleans, null, undefined, etc.)
  ///
  /// Examples:
  /// ```motoko
  /// // Unsigned integer 42
  /// let num : Value = #majorType0(42);
  ///
  /// // Negative integer -10
  /// let neg : Value = #majorType1(-10);
  ///
  /// // Byte string
  /// let bytes : Value = #majorType2([0x01, 0x02, 0x03]);
  ///
  /// // Text string
  /// let text : Value = #majorType3("Hello, CBOR!");
  ///
  /// // Array of values
  /// let array : Value = #majorType4([#majorType0(1), #majorType0(2), #majorType0(3)]);
  ///
  /// // Map with key-value pairs
  /// let map : Value = #majorType5([
  ///   (#majorType3("key"), #majorType0(42)),
  ///   (#majorType3("name"), #majorType3("value"))
  /// ]);
  ///
  /// // Tagged value (e.g., timestamp)
  /// let tagged : Value = #majorType6({
  ///   tag = 1;
  ///   value = #majorType3("2023-06-30T12:30:00Z");
  /// });
  ///
  /// // Boolean true
  /// let bool : Value = #majorType7(#bool(true));
  /// ```
  public type Value = {
    /// Major Type 0: Unsigned integers from 0 to 2^64 - 1.
    /// Used for non-negative integer values.
    #majorType0 : Nat64;

    /// Major Type 1: Negative integers from -2^64 to -1.
    /// Encoded as (-1 - n) where n is the absolute value minus 1.
    #majorType1 : Int;

    /// Major Type 2: Byte strings (sequences of raw bytes).
    /// Used for binary data that doesn't have text semantics.
    #majorType2 : [Nat8];

    /// Major Type 3: Text strings (UTF-8 encoded).
    /// Used for human-readable text data.
    #majorType3 : Text;

    /// Major Type 4: Arrays (ordered sequences of CBOR values).
    /// Can contain any mix of CBOR value types.
    #majorType4 : [Value];

    /// Major Type 5: Maps (key-value pairs).
    /// Keys and values can be any CBOR value type.
    #majorType5 : [(Value, Value)];

    /// Major Type 6: Tagged values (semantic annotations).
    /// Associates a tag number with a value to provide additional meaning.
    #majorType6 : {
      /// The tag number indicating the semantic meaning
      tag : Nat64;
      /// The tagged value
      value : Value;
    };

    /// Major Type 7: Floats and simple values.
    /// Includes floating-point numbers, booleans, null, undefined, and other simple values.
    #majorType7 : {
      /// Simple integer values (0-255)
      #integer : Nat8;
      /// Boolean values (true/false)
      #bool : Bool;
      /// Null value
      #_null;
      /// Undefined value
      #_undefined;
      /// Floating-point numbers (half, single, double precision)
      #float : FloatX.FloatX;
      /// Break symbol (used internally for indefinite-length items)
      #_break;
    };
  };

  /// Represents errors that can occur during CBOR decoding operations.
  /// These errors indicate problems with the input data or decoding process.
  ///
  /// Example usage:
  /// ```motoko
  /// let result = CBOR.fromBytes(invalidBytes);
  /// switch (result) {
  ///   case (#ok(value)) { /* Use decoded value */ };
  ///   case (#err(#unexpectedEndOfBytes)) { /* Handle truncated data */ };
  ///   case (#err(#invalid(msg))) { /* Handle invalid format */ };
  ///   case (#err(#unexpectedBreak)) { /* Handle misplaced break */ };
  /// };
  /// ```
  public type DecodingError = {
    /// The input bytes ended unexpectedly while decoding was in progress.
    /// This typically indicates truncated or incomplete CBOR data.
    #unexpectedEndOfBytes;

    /// The input contains invalid CBOR data with a descriptive error message.
    /// This can occur when the data doesn't conform to CBOR format rules.
    #invalid : Text;

    /// A break symbol was encountered in an unexpected context.
    /// Break symbols are only valid within indefinite-length items.
    #unexpectedBreak;
  };

  /// Represents errors that can occur during CBOR encoding operations.
  /// These errors indicate problems with the input values or encoding process.
  ///
  /// Example usage:
  /// ```motoko
  /// let result = CBOR.toBytes(invalidValue);
  /// switch (result) {
  ///   case (#ok(bytes)) { /* Use encoded bytes */ };
  ///   case (#err(#invalidValue(msg))) { /* Handle invalid input */ };
  /// };
  /// ```
  public type EncodingError = {
    /// The input value cannot be encoded to CBOR format.
    /// This can occur when values are outside valid ranges or have invalid combinations.
    #invalidValue : Text;
  };

};
