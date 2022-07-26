import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";

module {
    public func convertNat8To16(nat: Nat8) : Nat16 {
        return Nat16.fromNat(Nat8.toNat(nat)); // TODO better way?
    };

    public func bytesToNat(bytes: [Nat8]) : Nat {
        return 0; // TODO
    };
}