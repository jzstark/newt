(* Auto-generated from "service.atd" *)


type ioformat = {
  typ: string;
  shape: int list option;
  weight: string option
}

type func = { name: string; input: ioformat; output: ioformat }

type service = {
  name: string;
  gist_id: string;
  version: string;
  services: func list
}
