type service
type config

(* save a service to a new gist (json configuration file)*)
val deploy : service array -> dag -> string -> unit
