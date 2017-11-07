let s1 = {
  "PlusOne";
  "12345";
  "0.0.1";
  [{
    "main";
    "int";
    "int";
    fun x -> (unpack_int x) + 1;
  }]
}

let s2 = {
  "Square";
  "123456";
  "0.0.1";
  [{
    "main";
    "int";
    "int";
    fun x -> (unpack_int x) * (unpack_int x);
  }]
}

let s3 = connect s1.main s2.main
