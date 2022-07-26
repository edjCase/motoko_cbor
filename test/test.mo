// import Text "mo:base/Text";
// import Matchers "mo:matchers/Matchers";
import T "mo:matchers/Testable";
// import Suite "mo:matchers/Suite";
import Blob "mo:base/Blob"; 
import Cbor "../src/Cbor";
import Debug "mo:base/Debug";
import Result "mo:base/Result";


// let equals10 = Matchers.equals(T.nat(10));
// let equals20 = Matchers.equals(T.nat(20));
// let greaterThan10: Matchers.Matcher<Nat> = Matchers.greaterThan(10);
// let greaterThan20: Matchers.Matcher<Nat> = Matchers.greaterThan(20);

// let suite = Suite.suite("CborReader", [
//     Suite.test("Described as", 20, Matchers.describedAs("20's a lot mate.", equals10)),  
// ]);

// Suite.run(suite)

func test(bytes: [Nat8], expected : Cbor.CborValue) {
    let blob = Blob.fromArray(bytes);
    let reader = Cbor.CborReader(blob);
    let v = reader.read();
    if(v != #ok(expected)){
        Debug.trap("Invalid value. Expected: " # debug_show(#ok(expected)) # ", Actual: " # debug_show(v));
    };
};

test([0x00], #UnsignedInteger(0));
test([0x01], #UnsignedInteger(1));
test([0x0a], #UnsignedInteger(10));
test([0x17], #UnsignedInteger(23));
test([0x18, 0x18], #UnsignedInteger(24));
test([0x18, 0x19], #UnsignedInteger(25));
test([0x18, 0x64], #UnsignedInteger(100));
test([0x19, 0x03, 0xe8], #UnsignedInteger(1000));
test([0x1a, 0x00, 0x0f, 0x42, 0x40], #UnsignedInteger(1000000));
test([0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00], #UnsignedInteger(1000000000000));
test([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], #UnsignedInteger(18446744073709551615));
// test([0xc2, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], #UnsignedInteger(18446744073709551616));
