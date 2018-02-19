FROM ryanrhymes/owl
MAINTAINER John Smith

RUN opam install -y lwt cohttp cohttp-lwt-unix yojson jbuilder

RUN apt-get update -y \
    && apt-get -y install wget imagemagick

RUN mkdir /service
WORKDIR /service

COPY generate_server.ml jbuild /service/

ENV GIST c424e1d1454d58cfb9b0284ba1925a48
RUN owl -run $GIST \
    && find ~/.owl/zoo -iname '*' -exec cp \{\} . \; \
    && find . -name "*.ml" -exec sed -i '/^#/d' \{\} \; 

RUN ocamlfind ocamlopt -o generate_server \
    -linkpkg -package yojson generate_server.ml \
    && rm generate_server.cm* generate_server.o \
    && ./generate_server

RUN eval `opam config env` && jbuilder build server.bc

ENTRYPOINT ["./_build/default/server.bc"]
