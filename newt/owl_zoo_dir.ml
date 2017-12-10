(*
 * OWL - an OCaml numerical library for scientific computing
 * Copyright (c) 2016-2017 Liang Wang <liang.wang@cl.cam.ac.uk>
 *)

open Yojson

let dir = Sys.getenv "HOME" ^ "/.owl/zoo/"
let log = dir ^ "log.json"

let _create_log () =
  (* Ignore existing files from previous Zoo version *)
  let empty_list = `List [`Null] in
  Yojson.to_file log empty_list

and _find_latest_vid gid =
  if not (Sys.file_exists log) then _create_log ();
  let jslog = Yojson.Basic.from_file log in
  let versions = Yojson.Basic.Util.(filter_member gid [jslog]
    |> filter_member "latest" |> filter_string)
  in
  match versions with
  | []   -> ""
  | h::_ -> h

and _check_log gid vid =
  if not (Sys.file_exists log) then _create_log ();
  let jslog = Yojson.Basic.from_file log in
  let versions = Yojson.Basic.Util.(filter_member gid [jslog]
    |> filter_member "versions" |> filter_list) in
  match versions with
  | h::t -> List.mem (`String vid) h
  | []   -> false

and _update_log ?(latest=false) gid vid =
  if (_check_log gid vid = false) then (
    let jslog = Yojson.Basic.from_file log in
    let jslog' = Yojson.Basic.Util.to_assoc jslog in
    let new_item = (gid, `Assoc [("versions", `List [`String vid]);
      ("latest",  `String vid)]) in
    let updated = List.append jslog' [new_item] in
    Yojson.Basic.to_file log (`Assoc updated)
  ) else (
    let jslog = Yojson.Basic.from_file log in
    let jslog' = Yojson.Basic.Util.to_assoc jslog in
    let update record =
      let key, assoc = record in
      if not (gid = key) then record else
      let ver = Yojson.Basic.Util.to_assoc assoc in
      let _, versions = List.hd  ver in
      let _, tag      = List.nth ver 1 in
      let tag = if latest then (`String vid) else tag in
      let versions = Yojson.Basic.Util.to_list versions in
      let new_versions =
        if (List.mem (`String vid) versions) then versions
        else List.append versions [`String vid]
      in
      key, (`Assoc [("versions", `List new_versions); ("latest", tag)])
    in
    let updated = List.map update jslog' in
    Yojson.Basic.to_file log (`Assoc updated)
  )

and _parse_gist_string gist =
  let strip_string s =
    Str.global_replace (Str.regexp "[\r\n\t ]") "" s
  in
  let regex = Str.regexp "|" in
  let lst = Str.split_delim regex gist in
  let lst = List.map strip_string lst in
  let vid = List.nth lst 1 in
  List.hd lst,
  if (vid = "") then _find_latest_vid gid else vid

and rec _extract_zoo_gist f added =
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
  if (_check_log gid vid) = true then (
    Log.info "owl_zoo: %s | %s cached" gid vid
  )
  else (
    _update_log gid vid;
    Log.info "owl_zoo: %s | %s missing" gid vid;
    Owl_zoo_cmd.download_gist gid vid
  )

and _dir_zoo_ocaml gid vid added = (* final step: load *)
  let dir_gist = dir ^ gid ^ "/" ^ vid in
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
  let gid, vid = _parse_gist_string gist in
  if (Hashtbl.mem added gid = false) then (
    Hashtbl.add added gid []
  );
  let vids = Hashtbl.find added gid in
  if not (List.mem vid vids) then (
    let new_vids = List.append vids [vid] in
    Hashtbl.add added gid new_vids;
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
