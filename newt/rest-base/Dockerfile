FROM ocaml/opam:alpine-3.6_ocaml-4.04.2_flambda
MAINTAINER John Smith

USER opam

RUN sudo apk update && \
    sudo apk add m4 unzip
RUN opam install -y lwt cohttp cohttp-lwt-unix jbuilder base64 bitstring

# automatic run depext

RUN mkdir /home/opam/service
WORKDIR /home/opam/service

COPY ocaml_template_rest.ml jbuild /home/opam/service/

ENV GIST d20a8dc0ebe66412989406b6bce39787
RUN wget https://gist.github.com/$GIST/download -O gist.zip \
    && unzip -o -j gist.zip -d . \
    && rm gist.zip

RUN eval `opam config env` && jbuilder build ocaml_template_rest.exe

ENV ENTRY_FILE "splus.ml" #user input
ENV ENTRY_FUNC "plus"     #user input
CMD ["./_build/default/ocaml_template_rest.exe"]

# docker build -t matrixanger/add_service .
# docker run --name plus_service -p 8888:8888 -d matrixanger/add_service
# curl '172.17.0.2:8888/predict?input1=1&input2=10'