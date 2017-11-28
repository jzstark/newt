type t
type service
type dag

(* syntax for creating DAG *)
val make_dag : unit -> dag

(* create new service based on existing services and DAG *)
val create   : service array -> dag -> service
