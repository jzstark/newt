open Owl
open Owl_types
open Neural 
open Neural.S

(*
#zoo "e7d8b1f6fbe1d12bb4a769d8736454b9" (* LoadImage   *)
#zoo "41380a6baa6c5a37931cd375d494eb57" (* SqueezeNet  *)
#zoo "51eaf74c65fa14c8c466ecfab2351bbd" (* Imagenet_cls*)
#zoo "86a1748bbc898f2e42538839edba00e1" (* ImageUtils  *)
*)

let gist_id = "c424e1d1454d58cfb9b0284ba1925a48"

let infer img_name = 
  let nn = Graph.load "sqnet_owl.network" in 
  let prefix  = Filename.remove_extension img_name in
  (* use cache if possible *)
  let tmp_img = Filename.temp_file prefix ".ppm" in 
  let _ = Sys.command ("convert -resize 227x227\\! " ^ img_name ^ " " ^ tmp_img) in
  let img_ppm = LoadImage.(read_ppm tmp_img |> extend_dim)
    |> ImageUtils.preprocess
  in
  Graph.model nn img_ppm

let infer_tuples ?(top=5) img_name = 
  infer img_name |> Imagenet_cls.to_tuples ~top

let infer_json ?(top=5) img_name = 
  infer img_name |> Imagenet_cls.to_json ~top

(*
let _ =
  let example = Sys.argv.(1) in (*"panda_sq.ppm" in *)
  let result = infer_json example in
  print_endline result
*)

let _ = ()

(* jbuilder build sqnet_example.bc *)
(* _build/default/sqnet_example.bc "panda_sq.ppm" *)