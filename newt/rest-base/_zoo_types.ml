type img = 
  | PPM of string
  | GEN of string

type text = 
  | CN of string
  | EN of string

type voice = 
  | EN of string
  | CN of string

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
  | EN a -> a
  | CN a -> a

let text_of_string x typ = 
  match typ with
  | "EN" -> EN x
  | "CN" -> CN x
