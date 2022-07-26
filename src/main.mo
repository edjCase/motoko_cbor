import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Util "./util";


class CborReader(bytes: Blob) {
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
      case (0) {
        // Check additional bits for value
        // 23 or less => additional bits is the value
        // 24 => read 1 more byte for value
        // 25 => read 2 more bytes for value
        // 26 => read 4 more bytes for value
        // 27 => read 8 more bytes for value
        
        if(additional_bits <= 23){
          return #ok(#UnsignedInteger(Nat8.toNat(additional_bits)));
        };
        let content_byte_length : Nat8 = switch (additional_bits){
          case (24) 1;
          case (25) 2;
          case (26) 4;
          case (27) 8;
          case a {
            let message = "Major type 0 does not support additional bits value: " # Nat8.toText(additional_bits);
            return #err(#Malformed(message));
          };
        };
        let value_bytes: [Nat8] = switch (read_bytes(content_byte_length)){
          case (null) return #err(#UnexpectedEndOfBytes);
          case (?b) b;
        };
        let value: Nat = Util.bytesToNat(value_bytes);
        #ok(#UnsignedInteger(value));
      };
      case _ {
        return #err(#Malformed("Invalid major type: " # Nat8.toText(major_type)));
      };
    }
  };

  private func read_byte() : ?Nat8 {
    byte_position += 1;
    return iterator.next();
  };

  func read_bytes(n : Nat8) : ?[Nat8] {
    if (n < 1) {
      return null;
    };
    let iter: Iter.Iter<Nat> = Iter.range(1, Int8.toInt(Int8.fromNat8(n)));
    let buffer = Buffer.Buffer<Nat8>(Nat8.toNat(n));
    for (i in iter) {
      let byte = switch (read_byte()) {
        case (null) return null;
        case (?byte) byte;
      };
      buffer.add(byte);
    };
    return ?buffer.toArray();
  }
};

type CborError = {
  #UnexpectedEndOfBytes;
  #Malformed: Text;
};

type CborValue = {
  #UnsignedInteger: Nat; 
  #NegativeInteger: Nat; // TODO needs to be between -2^64 and -1, not -2^64 - 1 and 0
  #ByteString : [Nat8];
  #TextString: Text;
  #Array: [CborValue];
  #Map: {};
  #TaggedDataItem: CBORTag;
  #FloatOrSimple: FloatOrSimple
};

type FloatOrSimple = {
  #Simple: Nat8;
  #HalfFloat: Nat16;
  #SingleFloat: Nat32;
  #DoubleFloat: Nat64;
};

type CBORTag = {
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