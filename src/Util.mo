import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

module {
    public func appendArrayToBuffer<T>(buffer : Buffer.Buffer<T>, array : [T]) {
        Iter.iterate(Iter.fromArray(array), func(x : T, _ : Nat) { buffer.add(x) });
    };
};
