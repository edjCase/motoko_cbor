import FloatX "mo:xtendedNumbers/FloatX";

module {
  public type DecodingError = {
    #unexpectedEndOfBytes;
    #malformed: Text;
    #invalid: {
      #nat64: [Nat8];
      #utf8String;
      #unexpectedBreak;
    };
  };

  public type EncodingError = {
    #invalidValue: Text;
  };
}