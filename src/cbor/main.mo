import T "mo:base/Text";
import O "mo:base/Option";
import A "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import SHA256 "mo:sha256/SHA256";

type CBORValue = {
  #UnsignedInteger: Nat64; 
  #NegativeInteger: Nat64; // TODO needs to be between -2^64 and -1, not -2^64 - 1 and 0
  #ByteString : [Nat8];
  #TextString: Text;
  #Array: [CBORValue];
  #Map: {};
  #TaggedDataItem: CBORTag;
  #FloatOrSimple: FloatOrSimple
};

type FloatOrSimple = {
  Simple: Nat8,
  HalfFloat: Nat16,
  SingleFloat: Nat32,
  DoubleFloat: Nat64,
  
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