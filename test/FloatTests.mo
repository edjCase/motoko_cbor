import Blob "mo:base/Blob"; 
import Types "../src/Types";
import Debug "mo:base/Debug";
import FloatX "../src/FloatX";


module {

    public func run(){
        testFloat([0x7b, 0xff], 65504.0);
        testFloat([0x41, 0xb8, 0x00, 0x00], 23.0);
        testFloat([0x40, 0x37, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 23.0);
        // TODO
        // testFloat([0x7c, 0x00], INFINITY);
    };

    func testFloat(bytes: [Nat8], expected: Float) {
        let actualFX = FloatX.decodeFloatX(bytes);
        let precision = switch(bytes.size()) {
            case (2) #f16;
            case (4) #f32;
            case (8) #f64;
            case (a) Debug.trap("Invalid byte size: " # debug_show(bytes.size()));
        };
        let expectedFX = FloatX.floatToFloatX(expected, precision);
        switch(actualFX){
            case (null) Debug.trap("Invalid bytes for float: " # debug_show(bytes));
            case (?v){
                if(v != expectedFX){
                    Debug.trap("Invalid value. Expected: " # debug_show(expected) # ", Actual: " # debug_show(v) # ", Bytes: " # debug_show(bytes));
                };
            }
        }
    };

}