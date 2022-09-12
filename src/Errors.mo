import FloatX "mo:xtendedNumbers/FloatX";

module {
  public type DecodingError = {
    #unexpectedEndOfBytes;
    #unexpectedBreak;
    #invalid: Text;
  };

  public type EncodingError = {
    #invalidValue: Text;
  };
}