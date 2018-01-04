FROM opam:ubuntu-14.04_ocaml-4.04.0
MAINTAINER John Smith

RUN apt-get update -y
RUN apt-get -y install wget unzip #user input
RUN opam install webmachine

WORKDIR /service

COPY . /service

ENV GIST d20a8dc0ebe66412989406b6bce39787 #user input
RUN wget https://gist.github.com/$GIST/download -O gist.zip \
    && unzip -o -j gist.zip -d . \
    && rm gist.zip

ENV ENTRY_FILE "splus.ml" #user input
ENV ENTRY_FUNC "plus"     #user input
CMD ["ocaml_template.ml", ENTRY_FILE, ENTRY_FUNC]