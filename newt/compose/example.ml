
(* example *)

let s1 = make_snode
  "Squeezenet.infer"
  "aa36ee2c93fad476f4a46dc195b6fd89"
  [|"img"; "ndarray"|]

let s2 = make_snode
  "Squeezenet.to_json"
  "aa36ee2c93fad476f4a46dc195b6fd89"
  [|"ndarray"; "text"|]
