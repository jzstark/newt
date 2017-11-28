(* Auto-generated from "service.atd" *)


type ioformat = Service_t.ioformat = {
  typ: string;
  shape: int list option;
  weight: string option
}

type func = Service_t.func = {
  name: string;
  input: ioformat;
  output: ioformat
}

type service = Service_t.service = {
  name: string;
  gist_id: string;
  version: string;
  services: func list
}

val write_ioformat :
  Bi_outbuf.t -> ioformat -> unit
  (** Output a JSON value of type {!ioformat}. *)

val string_of_ioformat :
  ?len:int -> ioformat -> string
  (** Serialize a value of type {!ioformat}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_ioformat :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> ioformat
  (** Input JSON data of type {!ioformat}. *)

val ioformat_of_string :
  string -> ioformat
  (** Deserialize JSON data of type {!ioformat}. *)

val write_func :
  Bi_outbuf.t -> func -> unit
  (** Output a JSON value of type {!func}. *)

val string_of_func :
  ?len:int -> func -> string
  (** Serialize a value of type {!func}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_func :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> func
  (** Input JSON data of type {!func}. *)

val func_of_string :
  string -> func
  (** Deserialize JSON data of type {!func}. *)

val write_service :
  Bi_outbuf.t -> service -> unit
  (** Output a JSON value of type {!service}. *)

val string_of_service :
  ?len:int -> service -> string
  (** Serialize a value of type {!service}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_service :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> service
  (** Input JSON data of type {!service}. *)

val service_of_string :
  string -> service
  (** Deserialize JSON data of type {!service}. *)

