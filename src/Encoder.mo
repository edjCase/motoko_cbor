import Binary "./Binary";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Util "./Util";
import Types "./Types";

module {
  public func encode(value: Types.CborValue) : Result.Result<[Nat8], Types.CborEncodingError> {
    switch(value) {
      case (#majorType0(t0)) encodeMajorType0(t0);
      case (#majorType1(t1)) encodeMajorType1(t1);
      case (#majorType2(t2)) encodeMajorType2(t2);
      case (#majorType3(t3)) encodeMajorType3(t3);
      case (#majorType4(t4)) encodeMajorType4(t4);
      case (#majorType5(t5)) encodeMajorType5(t5);
      case (#majorType6(t6)) encodeMajorType6(t6.tag, t6.value);
      case (#majorType7(t7)) {
        switch(t7) {
          case (#_break) return #err(#invalidValue("Break is not allowed as a value"));
          case (#_null) encodeMajorType7(#_null);
          case (#_undefined) encodeMajorType7(#_undefined);
          case (#bool(b)) encodeMajorType7(#bool(b));
          case (#float(f)) encodeMajorType7(#float(f));
          case (#integer(i)) encodeMajorType7(#integer(i));
        }
      };
    };
  };

  public func encodeMajorType0(value: Nat64) : Result.Result<[Nat8], Types.CborEncodingError> {
    let bytes = encodeNatInternal(0, value);
    return #ok(bytes);
  };

  public func encodeMajorType1(value: Int) : Result.Result<[Nat8], Types.CborEncodingError> {
    let maxValue: Int = -1;
    let minValue: Int = -0x10000000000000000;
    Debug.print("Value: " # debug_show(value));
    Debug.print("Min value: " # debug_show(minValue));
    if(value > maxValue or value < minValue) {
      return #err(#invalidValue("Major type 1 values must be between -2^64 and -1"));
    };
    let natValue: Nat = Int.abs(value + 1);
    Debug.print("Nat value: " # debug_show(natValue));
    let bytes = encodeNatInternal(1, Nat64.fromNat(natValue));
    return #ok(bytes);
  };

  public func encodeMajorType2(value: [Nat8]) : Result.Result<[Nat8], Types.CborEncodingError> {
    #ok([]);
  };

  public func encodeMajorType3(value: Text) : Result.Result<[Nat8], Types.CborEncodingError> {
    #ok([]);
  };

  public func encodeMajorType4(value: [Types.CborValue]) : Result.Result<[Nat8], Types.CborEncodingError> {
    #ok([]);
  };

  public func encodeMajorType5(value: [(Types.CborValue, Types.CborValue)]) : Result.Result<[Nat8], Types.CborEncodingError> {
    #ok([]);
  };

  public func encodeMajorType6(tag: Nat64, value: Types.CborValue) : Result.Result<[Nat8], Types.CborEncodingError> {
    #ok([]);
  };

  public func encodeMajorType7(value: {#integer: Nat8; #bool: Bool; #_null; #_undefined; #float: Float;}) : Result.Result<[Nat8], Types.CborEncodingError> {
    #ok([]);
  };

  private func encodeRaw(majorType: Nat8, additionalBits: Nat8, additionalBytes: ?[Nat8]) : [Nat8] {
    let firstByte: Nat8 = majorType << 5 + additionalBits;
    switch(additionalBytes) {
      case (null) [firstByte];
      case (?bytes) {
        let buffer = Buffer.Buffer<Nat8>(bytes.size() + 1);
        buffer.add(firstByte);
        let otherBuffer = Buffer.Buffer<Nat8>(bytes.size());
        Iter.iterate(Iter.fromArray(bytes), func(x : Nat8, ix : Nat) { otherBuffer.add(x) });        
        buffer.append(otherBuffer);
        buffer.toArray();
      };
    }
  };

  private func encodeNatInternal(majorType: Nat8, value: Nat64) : [Nat8] {
    let (additionalBits: Nat8, additionalBytes: ?[Nat8]) = if (value <= 23) {
      (Nat8.fromNat(Nat64.toNat(value)), null);
    } else {
      if (value <= 0xff) {
        (24: Nat8, ?[Nat8.fromNat(Nat64.toNat(value))]); // 24 indicates 1 more byte of info
      } else if (value <= 0xffff) {
        (25: Nat8, ?Binary.BigEndian.fromNat16(Nat16.fromNat(Nat64.toNat(value))));// 25 indicates 2 more bytes of info
      } else if (value <= 0xffffffff) {
        (26: Nat8, ?Binary.BigEndian.fromNat32(Nat32.fromNat(Nat64.toNat(value)))); // 26 indicates 4 more byte of info
      } else {
        (27: Nat8, ?Binary.BigEndian.fromNat64(value)); // 27 indicates 8 more byte of info
      }
    };
    encodeRaw(majorType, additionalBits, additionalBytes);
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