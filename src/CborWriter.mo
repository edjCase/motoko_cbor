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
  public class CborWriter(buffer: Buffer.Buffer<Nat8>) {
    let writeBuffer : Buffer.Buffer<Nat8> = buffer;

    public func write(value: CborValue) {
      switch(value) {
        case (#majorType0(t0)) writeMajorType0(t0);
      };
    };

    public func writeMajorType0(value: Nat64) {
      var additonalBits;
      var additionalBytes : ?[Nat8] = null;
      if (value <= 23) {
        additonalBits := value;
      } else {
        if (value <= 0xff) {
          additionalBits := 24; // 24 indicates 1 more byte of info
          additionalBytes := Binary.BigEndian.fromNat8(Nat8.fromNat(Nat64.toNat(value)));
        } else if (value <= 0xffff) {
          additionalBits := 25; // 25 indicates 2 more bytes of info
          additionalBytes := Binary.BigEndian.fromNat16(Nat16.fromNat(Nat64.toNat(value)));
        } else if (value <= 0xffffffff) {
          additionalBits := 26; // 26 indicates 4 more byte of info
          additionalBytes := Binary.BigEndian.fromNat32(Nat32.fromNat(Nat64.toNat(value)));
        } else {
          additionalBits := 27; // 27 indicates 8 more byte of info
          additionalBytes := Binary.BigEndian.fromNat64(value);
        }
      }
      writeRaw(0, additionalBits, additionalBytes);
    };

    private func writeRaw(majorType: Nat8, additionalBits: Nat8, additionalBytes: ?[Nat8]) {

    };

  };
  public type CborWriteError = {
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