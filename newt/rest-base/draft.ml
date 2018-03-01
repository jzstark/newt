(* #require yojson *)

(* zoo_types.ml *)
type img = 
  | PPM of string
  | GEN of string

type text = 
  | CN of string
  | EN of string

type voice = 
  | EN of string
  | CN of string

(** tools for service developer *)
let string_of_img x = 
  match x with
  | PPM a -> a
  | GEN a -> a

let img_of_string x typ =
  match typ with
   | "ppm" -> PPM x
   | _     -> GEN x

let string_of_text x = 
  match x with
  | EN a -> a
  | CN a -> a

let text_of_string x typ = 
  match typ with
  | "EN" -> EN x
  | "CN" -> CN x

(** zoo_types.ml ends *)

type service = {
  mutable gists : string array;
  mutable types : string array;
  mutable graph : (string * string) Owl_graph.node; (* "M.f" * "gist" *)
}

let get_gists s = s.gists 
let get_types s = s.types
let get_graph s = s.graph

let in_types s = 
  let lst = Array.to_list (get_types s) in
  List.(lst |> rev |> tl |> rev) |> Array.of_list

let out_type s = 
  let lst = Array.to_list (get_types s) in
  List.(lst |> rev |> hd)

(** Helper function *)
let strip_string s =
  Str.global_replace (Str.regexp "[\r\n\t ]") "" s

let filter_str (x, y) = x, 
  Yojson.Basic.Util.to_string y
  |> Str.split (Str.regexp "->")
  |> List.map strip_string

let uniq lst =
  let unique_set = Hashtbl.create (List.length lst) in
  List.iter (fun x -> Hashtbl.replace unique_set x ()) lst;
  Hashtbl.fold (fun x () xs -> x :: xs) unique_set []

(* split([1;2;3;4;5],3) --> [1;2;3], [4;5]*)
let split list n =
  let rec aux i acc = function
    | [] -> List.rev acc, []
    | h :: t as l -> 
      if i = 0 then List.rev acc, l
      else aux (i-1) (h :: acc) t in
  aux n [] list

let merge_array a b = 
  Array.append a b |> Array.to_list
  |> uniq |> Array.of_list

let replace a b idx = 
  assert (idx < (Array.length b));
  let x, y = split (Array.to_list b) idx in 
  (x @ (Array.to_list a) @ y) |> Array.of_list

(** Core functions *)

let make_snode name gist types = 
  let gists = [|gist|] in 
  let graph = Owl_graph.node (name, gist) in 
  { gists; types; graph}

let make_services gist = 
  Owl_zoo_cmd.download_gist gist;
  let conf_json = Owl_zoo_cmd.load_file (gist ^ "/service.json") in
  let nt_lst = Yojson.Basic.from_string conf_json
    |> Yojson.Basic.Util.to_assoc
    |> List.map filter_str 
  in
  let services = Array.make (List.length nt_lst) 
    (make_snode "" "" [|""|]) in
  List.iteri (fun i (n, t) -> 
    services.(i) <- make_snode n gist (Array.of_list t)
  ) nt_lst;
  services

(* Arbitrary args seems difficult to implement...? *)
let execute service args = ()

let publish service name = ()
  (*
  - generate a "main.ml":
    let main p1 p2 p3 =
      let r0 = M1.f p1 p2 in
      let r1 = M2.f r0 p3 in
      r1
  - get gist files (ignore name collision)
  - generate Dockerfile & server file
  *)

(** compose operations *)

(* "->" raise error if two services are not compatible *)
let seq ?(name="") s1 s2 idx = 
  (* manual type check *)
  assert (Array.mem (out_type s1) (in_types s2));

  let gists = merge_array (get_gists s1) (get_gists s2) in
  let types = replace (get_types s1) (get_types s2) idx in
  let graph = get_graph s1 in
  let graph_cld = get_graph s2 in 
  Owl_graph.connect [|graph|] [|graph_cld|];
  {gists; types; graph}

(* example *)

let s1 = make_snode
  "Squeezenet.infer"
  "aa36ee2c93fad476f4a46dc195b6fd89"
  [|"img"; "ndarray"|]

let s2 = make_snode
  "Squeezenet.to_json"
  "aa36ee2c93fad476f4a46dc195b6fd89"
  [|"ndarray"; "text"|]