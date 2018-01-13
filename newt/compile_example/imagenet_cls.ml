open Owl

let gist_id = "51eaf74c65fa14c8c466ecfab2351bbd"

(* input: 1x1000 ndarray; output: top-N inference result list, 
    each element in the form of [class: string; propability: float] *)
let to_tuples ?(top=5) preds = 
  let dict_path = Sys.getenv "HOME" ^ "/.owl/zoo/" ^ gist_id ^ "/imagenet1000.dict" in 
  let h = Owl_utils.marshal_from_file dict_path in 
  let tp = Dense.Matrix.S.top preds top in 

  let results = Array.make top ("type", 0.) in 
  Array.iteri (fun i x -> 
    let cls  = Hashtbl.find h x.(1) in 
    let prop = Dense.Ndarray.S.get preds [|x.(0); x.(1)|] in 
    Array.set results i (cls, prop);
  ) tp;
  results

(* input: 1x1000 ndarray; output: top-N inference result as a json string *)
let to_json ?(top=5) preds = 
  let dict_path = Sys.getenv "HOME" ^ "/.owl/zoo/" ^ gist_id ^ "/imagenet1000.dict" in 
  let h = Owl_utils.marshal_from_file dict_path in
  let tp = Dense.Matrix.S.top preds top in

  let assos = Array.make top "" in 
  Array.iteri (fun i x -> 
    let cls  = Hashtbl.find h x.(1) in 
    let prop = Dense.Matrix.S.get preds x.(0) x.(1) in 
    let p = "{\"class\":\"" ^ cls ^ "\", \"prop\": " ^ (string_of_float prop) ^ "}," in 
    Array.set assos i p 
  ) tp;

  let str  = Array.fold_left (^) "" assos in 
  let str  = String.sub str 0 ((String.length str) - 1) in
  let json = "[" ^ str ^ " ]" in 
  json