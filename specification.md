# Specification of Model Definition (Draft)

// Graph contains nodes

message GraphDef {
  repeated NodeDef node = 1;
  int32 version = 3 [deprecated = true];
  FunctionDefLibrary library = 2;
};

// Node containes Attr-value pairs

message NodeDef {
  string name = 1;
  string op = 2;
  repeated string input = 3;
  string device = 4;
  map<string, AttrValue> attr = 5;
}

// AttrValue, the value for an attr used to configure an Op.
message AttrValue {
  message ListValue {
    repeated bytes s = 2;                        // "list(string)"
    repeated int64 i = 3 [packed = true];        // "list(int)"
    repeated float f = 4 [packed = true];        // "list(float)"
    repeated bool b = 5 [packed = true];         // "list(bool)"
    repeated DataType type = 6 [packed = true];  // "list(type)"
    repeated TensorShapeProto shape = 7;         // "list(shape)"
    repeated TensorProto tensor = 8;             // "list(tensor)"
    repeated NameAttrList func = 9;              // "list(attr)"
  }

  oneof value {
    bytes s = 2;                 // "string"
    int64 i = 3;                 // "int"
    float f = 4;                 // "float"
    bool b = 5;                  // "bool"
    DataType type = 6;           // "type"
    TensorShapeProto shape = 7;  // "shape"
    TensorProto tensor = 8;      // "tensor"
    ListValue list = 1;          // any "list(...)"
    NameAttrList func = 10;
    string placeholder = 9;
  }
}

message NameAttrList {
  string name = 1;
  map<string, AttrValue> attr = 2;
}

// Tensor

message TensorProto {
  DataType dtype = 1;
  TensorShapeProto tensor_shape = 2;
  int32 version_number = 3;
  bytes tensor_content = 4;
  repeated int32 half_val = 13 [packed = true];
  repeated float float_val = 5 [packed = true];
  repeated double double_val = 6 [packed = true];
  repeated int32 int_val = 7 [packed = true];
  repeated bytes string_val = 8;
  repeated float scomplex_val = 9 [packed = true];
  repeated int64 int64_val = 10 [packed = true];
  repeated bool bool_val = 11 [packed = true];
  repeated double dcomplex_val = 12 [packed = true];
  repeated ResourceHandle resource_handle_val = 14; //see resource_handle.proto
};

// TensorShape
message TensorShapeProto {
  message Dim {
    // One dimension of the tensor.
    int64 size = 1;
    string name = 2;
  };
  repeated Dim dim = 2;
  bool unknown_rank = 3;
};

// A node also contains function definition

message FunctionDefLibrary {
  repeated FunctionDef function = 1;
  repeated GradientDef gradient = 2;
}

message GradientDef {
  string function_name = 1;
  string gradient_func = 2;
}

message FunctionDef {
  OpDef signature = 1;
  map<string, AttrValue> attr = 5;
  repeated NodeDef node_def = 3;
  map<string, string> ret = 4;
}


// Defines an operation. A NodeDef in a GraphDef specifies an Op by
// using the "op" field which should match the name of a OpDef.
message OpDef {
  string name = 1;

  // For describing inputs and outputs.
  message ArgDef {
    string name = 1;
    string description = 2;
    DataType type = 3;
    string type_attr = 4;    // if specified, attr must have type "type"
    string number_attr = 5;  // if specified, attr must have type "int"
    string type_list_attr = 6;
    bool is_ref = 16;
  };

  repeated ArgDef input_arg = 2;
  repeated ArgDef output_arg = 3;
  // Argument
  message AttrDef {
    string name = 1;
    string type = 2;
    AttrValue default_value = 3;
    string description = 4;
    bool has_minimum = 5;
    int64 minimum = 6;
    AttrValue allowed_values = 7;
  }

  repeated AttrDef attr = 4;
  OpDeprecation deprecation = 8;
  string summary = 5;
  string description = 6;
  bool is_commutative = 18;
  bool is_aggregate = 16;
  bool is_stateful = 17;
  bool allows_uninitialized_input = 19;
};

// DataType

enum DataType {
  DT_INVALID = 0;
  DT_FLOAT = 1;
  DT_DOUBLE = 2;
  DT_INT32 = 3;
  DT_UINT8 = 4;
  DT_INT16 = 5;
  DT_INT8 = 6;
  DT_STRING = 7;
  DT_COMPLEX64 = 8;  // Single-precision complex
  DT_INT64 = 9;
  DT_BOOL = 10;
  DT_QINT8 = 11;     // Quantized int8
  DT_QUINT8 = 12;    // Quantized uint8
  DT_QINT32 = 13;    // Quantized int32
  DT_BFLOAT16 = 14;  // Float32 truncated to 16 bits.  Only for cast ops.
  DT_QINT16 = 15;    // Quantized int16
  DT_QUINT16 = 16;   // Quantized uint16
  DT_UINT16 = 17;
  DT_COMPLEX128 = 18;  // Double-precision complex
  DT_HALF = 19;
  DT_RESOURCE = 20;
  DT_FLOAT_REF = 101;
  DT_DOUBLE_REF = 102;
  DT_INT32_REF = 103;
  DT_UINT8_REF = 104;
  DT_INT16_REF = 105;
  DT_INT8_REF = 106;
  DT_STRING_REF = 107;
  DT_COMPLEX64_REF = 108;
  DT_INT64_REF = 109;
  DT_BOOL_REF = 110;
  DT_QINT8_REF = 111;
  DT_QUINT8_REF = 112;
  DT_QINT32_REF = 113;
  DT_BFLOAT16_REF = 114;
  DT_QINT16_REF = 115;
  DT_QUINT16_REF = 116;
  DT_UINT16_REF = 117;
  DT_COMPLEX128_REF = 118;
  DT_HALF_REF = 119;
  DT_RESOURCE_REF = 120;
}
