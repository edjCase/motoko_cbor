import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";

module {
    public func decodeFloat(bytes: [Nat8]) : Float {
        let (sign: Bool, exponent: , mantissa) = switch(bytes.size()) {

        }
        
//   unsigned half = (halfp[0] << 8) + halfp[1];
//   unsigned exp = (half >> 10) & 0x1f;
//   unsigned mant = half & 0x3ff;
//   double val;
//   if (exp == 0) val = ldexp(mant, -24);
//   else if (exp != 31) val = ldexp(mant + 1024, exp - 25);
//   else val = mant == 0 ? INFINITY : NAN;
//   return half & 0x8000 ? -val : val;
    }
}