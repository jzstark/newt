FROM ryanrhymes/owl
MAINTAINER John Smith

RUN apt-get update -y \
    && apt-get -y install wget imagemagick

RUN opam install -y lwt cohttp cohttp-lwt-unix jbuilder

# automatic run depext

RUN mkdir /service
WORKDIR /service

COPY ocaml_template_rest.ml jbuild /service/

ENV GIST db4d6ec23d14cbe008756b2c006c33b7
RUN wget https://gist.github.com/$GIST/download -O gist.zip \
    && unzip -o -j gist.zip -d . \
    && rm gist.zip

ENV ENTRY_FILE "sqnet_example.ml" #user input
ENV ENTRY_FUNC "infer_json"       #user input

RUN eval `opam config env` && jbuilder build ocaml_template_rest.bc

CMD ["./_build/default/ocaml_template_rest.bc"]

# docker build -t matrixanger/add_service .
# docker run --name plus_service -p 8888:8888 -d matrixanger/add_service
# curl '172.17.0.2:8888/predict?input1=1&input2=10'
