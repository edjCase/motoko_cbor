import Blob "mo:base/Blob"; 
import Types "../src/Types";
import Debug "mo:base/Debug";
import Util "../src/Util";


module {

    public func run(){
        testFloat([0x7b, 0xff], 65504);
        testFloat([0x41, 0xb8, 0x00, 0x00], 23);
        testFloat([0x40, 0x37, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 23);
        // TODO
        // testFloat([0x7c, 0x00], INFINITY);
    };

    func testFloat(bytes: [Nat8], expected: Float) {
        let v = Util.decodeFloat(bytes);
        switch(v){
            case (null) Debug.trap("Invalid bytes for float: " # debug_show(bytes));
            case (?v){
                if(v != expected){
                    Debug.trap("Invalid value. Expected: " # debug_show(expected) # ", Actual: " # debug_show(v) # ", Bytes: " # debug_show(bytes));
                };
            }
        }
    };

}