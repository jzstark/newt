(* generate a entry file called mname.ml based on service *)
let generate_main ?(dir=".") service mname = 
  let header = ref "" in 
  Array.iter (fun gist ->
    header := !header ^ (Printf.sprintf "#zoo \"%s\"\n" gist)
  ) (get_gists service);

  let p_num = Array.length (get_types service) in
  let params = Array.make p_num "" in
  for i = 0 to (p_num - 1) do 
    params.(i) <- "p" ^ (string_of_int i)
  done;
  let p_str = combine params in

  let body = ref "" in
  let cnt  = ref 0 in
  let pcnt = ref 0 in
  let iterfun node = 
    let name, gist, pn = Owl_graph.attr node in
    let ps = 
      let p_str' = combine (Array.sub params !pcnt pn) in
      if !cnt = 0 then p_str'
      else "r" ^ (string_of_int !cnt) ^ p_str'
    in
    body := !body ^ Printf.sprintf "  let r%d = %s %s in\n" !cnt name ps;
    pcnt := !pcnt + pn; cnt := !cnt + 1
  in
  Owl_graph.iter_ancestors iterfun [|(get_graph service)|];
  body := !body ^ (Printf.sprintf "  r%d\n" (!cnt - 1));

  let output_string = "#/usr/bin/env owl\n" ^ !header ^
    (Printf.sprintf "let main%s =\n%s" p_str !body) in 

  let dir = if "." then Sys.getcwd () else dir in
  save_file output_string (dir ^ "/" ^ mname ^ ".ml")
