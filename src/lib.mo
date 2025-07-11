import Types "Types";
import Decoder "Decoder";
import Encoder "Encoder";

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
    /// Represents a CBOR value using the major type system.
    /// See Types.Value for detailed documentation of each major type.
    public type Value = Types.Value;

    /// Represents errors that can occur during CBOR decoding operations.
    /// See Types.DecodingError for detailed documentation of each error type.
    public type DecodingError = Types.DecodingError;

    /// Represents errors that can occur during CBOR encoding operations.
    /// See Types.EncodingError for detailed documentation of each error type.
    public type EncodingError = Types.EncodingError;

    /// Decodes CBOR binary data into a structured value.
    /// This function converts CBOR bytes into a Motoko value representation.
    ///
    /// Parameters:
    /// * `bytes`: An iterator over the CBOR-encoded bytes to decode
    ///
    /// Returns:
    /// * `#ok(Value)`: Successfully decoded CBOR value
    /// * `#err(DecodingError)`: Decoding failed with error details
    ///
    /// Example:
    /// ```motoko
    /// let bytes: [Nat8] = [0x18, 0x2a]; // CBOR encoding of integer 42
    /// let result = fromBytes(bytes.vals());
    /// ```
    public let fromBytes = Decoder.fromBytes;

    /// Encodes a CBOR value into binary format.
    /// This function converts a Motoko CBOR value into its binary representation.
    ///
    /// Parameters:
    /// * `value`: The CBOR value to encode
    ///
    /// Returns:
    /// * `#ok([Nat8])`: Successfully encoded bytes
    /// * `#err(EncodingError)`: Encoding failed with error details
    ///
    /// Example:
    /// ```motoko
    /// let value : Value = #majorType0(42);
    /// let result = toBytes(value);
    /// ```
    public let toBytes = Encoder.toBytes;

    /// Encodes a CBOR value into a provided buffer and returns the number of bytes written.
    /// This function is more efficient than `toBytes` when you need to control the buffer
    /// or when encoding multiple values sequentially.
    ///
    /// Parameters:
    /// * `buffer`: The buffer to append encoded bytes to
    /// * `value`: The CBOR value to encode
    ///
    /// Returns:
    /// * `#ok(Nat)`: Successfully encoded, returns number of bytes written
    /// * `#err(EncodingError)`: Encoding failed with error details
    ///
    /// Example:
    /// ```motoko
    /// let buffer = Buffer.Buffer<Nat8>(100);
    /// let value : Value = #majorType0(42);
    /// let result = toBytesBuffer(buffer, value);
    /// ```
    public let toBytesBuffer = Encoder.toBytesBuffer;
};
