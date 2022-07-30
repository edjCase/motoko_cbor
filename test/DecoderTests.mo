import Blob "mo:base/Blob"; 
import Types "../src/Types";
import CborDecoder "../src/Decoder";
import CborEncoder "../src/Encoder";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Char "mo:base/Char";
import Util "../src/Util";


module {

    public func run() {
        // Major Type 0
        test([0x00], #majorType0(0), null);
        test([0x01], #majorType0(1), null);
        test([0x0a], #majorType0(10), null);
        test([0x17], #majorType0(23), null);
        test([0x18, 0x18], #majorType0(24), null);
        test([0x18, 0x19], #majorType0(25), null);
        test([0x18, 0x64], #majorType0(100), null);
        test([0x19, 0x03, 0xe8], #majorType0(1000), null);
        test([0x1a, 0x00, 0x0f, 0x42, 0x40], #majorType0(1000000), null);
        test([0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00], #majorType0(1000000000000), null);
        test([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], #majorType0(18446744073709551615), null);

        // Major Type 1
        test([0x20], #majorType1(-1), null);
        test([0x29], #majorType1(-10), null);
        test([0x38, 0x63], #majorType1(-100), null);
        test([0x39, 0x03, 0xe7], #majorType1(-1000), null);
        test([0x3b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], #majorType1(-18446744073709551616), null);

        // Major Type 2
        test([0x40], #majorType2([]), null);
        test([0x44, 0x01, 0x02, 0x03, 0x04], #majorType2([0x01, 0x02, 0x03, 0x04]), null);
        test([0x58, 0x01, 0x02], #majorType2([0x02]), ?[0x41, 0x02]);
        test([0x41, 0x02], #majorType2([0x02]), null);
        test([0x59, 0x00, 0x01, 0x03], #majorType2([0x03]), ?[0x41, 0x03]);
        test([0x41, 0x03], #majorType2([0x03]), null);
        test([0x5a, 0x00, 0x00, 0x00, 0x01, 0x04], #majorType2([0x04]), ?[0x41, 0x04]);
        test([0x41, 0x04], #majorType2([0x04]), null);
        test([0x5b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x05], #majorType2([0x05]), ?[0x41, 0x05]);
        test([0x41, 0x05], #majorType2([0x05]), null);
        // Indef
        test([0x5f, 0x44, 0xaa, 0xbb, 0xcc, 0xdd, 0xff], #majorType2([0xaa, 0xbb, 0xcc, 0xdd]), ?[0x44, 0xaa, 0xbb, 0xcc, 0xdd]);
        test([0x44, 0xaa, 0xbb, 0xcc, 0xdd], #majorType2([0xaa, 0xbb, 0xcc, 0xdd]), null);
        test([0x5f, 0x42, 0x01, 0x02, 0x43, 0x03, 0x04, 0x05, 0xff], #majorType2([0x01, 0x02, 0x03, 0x04, 0x05]), ?[0x45, 0x01, 0x02, 0x03, 0x04, 0x05]);
        test([0x45, 0x01, 0x02, 0x03, 0x04, 0x05], #majorType2([0x01, 0x02, 0x03, 0x04, 0x05]), null);


        // Major Type 3
        test([0x60], #majorType3(""), null);
        test([0x61, 0x61], #majorType3("a"), null);
        test([0x64, 0x49, 0x45, 0x54, 0x46], #majorType3("IETF"), null);
        test([0x62, 0x22, 0x5c], #majorType3("\"\\"), null);
        test([0x62, 0xc3, 0xbc], #majorType3("\u{00fc}"), null);
        test([0x63, 0xe6, 0xb0, 0xb4], #majorType3("\u{6c34}"), null);
        // TODO test failure
        // test([0x64, 0xf0, 0x90, 0x85, 0x91], #Invalid(#UTF8String));
        //Indef 
        test([0x7f, 0x65, 0x73, 0x74, 0x72, 0x65, 0x61, 0x64, 0x6d, 0x69, 0x6e, 0x67, 0xff], #majorType3("streaming"), ?[0x69, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6D, 0x69, 0x6E, 0x67]);
        test([0x69, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6D, 0x69, 0x6E, 0x67], #majorType3("streaming"), null);





        // Major Type 4
        test([0x80], #majorType4([]), null);
        test([0x83, 0x01, 0x02, 0x03], #majorType4([#majorType0(1), #majorType0(2), #majorType0(3)]), null);
        test([0x83, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05], #majorType4([#majorType0(1), #majorType4([#majorType0(2), #majorType0(3)]), #majorType4([#majorType0(4), #majorType0(5)])]), null);
        test([0x98, 0x19, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x18, 0x18, 0x19], #majorType4([#majorType0(1), #majorType0(2), #majorType0(3), #majorType0(4), #majorType0(5), #majorType0(6), #majorType0(7), #majorType0(8), #majorType0(9), #majorType0(10), #majorType0(11), #majorType0(12), #majorType0(13), #majorType0(14), #majorType0(15), #majorType0(16), #majorType0(17), #majorType0(18), #majorType0(19), #majorType0(20), #majorType0(21), #majorType0(22), #majorType0(23), #majorType0(24), #majorType0(25)]), null);
        test([0x82, 0x61, 0x61, 0xa1, 0x61, 0x62, 0x61, 0x63], #majorType4([#majorType3("a"), #majorType5([(#majorType3("b"), #majorType3("c"))])]), null);
        // Indef
        test([0x9f, 0xff], #majorType4([]), ?[0x80]);
        test([0x9f, 0x01, 0x82, 0x02, 0x03, 0x9f, 0x04, 0x05, 0xff, 0xff], #majorType4([#majorType0(1), #majorType4([#majorType0(2), #majorType0(3)]), #majorType4([#majorType0(4), #majorType0(5)])]), ?[0x83, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]);
        test([0x9f, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05, 0xff], #majorType4([#majorType0(1), #majorType4([#majorType0(2), #majorType0(3)]), #majorType4([#majorType0(4), #majorType0(5)])]), ?[0x83, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]);
        test([0x83, 0x01, 0x9f, 0x02, 0x03, 0xff, 0x82, 0x04, 0x05], #majorType4([#majorType0(1), #majorType4([#majorType0(2), #majorType0(3)]), #majorType4([#majorType0(4), #majorType0(5)])]), ?[0x83, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]);
        test([0x9f, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x18, 0x18, 0x19, 0xff], #majorType4([#majorType0(1), #majorType0(2), #majorType0(3), #majorType0(4), #majorType0(5), #majorType0(6), #majorType0(7), #majorType0(8), #majorType0(9), #majorType0(10), #majorType0(11), #majorType0(12), #majorType0(13), #majorType0(14), #majorType0(15), #majorType0(16), #majorType0(17), #majorType0(18), #majorType0(19), #majorType0(20), #majorType0(21), #majorType0(22), #majorType0(23), #majorType0(24), #majorType0(25)]), null);


        // Major Type 5
        test([0xa0], #majorType5([]), null);
        test([0xa2, 0x01, 0x02, 0x03, 0x04], #majorType5([(#majorType0(1),#majorType0(2)), (#majorType0(3), #majorType0(4))]), null);
        test([0xa2, 0x61, 0x61, 0x01, 0x61, 0x62, 0x82, 0x02, 0x03], #majorType5([(#majorType3("a"),#majorType0(1)), (#majorType3("b"), #majorType4([#majorType0(2), #majorType0(3)]))]), null);
        test([0xa5, 0x61, 0x61, 0x61, 0x41, 0x61, 0x62, 0x61, 0x42, 0x61, 0x63, 0x61, 0x43, 0x61, 0x64, 0x61, 0x44, 0x61, 0x65, 0x61, 0x45], #majorType5([(#majorType3("a"),#majorType3("A")), (#majorType3("b"), #majorType3("B")), (#majorType3("c"), #majorType3("C")), (#majorType3("d"), #majorType3("D")), (#majorType3("e"), #majorType3("E"))]), null);
        // Indef
        test([0xbf, 0x61, 0x61, 0x01, 0x61, 0x62, 0x9f, 0x02, 0x03, 0xff, 0xff], #majorType5([(#majorType3("a"),#majorType0(1)), (#majorType3("b"), #majorType4([#majorType0(2), #majorType0(3)]))]), null);
        test([0x82, 0x61, 0x61, 0xbf, 0x61, 0x62, 0x61, 0x63, 0xff], #majorType4([#majorType3("a"), #majorType5([(#majorType3("b"), #majorType3("c"))])]), null);
        test([0xbf, 0x63, 0x46, 0x75, 0x6e, 0xf5, 0x63, 0x41, 0x6d, 0x74, 0x21, 0xff], #majorType5([(#majorType3("Fun"), #majorType7(#bool(true))), (#majorType3("Amt"), #majorType1(-2))]), null);



        // Major Type 6
        test([0xc0, 0x74, 0x32, 0x30, 0x31, 0x33, 0x2d, 0x30, 0x33, 0x2d, 0x32, 0x31, 0x54, 0x32, 0x30, 0x3a, 0x30, 0x34, 0x3a, 0x30, 0x30, 0x5a], #majorType6({tag=0; value=#majorType3("2013-03-21T20:04:00Z")}), null);
        test([0xc1, 0x1a, 0x51, 0x4b, 0x67, 0xb0], #majorType6({tag=1; value=#majorType0(1363896240)}), null);
        test([0xc1, 0xfb, 0x41, 0xd4, 0x52, 0xd9, 0xec, 0x20, 0x00, 0x00], #majorType6({tag=1; value=#majorType7(#float(1363896240.5))}), null);
        test([0xd7, 0x44, 0x01, 0x02, 0x03, 0x04], #majorType6({tag=23; value=#majorType2([0x01, 0x02, 0x03, 0x04])}), null);
        test([0xd8, 0x18, 0x45, 0x64, 0x49, 0x45, 0x54, 0x46], #majorType6({tag=24; value=#majorType2([0x64, 0x49, 0x45, 0x54, 0x46])}), null);
        test([0xd8, 0x20, 0x76, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d], #majorType6({tag=32; value=#majorType3("http://www.example.com")}), null);
        test([0xc2, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], #majorType6({tag=2; value=#majorType2([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])}), null);
        test([0xc3, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], #majorType6({tag=3; value=#majorType2([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])}), null);


        // Major Type 7
        test([0xf4], #majorType7(#bool(false)), null);
        test([0xf5], #majorType7(#bool(true)), null);
        test([0xf6], #majorType7(#_null), null);
        test([0xf7], #majorType7(#_undefined), null);
        test([0xf0], #majorType7(#integer(16)), null);
        test([0xf8, 0x20], #majorType7(#integer(32)), null);
        test([0xf8, 0xff], #majorType7(#integer(255)), null);
        // TODO this is not allowed
        // test([0xf8], #majorType7(#integer(23)), null); 
        // test([0xf8, 0x18], #majorType7(#integer(24)), null);
    };

    func test(bytes: [Nat8], expected : Types.CborValue, reverseValue: ?[Nat8]) {
        let decodeResult = CborDecoder.decodeBytes(bytes);
        let actual: Types.CborValue = trapOrReturn<Types.CborValue, Types.CborDecodingError>(decodeResult, func (e) { debug_show(e) });
        if(actual != expected){
            Debug.trap("Invalid value.\nExpected: " # debug_show(expected) # "\nActual: " # debug_show(actual) # "\nBytes: " # toHexString(bytes));
        };
        let encodeResult = CborEncoder.encode(actual);
        let actualBytes = trapOrReturn<[Nat8], Types.CborEncodingError>(encodeResult, func (e) { debug_show(e) });
        let comparisonValue: [Nat8] = switch (reverseValue) {
            case (null) bytes;
            case (?v) v;
        };
        if(actualBytes != comparisonValue) {
            Debug.trap("Invalid value.\nExpected: " # toHexString(comparisonValue) # "\nActual:   " # toHexString(actualBytes) # "\nValue: " # debug_show(actual));
        };
    };

    func trapOrReturn<TValue, TErr>(result: Result.Result<TValue, TErr>, show: (TErr) -> Text) : TValue {
        switch(result){
            case (#err(e)) Debug.trap("Error: " # show(e));
            case (#ok(a)) a;
        }
    };

    public func toHexString(array : [Nat8]) : Text {
        Array.foldLeft<Nat8, Text>(array, "", func (accum, w8) {
            var pre = "";
            if(accum != ""){
                pre #= ", ";
            };
            accum # pre # encodeW8(w8);
        });
    };
    private let base : Nat8 = 0x10; 

    private let symbols = [
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
    ];
    /**
    * Encode an unsigned 8-bit integer in hexadecimal format.
    */
    private func encodeW8(w8 : Nat8) : Text {
        let c1 = symbols[Nat8.toNat(w8 / base)];
        let c2 = symbols[Nat8.toNat(w8 % base)];
        "0x" # Char.toText(c1) # Char.toText(c2);
    };
}
