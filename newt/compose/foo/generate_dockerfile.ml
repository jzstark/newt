let save_file file string =
  let channel = open_out file in
  output_string channel string;
  close_out channel

let _ = 

if ( Array.length Sys.argv < 2) then 
  (failwith "Usage: generate Dockerfile based on gist id");

let gid = Sys.argv.(1) in

let output_str = "
FROM ryanrhymes/owl
MAINTAINER John Smith

RUN opam install -y lwt cohttp cohttp-lwt-unix yojson jbuilder

RUN apt-get update -y \\
    && apt-get -y install wget imagemagick

RUN mkdir /service
WORKDIR /service

COPY generate_server.ml jbuild /service/

ENV GIST $1
RUN owl -run " ^ gid ^ "\\
    && find ~/.owl/zoo -iname '*' -exec cp \\{\\} . \\; \\
    && find . -name \"*.ml\" -exec sed -i '/^#/d' \\{\\} \\;

RUN ocamlfind ocamlopt -o generate_server \\
    -linkpkg -package yojson,str generate_server.ml \\
    && rm generate_server.cm* generate_server.o \\
    && ./generate_server

RUN eval `opam config env` && jbuilder build server.bc

ENTRYPOINT [\"./_build/default/server.bc\"]
"
in

save_file "Dockerfile" output_string