open Redis_sync.Client

(* Two *)
let model_db_num    = 1
let endpoint_db_num = 2
let link_db_num     = 3

(* 
 * Container information 
 *)

let connect host port = 
  Redis_sync.Client.connect {host=host; port=port}

(* TODO: what will a proper key? a proper one is gistid+vid*)
let add_container db_conn name host port input_type = 
  select db_conn model_db_num;

  let mappings = [
    ("host", host); ("port", port);
    ("container_name", name);
    ("input_type", input_type);
  ] in 
  hmset db_conn name mappings

let del_container db_conn key = 
  select db_conn model_db_num;
  del db_conn [key]

let get_container db_conn key = 
  select db_conn model_db_num;
  hgetall db_conn key

let get_all_containers db_conn = 
  select db_conn model_db_num;
  keys db_conn "*"


(* 
 * Endpoints information 
 *)

let add_endpoint db_conn host port name input_type = 
  select db_conn endpoint_db_num; 

  let mappings = [
    ("host", host); ("port", port);
    ("input_type", input_type);
  ] in 
  hmset db_conn name mappings

let del_endpoints db_conn key = 
  select db_conn endpoint_db_num;
  del db_conn [key]

let get_endpoints db_conn key = 
  select db_conn endpoint_db_num;
  hgetall db_conn key

let get_all_endpoints db_conn = 
  select db_conn endpoint_db_num;
  keys db_conn "*"

(* 
 * Link container and information 
 *)

(* possible expansion: *)
let set_endpoint_link db_conn ep_name container_key = 
  select db_conn link_db_num;
  sadd db_conn ep_name container_key

let get_linked_container db_conn ep_name = 
  select db_conn link_db_num;
  smembers db_conn ep_name

(* 
 * Subscribe to changes
 *)

let subscribe_to_key_changes db_conn db_num subscriber callback = 
  let pattern = "__keyspace@" ^ (string_of_int db_num) ^ "__:*" in
  let fn topic msg = 
    let splits = Str.split (Str.regexp ":") topic |> Array.of_list in 
    let key = splits.(1) in 
    callback key msg
  in
  psubscribe db_conn [pattern] (* subscribe to a function rather than string *)

let subscribe_to_container_changes db_conn =
  subscribe_to_key_changes db_conn model_db_num

let subscribe_to_endpoint_changes db_conn =
  subscribe_to_key_changes db_conn endpoint_db_num

let subscribe_to_link_changes db_conn =
  subscribe_to_key_changes db_conn link_db_num