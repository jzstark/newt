(*
 * OWL - an OCaml numerical library for scientific computing
 * Copyright (c) 2016-2017 Liang Wang <liang.wang@cl.cam.ac.uk>
 *)


let dir = Sys.getenv "HOME" ^ "/.owl/zoo/"  
let log = dir ^ "/log.json"

let _parse_gist_string gist = 
  let gid = "12345abcde"  in
  let vid = "1" in 
  let vid = if not vid then find_latest_version gid in 
  gid, vid
    
let check_log gid vid =
  if Sys.file_exist log then Sys.create log;
  let jslog = Yojson log;
  Yojson.find jslog gid vid

let add_log gid vid = 
  if Sys.file_exist log then Sys.create log;
  let jslog = Yojson log;
  Yojson.add jslog gid vid

let rec _extract_zoo_gist f added = (* Most of this part goes to parser *)
  let s = Owl.Utils.read_file_string f in
  let regex = Str.regexp "^#zoo \"\\([0-9A-Za-z]+\\)\"" in
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
    Log.info "owl_zoo: %s cached" gist
  )
  else (
    make_log gid vid;
    Log.info "owl_zoo: %s missing" gist;
    Owl_zoo_cmd.download_gist gist (* download to correct subdirectory *)
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
  let gid, vid = _parse_gist_string gist in (* change the hashtbl structure *)
  if Hashtbl.mem added gid vid = false then (
    Hashtbl.add added gist gist ; (*?*)
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
