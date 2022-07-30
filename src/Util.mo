import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Int16 "mo:base/Int16";
import Int64 "mo:base/Int64";
import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Binary "./Binary";

module {
    public func decodeFloat(bytes: [Nat8]) : ?Float {
        var bits: Nat64 = Binary.BigEndian.toNat64(bytes);
        let (exponentBitLength: Nat64, mantissaBitLength: Nat64) = switch(bytes.size()) {
            case (2) {
                (5: Nat64, 10: Nat64);
            };
            case (4) {
                (8: Nat64, 23: Nat64);
            };
            case (8) {
                (11: Nat64, 52: Nat64);
            };
            case (a) return null; 
        };
        // Bitshift to get mantissa, exponent and sign bits
        let mantissaBits: Nat64 = bits & (Nat64.pow(2, mantissaBitLength) - 1);
        let exponentBits: Nat64 = (bits >> mantissaBitLength) & (Nat64.pow(2, exponentBitLength) - 1);
        let signBits: Nat64 = (bits >> (mantissaBitLength + exponentBitLength)) & 0x01;

        // Convert bits into numbers
        let e: Int64 = Int64.pow(2, Int64.fromNat64(exponentBits) - ((Int64.fromNat64(Nat64.pow(2, exponentBitLength) / 2)) - 1));
        let maxOffsetInverse: Float = Float.pow(2, Float.fromInt64(Int64.fromNat64(mantissaBitLength)) * -1);
        let m: Float = 1.0 + (Float.fromInt64(Int64.fromNat64(mantissaBits)) * maxOffsetInverse);

        var floatValue: Float = Float.fromInt64(e) * m;

        // Make negative if sign bit is 1
        if (signBits == 1) {
            floatValue := Float.mul(floatValue, -1.0);
        };
        
        ?floatValue;
    };

    public func concatArrays<T>(x: [T], y: [T]) : [T] {
        let buffer = Buffer.Buffer<T>(x.size() + y.size());
        appendArrayToBuffer(buffer, x);
        appendArrayToBuffer(buffer, y);
        buffer.toArray();
    };

    public func appendArrayToBuffer<T>(buffer: Buffer.Buffer<T>, array: [T]) {
        Iter.iterate(Iter.fromArray(array), func(x : T, ix : Nat) { buffer.add(x) });
    };
}