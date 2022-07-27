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
        Debug.trap("Invalid value. Expected: " # debug_show(#ok(expected)) # ", Actual: " # debug_show(v) # ", Bytes: " # debug_show(bytes));
    };
};

// Major Type 0
test([0x00], #MajorType0(0));
test([0x01], #MajorType0(1));
test([0x0a], #MajorType0(10));
test([0x17], #MajorType0(23));
test([0x18, 0x18], #MajorType0(24));
test([0x18, 0x19], #MajorType0(25));
test([0x18, 0x64], #MajorType0(100));
test([0x19, 0x03, 0xe8], #MajorType0(1000));
test([0x1a, 0x00, 0x0f, 0x42, 0x40], #MajorType0(1000000));
test([0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00], #MajorType0(1000000000000));
test([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], #MajorType0(18446744073709551615));

// Major Type 1
test([0x20], #MajorType1(0));
test([0x29], #MajorType1(9));
test([0x38, 0x63], #MajorType1(99));
test([0x39, 0x03, 0xe7], #MajorType1(999));
test([0x3b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], #MajorType1(18446744073709551615));

// Major Type 2
test([0x40], #MajorType2([]));
test([0x44, 0x01, 0x02, 0x03, 0x04], #MajorType2([0x01, 0x02, 0x03, 0x04]));
test([0x58, 0x01, 0x02], #MajorType2([0x02]));
test([0x59, 0x00, 0x01, 0x03], #MajorType2([0x03]));
test([0x5a, 0x00, 0x00, 0x00, 0x01, 0x04], #MajorType2([0x04]));
test([0x5b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x05], #MajorType2([0x05]));

// TODO use 
// 0b010_11111 0b010_00100 0xaabbccdd 0b010_00011 0xeeff99 0b111_11111
// 5F              -- Start indefinite-length byte string
//    44           -- Byte string of length 4
//       aabbccdd  -- Bytes content
//    43           -- Byte string of length 3
//       eeff99    -- Bytes content
//    FF           -- "break"
// test([0x5f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xff], #MajorType2([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]));


// Major Type 3



// Major Type 6
// test([0xc2, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], #MajorType6({tag: 18446744073709551616));
// test([0xc3, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], #MajorType6({tag: -18446744073709551617));
