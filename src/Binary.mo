import Array "mo:base/Array";
import Int8 "mo:base/Int8";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Int64 "mo:base/Int64";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";

module {
    public type ByteOrder = {
        fromNat16 : (Nat16) -> [Nat8];
	    fromNat32 : (Nat32) -> [Nat8];
	    fromNat64 : (Nat64) -> [Nat8];
        toNat16 : ([Nat8]) -> Nat16;
	    toNat32 : ([Nat8]) -> Nat32;
	    toNat64 : ([Nat8]) -> Nat64;
    };

    private func nat16to8 (n : Nat16) : Nat8 = Nat8.fromIntWrap(Nat16.toNat(n)); 
    private func nat8to16 (n : Nat8) : Nat16 = Nat16.fromIntWrap(Nat8.toNat(n));

    private func nat32to8 (n : Nat32) : Nat8 = Nat8.fromIntWrap(Nat32.toNat(n)); 
    private func nat8to32 (n : Nat8) : Nat32 = Nat32.fromIntWrap(Nat8.toNat(n));

    private func nat64to8 (n : Nat64) : Nat8 = Nat8.fromIntWrap(Nat64.toNat(n));
    private func nat8to64 (n : Nat8) : Nat64 = Nat64.fromIntWrap(Nat8.toNat(n));

    public let LittleEndian : ByteOrder = {
        toNat16 = func (bytes : [Nat8]) : Nat16 {
            if (bytes.size() >= 2){
                Debug.trap("Nat16 can only hold 2 bytes. Input byte length: " # Nat.toText(bytes.size()));
            };
            var nat16 : Nat16 = 0;
            Iter.iterate<Nat8>(Iter.fromArray(bytes), func(x, i) {
                nat16 |= nat8to16(x) << (Nat16.fromNat(i) * 8);
            });
            return nat16;
        };

        fromNat16 = func (n : Nat16) : [Nat8] {
            let b = Array.init<Nat8>(2, 0x00);
            b[0] := nat16to8(n);
            b[1] := nat16to8(n >> 8);
            Array.freeze(b);
        };

        toNat32 = func (bytes : [Nat8]) : Nat32 {
            if (bytes.size() >= 4){
                Debug.trap("Nat32 can only hold 4 bytes. Input byte length: " # Nat.toText(bytes.size()));
            };
            var nat32 : Nat32 = 0;
            Iter.iterate<Nat8>(Iter.fromArray(bytes), func(x, i) {
                nat32 |= nat8to32(x) << (Nat32.fromNat(i) * 8);
            });
            return nat32;
        };

        fromNat32 = func (n : Nat32) : [Nat8] {
            let b = Array.init<Nat8>(4, 0x00);
            b[0] := nat32to8(n);
            b[1] := nat32to8(n >> 8);
            b[2] := nat32to8(n >> 16);
            b[3] := nat32to8(n >> 24);
            Array.freeze(b);
        };

        toNat64 = func (bytes : [Nat8]) : Nat64 {
            let size = bytes.size();
            if (size > 8){
                Debug.trap("Nat64 can only hold 8 bytes. Input byte length: " # Nat.toText(size));
            };
            var nat64 : Nat64 = 0;
            Iter.iterate<Nat>(Iter.range(0, size - 1), func(x, i) {
                let v = bytes[x];
                nat64 |= nat8to64(v) << (Nat64.fromNat(i) * 8);
            });
            return nat64;
        };

        fromNat64 = func (n : Nat64) : [Nat8] {
            let b = Array.init<Nat8>(8, 0x00);
            b[0] := nat64to8(n);
            b[1] := nat64to8(n >> 8);
            b[2] := nat64to8(n >> 16);
            b[3] := nat64to8(n >> 24);
            b[4] := nat64to8(n >> 32);
            b[5] := nat64to8(n >> 40);
            b[6] := nat64to8(n >> 48);
            b[7] := nat64to8(n >> 56);
            Array.freeze(b);
        };
    };

    public let BigEndian : ByteOrder = {
        toNat16 = func (bytes : [Nat8]) : Nat16 {
            nat8to16(bytes[1]) | nat8to16(bytes[0]) << 8;
        };

        fromNat16 = func (n : Nat16) : [Nat8] {
            let b = Array.init<Nat8>(2, 0x00);
            b[0] := nat16to8(n >> 8);
            b[1] := nat16to8(n);
            Array.freeze(b);
        };

        toNat32 = func (bytes : [Nat8]) : Nat32 {
            nat8to32(bytes[3]) | nat8to32(bytes[2]) << 8 | nat8to32(bytes[1]) << 16 | nat8to32(bytes[0]) << 24;
        };

        fromNat32 = func (n : Nat32) : [Nat8] {
            let b = Array.init<Nat8>(4, 0x00);
            b[0] := nat32to8(n >> 24);
            b[1] := nat32to8(n >> 16);
            b[2] := nat32to8(n >> 8);
            b[3] := nat32to8(n);
            Array.freeze(b);
        };

        toNat64 = func (bytes : [Nat8]) : Nat64 {
            let size : Nat = bytes.size();
            if (size > 8){
                Debug.trap("Nat64 can only hold 8 bytes. Input byte length: " # Nat.toText(size));
            };
            if(size < 1) {
                return 0;
            };
            var nat64 : Nat64 = 0;
            let lastIndex : Nat = size - 1;
            Iter.iterate<Nat8>(Iter.fromArray(bytes), func(v, i) {
                nat64 |= nat8to64(v) << (Nat64.fromNat(lastIndex - i) * 8);
            });
            return nat64;
        };

        fromNat64 = func (n : Nat64) : [Nat8] {
            let b = Array.init<Nat8>(8, 0x00);
            b[0] := nat64to8(n >> 56);
            b[1] := nat64to8(n >> 48);
            b[2] := nat64to8(n >> 40);
            b[3] := nat64to8(n >> 32);
            b[4] := nat64to8(n >> 24);
            b[5] := nat64to8(n >> 16);
            b[6] := nat64to8(n >> 8);
            b[7] := nat64to8(n);
            Array.freeze(b);
        };
    };
};