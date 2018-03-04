let ss = make_services "aa36ee2c93fad476f4a46dc195b6fd89";;
let s1 = ss.(0);;
let s2 = ss.(1);;
let s3 = seq s1 s2 0;;
publish_service s3 "whatever";;
