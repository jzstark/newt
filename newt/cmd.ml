(*
 * Toploop.mod_use_file Format.std_formatter "redis_db.ml";;
 * Toploop.mod_use_file Format.std_formatter "query_processor.ml";;
 *)

(* 1: management_frontend.ml *)
(* Owl_zoo_deployer.deploy_service "plus_service" "localhost" gistid *)
(* zoo.conf: entryfile, entry function, input types, output type*)

let conf = Docker_manager.get_configuration gistid;;
Docker_manager.generate_files conf;;
Docker_manager.sendfiles 
    "localhost" 
    ["Dockerfile", "ocaml_template_rest.ml", "jbuild"] 
    "/zoo/service/plus_service";;
Docker_manager.build_image "localhost" "/zoo/service/plus_service"

let in_typs = "int";; (* Hashtbl.find conf "input_type" *)
let port = 8888;; 
let redis_conn = Redis_db.connect "localhost" port;;
Redis_db.add_container redis_conn "plus_service" "localhost" "8888" in_typs;;

(* 2: query_frontend.ml *)
(* Owl_zoo_deployer.make_endpoint "plus" input_type *)

let server = Http_server.create_server "localhost" 8765;;
server#add_application redis_conn "plus" in_typs;;

(* 3: query_frontend.ml *)
(* Owl_zoo_deployer.link "epName" "servName" *)
Redis_db.set_endpoint_link redis_conn "plus" "plus_service"

(* 4 *)
(* curl '127.0.0.1:8765/predict/plus?input=12' *)