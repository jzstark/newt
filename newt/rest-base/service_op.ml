(*require service_def.ml *)

(** Consts *)
let conf_name = "service.json"
let zoo_root  = Sys.getenv "HOME" ^ "/.owl/zoo"

(** Helper function *)
let save_file file string =
  let channel = open_out file in
  output_string channel string;
  close_out channel

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
let split n lst =
  let rec aux i acc = function
    | [] -> List.rev acc, []
    | h :: t as l -> 
      if i = 0 then List.rev acc, l
      else aux (i-1) (h :: acc) t in
  aux n [] lst

let merge_array a b = 
  Array.append a b |> Array.to_list
  |> uniq |> Array.of_list

let rec remove_nth n = function
  | [] -> []
  | h :: t -> 
    if n = 0 then t 
    else h :: remove_nth (n-1) t

(* replace array a's idx-th elem with array b *)
let replace a b idx = 
  assert (idx >= 0 && idx < (Array.length b));
  let x, y = a |> Array.to_list |> remove_nth idx |> split idx in 
  (x @ (Array.to_list b) @ y) |> Array.of_list

let join ?(delim=" ") arr = 
  String.concat delim (Array.to_list arr)

(** compose operations *)

(* "->" raise error if two services are not compatible *)
let seq ?(name="") s1 s2 idx = 
  (* manual type check *)
  assert (Array.mem (out_type s1) (in_types s2)); (* incompatible service type *)
  assert (out_type s1 = (Array.get (in_types s2) idx)); (* incompatible argement type *)

  let gists = merge_array (get_gists s1) (get_gists s2) in
  let types = replace (get_types s2) (in_types s1) idx in
  let graph = get_graph s2 in
  let graph_cld = get_graph s1 in 
  Owl_graph.connect [|graph|] [|graph_cld|];
  {gists; types; graph}

(** Core functions *)

let make_snode name gist types = 
  let gists = [|gist|] in 
  let pn = Array.length types in
  let graph = Owl_graph.node (name, gist, pn) in 
  {gists; types; graph}

let make_services gist = 
  Owl_zoo_cmd.download_gist gist; (* should use cache if possible *)
  let conf_json = Owl_zoo_cmd.load_file (gist ^ "/" ^ conf_name) in
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

let list_nodes s = 
  let g = get_graph s in 
  let result = ref "" in
  let iterfun node = 
    let name, gist, pn = Owl_graph.attr node in
    result := !result ^ 
      Printf.sprintf "node: (%s, %s, %d)\n" name gist pn
  in 
  Owl_graph.iter_descendants iterfun [|g|];
  !result

let save_service service name =
  let tmp_dir = Filename.get_temp_dir_name () ^ "/" ^
    (string_of_int (Random.int 100000)) in
  Sys.command ("mkdir " ^ tmp_dir) |> ignore;

  generate_main ~dir:tmp_dir service name;
  generate_conf ~dir:tmp_dir service name;
  save_file (tmp_dir ^ "/readme.md") name; 
  let gist = Owl_zoo_cmd.upload_gist tmp_dir in
  gist

let build_docker ?(tag="latest") uname cname = 
  let container = Printf.sprintf "%s/%s:%s" uname cname tag in
  let cmd = Printf.sprintf "docker build -t %s . && docker push %s" 
    container container in
  Sys.command cmd |> ignore

(* service discovery *)
let log_info mname gist = ()

let publish_g gist mname uname cname = 
  Owl_zoo_cmd.download_gist gist;
  generate_jbuild ();
  generate_server (zoo_root ^ "/" ^ gist ^ "/" ^ conf_name);
  generate_dockerfile gist;
  build_docker uname cname;
  log_info mname gist 

let publish_s service mname uname cname =  
  let gist = save_service service mname in
  publish_g gist mname uname cname
