import Binary "./Binary";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import LittleEndian "mo:base/Int64";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Util "./Util";

module {
  public class CborReader(bytes: Blob) {
    var byte_position : Nat = 0;
    let iterator : Iter.Iter<Nat8> = bytes.vals();

    public func read() : Result.Result<CborValue, CborError> {
      readInternal(false);
    };

    private func readInternal(allowBreak: Bool) : Result.Result<CborValue, CborError> {
      let firstByte : Nat8 = switch (readByte()){
        case (null) {
          return #err(#unexpectedEndOfBytes);
        };
        case (?firstByte) firstByte;
      };
      let (majorType, additionalBits) = parseMajorType(firstByte);
      let result = switch (majorType) {
        case (0) parseMajorType0(additionalBits);
        case (1) parseMajorType1(additionalBits);
        case (2) parseMajorType2(additionalBits);
        case (3) parseMajorType3(additionalBits);
        case (4) parseMajorType4(additionalBits);
        case (5) parseMajorType5(additionalBits);
        case (6) parseMajorType6(additionalBits);
        case (7) parseMajorType7(additionalBits);
        case _ return #err(#malformed("Invalid major type: " # Nat8.toText(majorType)));
      };
      if(not allowBreak) {
        return switch(result) {
          case (#ok(#majorType7(#_break))) #err(#invalid(#unexpectedBreak));
          case (a) a;
        };
      };
      result;
    };

    private func parseMajorType(byte: Nat8) : (Nat8, Nat8) {
      let majorType : Nat8 = (byte >> 5) & 0x07; // Get first 3 bits
      let additionalBits : Nat8 = byte & 0x1F; // Get last 5 bits
      (majorType, additionalBits); 
    };

    private func readByte() : ?Nat8 {
      byte_position += 1;
      return iterator.next();
    };

    private func readBytes(n : Nat) : ?[Nat8] {
      if (n < 1) {
        return ?[];
      };
      let iter: Iter.Iter<Nat> = Iter.range(1, n);
      let buffer = Buffer.Buffer<Nat8>(n);
      for (i in iter) {
        let byte = switch (readByte()) {
          case (null) return null;
          case (?byte) byte;
        };
        buffer.add(byte);
      };
      return ?buffer.toArray();
    };

    private func readIndefBytes(chunkedMajorType: ?Nat8) : Result.Result<[Nat8], CborError> {
      let buffer = Buffer.Buffer<Nat8>(1);
      label l loop {
        let byte = switch (readByte()) {
          case (null) return #err(#unexpectedEndOfBytes);
          case (?byte) byte;
        };
        if (byte == 0xff) {
          break l; // Reached end of indefinate byte sequence
        };
        switch(chunkedMajorType) {
          case (null) buffer.add(byte); // byte is actual byte value
          case (?t) {
            // byte represents major type/additional bits of next byte chunk
            let (majorType, additionalBits) = parseMajorType(byte);
            if (majorType != t) {
              return #err(#malformed("Major type " # Nat8.toText(majorType) # " expected, got " # Nat8.toText(t)));
            };
            
            let bytes = switch(readBytes(Nat8.toNat(additionalBits))) {
              case (null) return #err(#unexpectedEndOfBytes);
              case (?v) v;
            };
            Iter.iterate<Nat8>(Iter.fromArray(bytes), func (b, i) { buffer.add(b); });
          };
        }
      };
      return #ok(buffer.toArray());
    };


    private func parseMajorType0(additionalBits: Nat8) : Result.Result<CborValue, CborError> {
      let value = switch(getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) Binary.BigEndian.toNat64(b); // Convert bytes to value
        case (#ok(#indef)) return #err(#malformed("Major type 0 does not support 31 for additional bits"));
        case (#err(x)) return #err(x);
      };
      #ok(#majorType0(value));
    };

    private func parseMajorType1(additionalBits: Nat8) : Result.Result<CborValue, CborError> {
      let value = switch(getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) Binary.BigEndian.toNat64(b); // Convert bytes to value
        case (#ok(#indef)) return #err(#malformed("Major type 1 does not support 31 for additional bits"));
        case (#err(x)) return #err(x);
      };
      #ok(#majorType1(value));
    };

    private func parseMajorType2(additionalBits: Nat8) : Result.Result<CborValue, CborError> {
      let byte_value = switch(getAdditionalBitsByteValue(additionalBits, 2)) {
        case (#err(e)) return #err(e);
        case (#ok(v)) v;
      };
      #ok(#majorType2(byte_value));
    };

    private func parseMajorType3(additionalBits: Nat8) : Result.Result<CborValue, CborError> {
      let byte_value = switch(getAdditionalBitsByteValue(additionalBits, 3)) {
        case (#err(e)) return #err(e);
        case (#ok(v)) v;
      };
      let blob = Blob.fromArray(byte_value);
      let text_value: Text = switch(Text.decodeUtf8(blob)){
        case (null) return #err(#invalid(#utf8String));
        case (?v) v;
      };
      #ok(#majorType3(text_value));
    };

    private func parseMajorType4(additionalBits: Nat8) : Result.Result<CborValue, CborError> {
      let array_length: Nat64 = switch(getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) Binary.BigEndian.toNat64(b); // Convert bytes to value
        case (#ok(#indef)) {
          // Loop indefinitely for each array item
          let buffer = Buffer.Buffer<CborValue>(1);
          label l loop {
            let cbor_value: CborValue = switch(readInternal(true)) {
              case (#err(e)) return #err(e);
              case (#ok(v)) v;
            };
            if (cbor_value == #majorType7(#_break)){
              break l;
            };
            buffer.add(cbor_value);
          };
          return #ok(#majorType4(buffer.toArray()));
        };
        case (#err(x)) return #err(x);
      };
      let buffer = Buffer.Buffer<CborValue>(Nat64.toNat(array_length));
      for (i in Iter.range(1, Nat64.toNat(array_length))) {
        let cbor_value: CborValue = switch(readInternal(false)) {
          case (#err(e)) return #err(e);
          case (#ok(v)) v;
        };
        buffer.add(cbor_value);
      };
      #ok(#majorType4(buffer.toArray()));
    };
    
    private func parseMajorType5(additionalBits: Nat8) : Result.Result<CborValue, CborError> {
      let map_size: Nat64 = switch(getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) Binary.BigEndian.toNat64(b); // Convert bytes to value
        case (#ok(#indef)) {
          // Loop indefinitely for each array item
          let buffer = Buffer.Buffer<(CborValue, CborValue)>(1);
          label l loop {
            let (key, value) = switch(readKeyValuePair()){
              case (#err(#invalid(#unexpectedBreak))) break l;
              case (#err(e)) return #err(e);
              case (#ok(v)) v;
            };
            buffer.add((key, value));
          };
          return #ok(#majorType5(buffer.toArray()));
        };
        case (#err(x)) return #err(x);
      };
      let buffer = Buffer.Buffer<(CborValue, CborValue)>(Nat64.toNat(map_size));
      for (i in Iter.range(1, Nat64.toNat(map_size))) {
        let (key, value) = switch(readKeyValuePair()){
          case (#err(e)) return #err(e);
          case (#ok(v)) v;
        };
        buffer.add((key, value));
      };
      #ok(#majorType5(buffer.toArray()));
    };

    private func readKeyValuePair() : Result.Result<(CborValue, CborValue), CborError> {
      let key: CborValue = switch(readInternal(false)) {
          case (#err(e)) return #err(e);
          case (#ok(v)) v;
        };
        let value: CborValue = switch(readInternal(false)) {
          case (#err(e)) return #err(e);
          case (#ok(v)) v;
        };
        #ok((key, value));
    };

    private func parseMajorType6(additionalBits: Nat8) : Result.Result<CborValue, CborError> {
      let tag: Nat64 = switch(getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) Binary.BigEndian.toNat64(b); // Convert bytes to value
        case (#ok(#indef)) return #err(#malformed("Value 31 is not allowed for additional bits for major type 6"));
        case (#err(x)) return #err(x);
      };
        let value: CborValue = switch(readInternal(false)) {
          case (#err(e)) return #err(e);
          case (#ok(v)) v;
        };
      #ok(#majorType6({tag=tag; value=value}));
    };

    private func parseMajorType7(additionalBits: Nat8) : Result.Result<CborValue, CborError> {
      if(additionalBits == 0xff) {
        // ff -> break code
        return #ok(#majorType7(#_break));
      };
      if(additionalBits <= 24) {
        // 0..24 are simple values
      }
      let value = switch(additionalBits) {
        case (25) #halfFloat()
      };
      #ok(value);
    };

    private func getAdditionalBitsByteValue(additionalBits: Nat8, majorType: Nat8) : Result.Result<[Nat8], CborError> {
      let bytes_to_read : Nat = switch(getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat8.toNat(n); // Convert number to length
        case (#ok(#bytes(b))) Nat64.toNat(Binary.BigEndian.toNat64(b)); // Convert bytes to length
        case (#ok(#indef)) {
          // Read indefinite length of bytes
          let indef_bytes = switch(readIndefBytes(?majorType)) {
            case (#err(e)) return #err(e);
            case (#ok(b)) b;
          };
          return #ok(indef_bytes);
        };
        case (#err(x)) return #err(x);
      };
      let bytes = switch(readBytes(bytes_to_read)) { // Read the byte strng
        case (null) return #err(#unexpectedEndOfBytes);
        case (?b) b;
      };
      #ok(bytes);
    };

    private func getAdditionalBitsValue(additionalBits: Nat8) : Result.Result<{#num: Nat8; #bytes: [Nat8]; #indef}, CborError> {
      // Check additional bits for value
      // 23 or less => additional bits is the value
      // 24 => read 1 more byte for value
      // 25 => read 2 more bytes for value
      // 26 => read 4 more bytes for value
      // 27 => read 8 more bytes for value
      
      if(additionalBits <= 23){
        return #ok(#num(additionalBits));
      };
      let content_byte_length : Nat = switch (additionalBits){
        case (24) 1;
        case (25) 2;
        case (26) 4;
        case (27) 8;
        case (31) return #ok(#indef);
        case a {
          let message = "Invalid additional bits value: " # Nat8.toText(additionalBits);
          return #err(#malformed(message));
        };
      };
      let value_bytes: [Nat8] = switch (readBytes(content_byte_length)){
        case (null) return #err(#unexpectedEndOfBytes);
        case (?b) b;
      };
      #ok(#bytes(value_bytes));
    }

  };
  public type CborError = {
    #unexpectedEndOfBytes;
    #malformed: Text;
    #invalid: {
      #utf8String;
      #unexpectedBreak;
    };
  };

  public type CborValue = {
    #majorType0: Nat64; // 0 -> 2^64 - 1
    #majorType1: Nat64; // -2^64 -> -1 ((-1 * Value) - 1)
    #majorType2 : [Nat8];
    #majorType3: Text;
    #majorType4: [CborValue];
    #majorType5: [(CborValue, CborValue)];
    #majorType6: {
      tag: Nat64;
      value: CborValue;
    };
    #majorType7: {
      #simple: {
        #integer: Nat8;
        #bool: Bool;
        #null;
        #undefined;
      };
      #halfFloat: Float;
      #singleFloat: Float;
      #doubleFloat: Float;
      #_break;
    }
  };


  // func cbor_tree(tree : HashTree) : Blob {
  //   let buf = Buffer.Buffer<Nat8>(100);

  //   // CBOR self-describing tag
  //   buf.add(0xD9);
  //   buf.add(0xD9);
  //   buf.add(0xF7);

  //   func add_blob(b: Blob) {
  //     // Only works for blobs with less than 256 bytes
  //     buf.add(0x58);
  //     buf.add(Nat8.fromNat(b.size()));
  //     for (c in Blob.toArray(b).vals()) {
  //       buf.add(c);
  //     };
  //   };

  //   func go(t : HashTree) {
  //     switch (t) {
  //       case (#empty)        { buf.add(0x81); buf.add(0x00); };
  //       case (#fork(t1,t2))  { buf.add(0x83); buf.add(0x01); go(t1); go (t2); };
  //       case (#labeled(l,t)) { buf.add(0x83); buf.add(0x02); add_blob(l); go (t); };
  //       case (#leaf(v))      { buf.add(0x82); buf.add(0x03); add_blob(v); };
  //       case (#pruned(h))    { buf.add(0x82); buf.add(0x04); add_blob(h); }
  //     }
  //   };

  //   go(tree);

  //   return Blob.fromArray(buf.toArray());
  // };
}