(* Part zero: run current zoo function as a standalone project: newt, 
    to avoid possible collision. *)


(* Part one: a client side script *)

#!/usr/bin/env owl

open Owl 
open Owl_zoo 
open Newt

(* #zoo "1232321323" (*LoadImage module *)  (*?*) *)

let module1 = "0123456789" (* image classification service *)
let module2 = "9876543210" (* google servicew *)
let module3 = "1232321323" (* helper function: load image *)

let service_LoadImage = Newt.load module3
let service_A = Newt.load ~location:"local" module1
let service_B = Newt.load ~location:"local" module2
let service_C = service_A.model -> service_B.recommend (* the right way? *)

(* let img = LoadImage.read_ppm "panda.ppm" *)
let img = Newt.run service_LoadImage.read_ppm (*doesn't look quite clean *)

let classfication = Newt.run service_A img (* assume only one input/output for each service *)
let recom = Newt.run service_C img

(* Part two: spec of each service *)
(* Inception_mata.json *)
{
    "name": "incpetionv3",
    "version": "1.0",
    "help": "InceptoinV3 network module"
    "services": [
        {
            "name" :  "model",
            "input":  {"type": Dense.Ndarray.S.Arr, "format": s.IMAGE, "shape": [|299;299;3|]}, (*batch dim? *)
            "output": {"type": Dense.Ndarray.S.Arr, "format": s.VOID,  "shape": [|1;1000|]},
            "weight": "https://drive.google.com/somewhere/inception_owl.network"
        },

        {
            "name": "decode",
            "input":  {"type": Dense.Ndarray.S.Arr, "format": s.VOID, "shape": [|1;1000|]},
            "output": {"type": (string * float) array }
        }   
    ]
}

(* recommendation_meta.json *)
{
    "name": "google_search_recommendation",
    "version": "0.1",
    "help": "simple wrapper for recommender service using google"
    "services": [
        {
            "name": "recommend",
            "input": {"type":string}
            "output": {"type": (int * string) array }
        }
    ]
}

(* load_image.json *)
{
    "name": "loadimage",
    "version": "1.2",
    "help": "read/output ppm image to/from Owl",
    "services": [
        {
            "name": "read_ppm",
            "input":  {"type": string },
            "output": {"type": Dense.Ndarray.S.Arr, "format": s.VOID, "shape":[|*;*;3|]}
        },

        {
            "name": "save_ppm",
            "input": {"type": Dense.Ndarray.S.Arr, "format": s.VOID, "shape":[|*;*;3|]},
            "output": {"type": unit }
        }
    ]
}

(* Part three: generate OCaml code from json with atdgen *)

(* Part four:  Image Module*)