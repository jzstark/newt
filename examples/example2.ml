#!/usr/bin/env owl

open Owl
open Newt

let _ =
(* existing services *)
let serv_plus_one = Newt.Service.load_atom "s1.json" in
let test_output   = Newt.Service.run serv_plus_two (I 1) in

(* two DAG design *)
let dag1 = Newt.Composer.create_dag "{S: S -> S;}" in
let dag2 = Newt.Composer.create_dag "{S: S -> S -> S;}" in

(* play with new services *)
let serv_plus_two  = Newt.Composer.create_service [|serv_a|] dag1 in
let serv_plus_tree = Newt.Composer.create_service [|serv_a|] dag2 in

let foo = Newt.Service.run serv_plus_two   (I 1) in (* expected: 3 *)
let bar = Newt.Service.run serv_plus_three (I 1) in (* expected: 4 *)

(* happy with the latter one. Save it to gist *)
Newt.Deployer.deploy "plus_three" serv_plus_three

(* should be saved as a new configure file plus_three.json:

===
name: "plus_three"
version "0,1"

type: “compound”
serv:  {
  name: "PlusOne_1"
  gid: "d20a8dc0ebe66412989406b6bce39787"
  bottom: "PlusOne_2"
}

serv: {
  name: "PlusOne_2"
  gid: "d20a8dc0ebe66412989406b6bce39787"
  bottom: "PlusOne_2"
}
====

This, in turn, must be used by Newt.Service.load
*)
