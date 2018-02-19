#! /bin/bash

if [ $# -ne 1 ]
then
    echo "Usage: generate Dockerfile based on gist id"
    exit 1
fi

GID=$1

cat > Dockerfile << EOF
FROM ryanrhymes/owl
MAINTAINER John Smith

RUN opam install -y lwt cohttp cohttp-lwt-unix yojson jbuilder

RUN apt-get update -y \\
    && apt-get -y install wget imagemagick

RUN mkdir /service
WORKDIR /service

COPY generate_server.ml jbuild /service/

ENV GIST $1
RUN owl -run \$GIST \\
    && find ~/.owl/zoo -iname '*' -exec cp \{\} . \; \\
    && find . -name "*.ml" -exec sed -i '/^#/d' \{\} \; 

RUN ocamlfind ocamlopt -o generate_server \\
    -linkpkg -package yojson generate_server.ml \\
    && rm generate_server.cm* generate_server.o \\
    && ./generate_server

RUN eval \`opam config env\` && jbuilder build server.bc

ENTRYPOINT ["./_build/default/server.bc"]
EOF