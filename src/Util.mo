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