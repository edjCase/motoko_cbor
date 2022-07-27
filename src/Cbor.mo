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
      let first_byte : Nat8 = switch (read_byte()){
        case (null) {
          return #err(#UnexpectedEndOfBytes);
        };
        case (?first_byte) first_byte;
      };
      let major_type : Nat8 = (first_byte >> 5) & 0x07; // Get first 3 bits
      let additional_bits : Nat8 = first_byte & 0x1F; // Get last 5 bits
      return switch (major_type) {
        case (0) parse_major_type_0(additional_bits);
        case (1) parse_major_type_1(additional_bits);
        case (2) parse_major_type_2(additional_bits);
        case _ return #err(#Malformed("Invalid major type: " # Nat8.toText(major_type)));
      }
    };

    private func read_byte() : ?Nat8 {
      byte_position += 1;
      return iterator.next();
    };

    private func read_bytes(n : Nat) : ?[Nat8] {
      if (n < 1) {
        return ?[];
      };
      let iter: Iter.Iter<Nat> = Iter.range(1, n);
      let buffer = Buffer.Buffer<Nat8>(n);
      for (i in iter) {
        let byte = switch (read_byte()) {
          case (null) return null;
          case (?byte) byte;
        };
        buffer.add(byte);
      };
      return ?buffer.toArray();
    };

    private func read_indef_bytes() : ?[Nat8] {
      let buffer = Buffer.Buffer<Nat8>(1);
      label l loop {
        let byte = switch (read_byte()) {
          case (null) return null;
          case (?byte) byte;
        };
        if (byte == 0xff) {
          break l; // Reached end of indefinate byte sequence
        };
        buffer.add(byte);
      };
      return ?buffer.toArray();
    };

    private func parse_major_type_0(additional_bits: Nat8) : Result.Result<CborValue, CborError> {
      let value = switch(get_additional_bits_value(additional_bits)) {
        case (#ok(#Num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#Bytes(b))) Binary.BigEndian.toNat64(b); // Convert bytes to value
        case (#ok(#Indef)) return #err(#Malformed("Major type 0 does not support 31 for additional bits"));
        case (#err(x)) return #err(x);
      };
      #ok(#MajorType0(value));
    };

    private func parse_major_type_1(additional_bits: Nat8) : Result.Result<CborValue, CborError> {
      let value = switch(get_additional_bits_value(additional_bits)) {
        case (#ok(#Num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#Bytes(b))) Binary.BigEndian.toNat64(b); // Convert bytes to value
        case (#ok(#Indef)) return #err(#Malformed("Major type 1 does not support 31 for additional bits"));
        case (#err(x)) return #err(x);
      };
      #ok(#MajorType1(value));
    };

    private func parse_major_type_2(additional_bits: Nat8) : Result.Result<CborValue, CborError> {
      let bytes_to_read : Nat = switch(get_additional_bits_value(additional_bits)) {
        case (#ok(#Num(n))) Nat8.toNat(n); // Convert number to length
        case (#ok(#Bytes(b))) Nat64.toNat(Binary.BigEndian.toNat64(b)); // Convert bytes to length
        case (#ok(#Indef)) {
          // Read indefinite length of bytes
          let indef_bytes = switch(read_indef_bytes()) {
            case (null) return #err(#UnexpectedEndOfBytes);
            case (?b) b;
          };
          return #ok(#MajorType2(indef_bytes));
        };
        case (#err(x)) return #err(x);
      };
      let bytes = switch(read_bytes(bytes_to_read)) { // Read the byte strng
        case (null) return #err(#UnexpectedEndOfBytes);
        case (?b) b;
      };
      #ok(#MajorType2(bytes));
    };


    private func get_additional_bits_value(additional_bits: Nat8) : Result.Result<{#Num: Nat8; #Bytes: [Nat8]; #Indef}, CborError> {
      // Check additional bits for value
      // 23 or less => additional bits is the value
      // 24 => read 1 more byte for value
      // 25 => read 2 more bytes for value
      // 26 => read 4 more bytes for value
      // 27 => read 8 more bytes for value
      
      if(additional_bits <= 23){
        return #ok(#Num(additional_bits));
      };
      let content_byte_length : Nat = switch (additional_bits){
        case (24) 1;
        case (25) 2;
        case (26) 4;
        case (27) 8;
        case (31) return #ok(#Indef);
        case a {
          let message = "Invalid additional bits value: " # Nat8.toText(additional_bits);
          return #err(#Malformed(message));
        };
      };
      let value_bytes: [Nat8] = switch (read_bytes(content_byte_length)){
        case (null) return #err(#UnexpectedEndOfBytes);
        case (?b) b;
      };
      #ok(#Bytes(value_bytes));
    }

  };
  public type CborError = {
    #UnexpectedEndOfBytes;
    #Malformed: Text;
  };

  public type CborValue = {
    #MajorType0: Nat64; // 0 -> 2^64 - 1
    #MajorType1: Nat64; // -2^64 -> -1 ((-1 * Value) - 1)
    #MajorType2 : [Nat8];
    #MajorType3: Text;
    #MajorType4: [CborValue];
    #MajorType5: [(CborValue, CborValue)];
    #MajorType6: {
      tag: Nat;
    };
    #MajorType7: {
      #Simple: Nat8;
      #HalfFloat: Nat16;
      #SingleFloat: Nat32;
      #DoubleFloat: Nat64;
      #Break;
    }
  };
  // public type CborValue = {
  //   #MajorType0: Nat64; // TODO needs to be between -2^64 and -1, not -2^64 - 1 and 0
  //   #NegativeInteger: Nat64; // TODO needs to be between -2^64 and -1, not -2^64 - 1 and 0
  //   #ByteString : [Nat8];
  //   #TextString: Text;
  //   #Array: [CborValue];
  //   #Map: {};
  //   #TaggedDataItem: CBORTag;
  //   #FloatOrSimple: FloatOrSimple
  // };

  public type FloatOrSimple = {
  };

  public type CBORTag = {
    #StandardDateTimeString: Text; // 0
    #EpochDate: {#Int: Int; #Float: Float}; // 1
    #UnsignedBignum: [Nat8]; // 2
    #NegativeBignum: [Nat8]; // 3
    // #DecimalFraction: [];
    // #BigFloat: [];
    // .. TODO
  }


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