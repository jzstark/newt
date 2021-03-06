type img =
  | PPM of string
  | GEN of string

type text =
  | CNT of string
  | ENT of string

type voice =
  | ENV of string
  | CNV of string

(** tools for service developer *)
let string_of_img x =
  match x with
  | PPM a -> a
  | GEN a -> a

let img_of_string x typ =
  match typ with
   | "ppm" -> PPM x
   | _     -> GEN x

let string_of_text x =
  match x with
  | ENT a -> a
  | CNT a -> a

let text_of_string typ x =
  match typ with
  | "EN" -> ENT x
  | "CN" -> CNT x
  | _    -> failwith "unsupported text type"
