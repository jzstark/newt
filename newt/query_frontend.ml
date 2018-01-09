open Redis_db
open Http_server
open Query_processor

let read_conf conf_file_name = None
let http_respond data = None
let linked_model_for_apps () = None
let jsonify data = None

let request_handler host_ip host_port = 
  let conf = read_conf "zoo.conf" in 
  let server = Http_server.create_server(host_ip, host_port) in
  let redis_conn = Redis_db.connect (Hashtbl.find conf "redis_addr") 
    (Hashtbl.find conf "redis_port") in
  let redis_subs = rd.connect_subscriber (Hashtbl.find conf "redis_addr") 
    (Hashtbl.find conf "redis_port") in

  Http_server.add_endpoint server "^/metrics$" "GET" (fun req -> http_respond req);

  let call_back_model_link key event_type = 
    assert (event_type = "sadd");
    let linked_model_names = Redis_db.get_linked_models redis_conn key in 
    Http_server.set_linked_models_for_app server key set_linked_models_for_app
    ()

  let call_back_app key event_type = 
    assert (event_type = "hset");
    let info = Redis_db.get_application_by_key redis_conn key in 
    let input_type = Hashtbl.find conf "input_type" in
    Http_server.add_endpoint server key input_type
    ()

  Redis_db.subscribe_to_application_changes redis_subs call_back_app;
  Redis_db.subscribe_to_model_link_changes  redis_subs call_back_model_link;

let get_linked_models_for_app key = 
  Hashtbl.find linked_model_for_apps key

let decode_and_handle_predict json name model_keys input_type = 
  let redis_conn = Redis_db.connect (Hashtbl.find conf "redis_addr") 
    (Hashtbl.find conf "redis_port") in
  let inp = parse_json json input_type in
  let pred = Query_processor.predict redis_conn name model_keys inp "REST" in
  pred

let add_application rd_conn key input_type = 
  let predict_fn name input_type req = 
    let models = get_linked_models_for_app name in 
    let pred = decode_and_handle_predict rd_conn req name input_type in
    jsonify pred
  in 
  let server = Http_server.create_server(host_ip, host_port) in
  Http_server.add_endpoint server ("^/" ^ key ^ "/predict$") "POST" predict_fn