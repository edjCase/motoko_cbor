import Types "Types";
import Decoder "Decoder";
import Encoder "Encoder";

module {
    public type Value = Types.Value;
    public type DecodingError = Types.DecodingError;
    public type EncodingError = Types.EncodingError;

    public let decode = Decoder.decode;

    public let encode = Encoder.encode;
    public let encodeToBuffer = Encoder.encodeToBuffer;
};
