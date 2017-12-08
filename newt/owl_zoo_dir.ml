(*
 * OWL - an OCaml numerical library for scientific computing
 * Copyright (c) 2016-2017 Liang Wang <liang.wang@cl.cam.ac.uk>
 *)

open Yojson

let dir = Sys.getenv "HOME" ^ "/.owl/zoo/"
let log = dir ^ "/log.json"

let _parse_gist_string gist =
  let strip_string s =
    Str.global_replace (Str.regexp "[\r\n\t ]") "" s
  in
  let regex = Str.regexp "|" in
  let lst = Str.split_delim regex gist in
  List.map strip_string lst;
  lst.(0), (* gid *)
  if (List.length = 1) then find_latest_vid lst.(0) else lst.(1) (* vid *)

let find_latest_vid gid =
  let jslog = Yojson.Basic.from_file log in
  Yojson.Basic.Util.(filter_member gid [jslog]
    |> filter_member "latest" |> filter_string)
    |> List.hd (* latest version id *)

let create_log () =
  let empty_list = `List [`Null] in
  Yojson.to_file log empty_list

let check_log gid vid =
  if Sys.file_exists log then create_log ();
  let jslog = Yojson.Basic.from_file log in
  let versions = Yojson.Basic.Util.(filter_member gid [jslog]
    |> filter_member "versions" |> filter_list)
    |> List.hd  in
  List.mem vid versions

let update_log ?(update=false) gid vid = (* consider update *)
  if Sys.file_exists log then create_log ();
  let jslog = Yojson.Basic.from_file log in
  let jslog' = Yojson.Basic.Util.to_assoc jslog in
  let _new_version record =
    let key, assoc = record in
    if not (gid = key) then record else
    let ver = Yojson.Basic.Util.to_assoc assoc in
    let _, versions = List.hd  ver in
    let _, tag      = List.nth ver 1 in
    let tag = if update then (`String vid) else tag in
    let versions = Yojson.Basic.Util.to_list versions in
    if List.mem (`String vid) versions then record else
    let new_versions = List.append versions [`String vid] in
    key, (`Assoc [("versions", `List new_versions); ("latest", tag)])
  in
  let updated = List.map _new_version jslog' in
  Yojson.Basic.to_file log (`Assoc updated)

let rec _extract_zoo_gist f added =
  let s = Owl.Utils.read_file_string f in
  let regex = Str.regexp "^#zoo \"\\([0-9A-Za-z]|+\\)\"" in
  try
    let pos = ref 0 in
    while true do
      pos := Str.search_forward regex s !pos;
      let gist = Str.matched_group 1 s in
      pos := !pos + (String.length gist);
      process_dir_zoo ~added gist
    done
  with Not_found -> ()


and _deploy_gist gid vid =
  if (check_log gid vid) = true then (
    Log.info "owl_zoo: %s | %s cached" gid vid
  )
  else (
    make_log gid vid;
    Log.info "owl_zoo: %s | %s missing" gid vid;
    Owl_zoo_cmd.download_gist git vid (* download to correct subdirectory *)
  )

and _dir_zoo_ocaml gid vid added = (* final step: load *)
  let dir_gist = dir ^ gist ^ "/" ^ vid in
  Sys.readdir (dir_gist)
  |> Array.to_list
  |> List.filter (fun s -> Filename.check_suffix s "ml")
  |> List.iter (fun l ->
          let f = Printf.sprintf "%s/%s" dir_gist l in
      _extract_zoo_gist f added;
      Toploop.mod_use_file Format.std_formatter f
      |> ignore
    )

and process_dir_zoo ?added gist =
  let added = match added with
    | Some h -> h
    | None   -> Hashtbl.create 128
  in
  if Hashtbl.mem added gid vid = false then ( (*keep structure for now *)
    let gid, vid = _parse_gist_string gist in
    Hashtbl.add added gist gist;
    _deploy_gist gid vid;
    _dir_zoo_ocaml gid vid added
  )

and add_dir_zoo () =
  let section = "owl" in
  let doc =
    "owl's zoo system\n" ^
    "ditribute code snippet via gist\n"
  in
  let info = Toploop.({ section; doc }) in
  let dir_fun = Toploop.Directive_string process_dir_zoo in
  Toploop.add_directive "zoo" dir_fun info
