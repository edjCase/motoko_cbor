import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int64 "mo:base/Int64";
import Float "mo:base/Float";
import Binary "./Binary";
  
  module {
    public type FloatX = {#f16: Float16; #f32: Float32; #f64: Float64};
    public type FloatBits = {
        isNegative: Bool;
        exponentBits: Nat64;
        mantissaBits: Nat64;
    };

    private type FloatBitInfo = {
        exponentBitLength: Nat64;
        mantissaBitLength: Nat64;
        encodeToBytes: (Nat64) -> [Nat8];
    };

    let float16BitInfo: FloatBitInfo = {
        exponentBitLength = 5;
        mantissaBitLength = 10;
        encodeToBytes = func (bits: Nat64): [Nat8] {
            let nat16 = Nat16.fromNat(Nat64.toNat(bits));
            Binary.BigEndian.fromNat16(nat16);
        };
    };

    let float32BitInfo: FloatBitInfo = {
        exponentBitLength = 8;
        mantissaBitLength = 23;
        encodeToBytes = func (bits: Nat64): [Nat8] {
            let nat32 = Nat32.fromNat(Nat64.toNat(bits));
            Binary.BigEndian.fromNat32(nat32);
        };
    };

    let float64BitInfo: FloatBitInfo = {
        exponentBitLength = 11;
        mantissaBitLength = 52;
        encodeToBytes = func (bits: Nat64): [Nat8] {
            Binary.BigEndian.fromNat64(bits);
        };
    };

    public class Float16(isNegative: Bool, exponentBits: Nat64, mantissaBits: Nat64) {
        private var byteCache: ?[Nat8] = null;

        public func toBytes() : [Nat8] {
            switch (byteCache) {
                case (?b) b;
                case (null) {
                    let bytes = encodeFloatInternal(isNegative, exponentBits, mantissaBits, float16BitInfo);
                    byteCache := ?bytes;
                    bytes;
                }
            }
        };

        public func toFloat() : Float {
            floatXToFloatInternal(isNegative, exponentBits, mantissaBits, float16BitInfo);
        };

        public func equal(other: Float16) : Bool {
            toBytes() == other.toBytes();
        }
    };

    public class Float32(isNegative: Bool, exponentBits: Nat64, mantissaBits: Nat64) {
        private var byteCache: ?[Nat8] = null;

        public func toBytes() : [Nat8] {
            switch (byteCache) {
                case (?b) b;
                case (null) {
                    let bytes = encodeFloatInternal(isNegative, exponentBits, mantissaBits, float32BitInfo);
                    byteCache := ?bytes;
                    bytes;
                }
            }
        };

        public func toFloat() : Float {
            floatXToFloatInternal(isNegative, exponentBits, mantissaBits, float32BitInfo);
        };

        public func equal(other: Float32) : Bool {
            toBytes() == other.toBytes();
        }
    };

    public class Float64(isNegative: Bool, exponentBits: Nat64, mantissaBits: Nat64) {
        private var byteCache: ?[Nat8] = null;
        
        public func toBytes() : [Nat8] {
            switch (byteCache) {
                case (?b) b;
                case (null) {
                    let bytes = encodeFloatInternal(isNegative, exponentBits, mantissaBits, float64BitInfo);
                    byteCache := ?bytes;
                    bytes;
                }
            }
        };

        public func toFloat() : Float {
            floatXToFloatInternal(isNegative, exponentBits, mantissaBits, float64BitInfo);
        };

        public func equal(other: Float64) : Bool {
            toBytes() == other.toBytes();
        }
    };

    public func encodeFloatX(f: FloatX) : [Nat8] {
        switch (f) {
            case (#f16(f16)) f16.toBytes();
            case (#f32(f32)) f32.toBytes();
            case (#f64(f64)) f64.toBytes();
        }
    };

    public func floatToFloat16(f: Float) : Float16 {
        floatToFloatXInternal(f, float16BitInfo);
    };

    public func floatToFloat32(f: Float) : Float32 {
        floatToFloatXInternal(f, float32BitInfo);
    };

    public func floatToFloat64(f: Float) : Float64 {
        floatToFloatXInternal(f, float64BitInfo);
    };

    private func encodeFloatInternal(isNegative: Bool, exponentBits: Nat64, mantissaBits: Nat64, bitInfo: FloatBitInfo) : [Nat8] {
        var bits: Nat64 = 0;
        if(isNegative) {
            bits |= 0x01;
        };
        bits <<= bitInfo.exponentBitLength;
        bits |= exponentBits;
        bits <<= bitInfo.mantissaBitLength;
        bits |= mantissaBits;

        bitInfo.encodeToBytes(bits);
    };


    public func decodeFloat16(bytes: [Nat8]) : ?Float16 {
        switch(decodeFloatX(bytes)) {
            case (?#f16(f)) ?f;
            case (x) null;
        };
    };

    public func decodeFloat32(bytes: [Nat8]) : ?Float32 {
        switch(decodeFloatX(bytes)) {
            case (?#f32(f)) ?f;
            case (x) null;
        };
    };

    public func decodeFloat64(bytes: [Nat8]) : ?Float64 {
        switch(decodeFloatX(bytes)) {
            case (?#f64(f)) ?f;
            case (x) null;
        };
    };

    public func decodeFloat(bytes: [Nat8]) : ?Float {
        switch(decodeFloatX(bytes)) {
            case (?#f16(f16)) ?f16.toFloat();
            case (?#f32(f32)) ?f32.toFloat();
            case (?#f64(f64)) ?f64.toFloat();
            case (x) null;
        };
    };

    public func decodeFloatX(bytes: [Nat8]) : ?FloatX {
        var bits: Nat64 = Binary.BigEndian.toNat64(bytes);
        let bitInfo: FloatBitInfo = switch(bytes.size()) {
            case (2) float16BitInfo;
            case (4) float32BitInfo;
            case (8) float64BitInfo;
            case (a) return null; 
        };
        let (exponentBitLength: Nat64, mantissaBitLength: Nat64) = (bitInfo.exponentBitLength, bitInfo.mantissaBitLength);
        // Bitshift to get mantissa, exponent and sign bits
        let mantissaBits: Nat64 = bits & (Nat64.pow(2, mantissaBitLength) - 1);
        let exponentBits: Nat64 = (bits >> mantissaBitLength) & (Nat64.pow(2, exponentBitLength) - 1);
        let signBits: Nat64 = (bits >> (mantissaBitLength + exponentBitLength)) & 0x01;
        
        // Make negative if sign bit is 1
        let isNegative: Bool = signBits == 1;
        let fX: FloatX = switch(bytes.size()) {
            case (2) #f16(Float16(isNegative, exponentBits, mantissaBits));
            case (4) #f32(Float32(isNegative, exponentBits, mantissaBits));
            case (8) #f64(Float64(isNegative, exponentBits, mantissaBits));
            case (a) return null;
        };
        ?fX
    };

    private func floatXToFloatInternal(isNegative: Bool, exponentBits: Nat64, mantissaBits: Nat64, bitInfo: FloatBitInfo) : Float {
        // Convert bits into numbers
        // e = 2 ^ (exponent - (2 ^ exponentBitLength / 2 - 1))
        let e: Int64 = Int64.pow(2, Int64.fromNat64(exponentBits) - ((Int64.fromNat64(Nat64.pow(2, bitInfo.exponentBitLength) / 2)) - 1));
        // moi = 2 ^ (mantissaBitLength * -1)
        let maxOffsetInverse: Float = Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.mantissaBitLength)) * -1);
        // m = 1 + mantissa * moi
        let m: Float = 1.0 + (Float.fromInt64(Int64.fromNat64(mantissaBits)) * maxOffsetInverse);
        // v = e * m
        var floatValue: Float = Float.fromInt64(e) * m;

        if (isNegative) {
            floatValue := Float.mul(floatValue, -1.0);
        };
        
        floatValue;
    };

    private func floatToFloatXInternal(float: Float, bitInfo: FloatBitInfo) : Float64 {
        // TODO convert 
        let isNegative = float < 0;

        // exponent is the power of 2 that is closest to the value without going over
        // exponent = trunc(log2(|value|))
        // where log2(x) = log(x)/log(2)
        let e = Float.log(Float.abs(float))/Float.log(2);
        let exponent: Nat64 = Int64.toNat64(Float.toInt64(e)); // Truncate
        // Max bit value is how many values can fit in the bit length
        let maxBitValue: Nat64 = Int64.toNat64(Float.toInt64(Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.exponentBitLength)))));
        // Exponent bits is a range of -(2^expBitLength/2) -1 -> (2^expBitLength/2)
        let exponentBits: Nat64 = exponent + ((maxBitValue / 2) - 1);

        // mantissaMaxOffset = 2 ^ mantissaBitLength
        let mantissaMaxOffset: Nat64 = Int64.toNat64(Float.toInt64(Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.mantissaBitLength)))));
        // The mantissa is the % of the exponent as the remainder between exponent and real value
        let mantissa: Float = (float / Float.pow(2, Float.fromInt64(Int64.fromNat64(exponent)))) - 1;
        // Bits represent how many offsets there are between the exponent and the value
        let mantissaBits: Nat64 = Int64.toNat64(Float.toInt64(Float.nearest(mantissa * Float.fromInt64(Int64.fromNat64(mantissaMaxOffset)))));
        Float64(isNegative, exponentBits, mantissaBits);
    };
  }