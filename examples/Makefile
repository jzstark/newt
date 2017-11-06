all:
	atdgen -t service.atd;
	atdgen -j service.atd;
	ocamlfind ocamlc -c service_t.mli -package atdgen;
	ocamlfind ocamlc -c service_j.mli -package atdgen;
	ocamlfind ocamlopt -c service_t.ml -package atdgen;
	ocamlfind ocamlopt -c service_j.ml -package atdgen

