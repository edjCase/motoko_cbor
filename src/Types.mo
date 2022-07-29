
module {
  public type CborValue = {
    #majorType0: Nat64; // 0 -> 2^64 - 1
    #majorType1: Int; // -2^64 -> -1 ((-1 * Value) - 1)
    #majorType2 : [Nat8];
    #majorType3: Text;
    #majorType4: [CborValue];
    #majorType5: [(CborValue, CborValue)];
    #majorType6: {
      tag: Nat64;
      value: CborValue;
    };
    #majorType7: {
      #integer: Nat8;
      #bool: Bool;
      #_null;
      #_undefined;
      #float: Float;
      #_break;
    };
  };

  public type CborReadError = {
    #unexpectedEndOfBytes;
    #malformed: Text;
    #invalid: {
      #utf8String;
      #unexpectedBreak;
    };
  };
}