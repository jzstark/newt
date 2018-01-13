open Owl

let _read_ppm fname =
  (* grayscale binary ppm reading *)
  let fp = open_in fname in
  let ver = input_line fp in (* version *)

  if ver <> "P6" then (* expect a .ppm file *)
    raise (Invalid_argument ("Unable to read image: " ^ fname))
  else
    ();

  (* This will skip comments. *)
  let rec ignore_comments_then_get_w_h () =
    let maybe_comment = input_line fp in
    if maybe_comment.[0] = '#' then
      ignore_comments_then_get_w_h ()
    else
      (* This line has the width and height in it *)
      maybe_comment
  in

  (* width, height num colors *)
  let w_h_line = ignore_comments_then_get_w_h () in
  let num_col_line = input_line fp in
  let w, h = Scanf.sscanf w_h_line "%d %d" (fun w h -> w, h) in
  let num_col = Scanf.sscanf num_col_line "%d" (fun n -> n) in

  let img   = String.make (w * h * 3) ' ' in
  let imf_o = Array.make_matrix (w * 3) h 0.0 in

  (* Note that under 32bit OCaml, this will only work when reading strings up
     to ~16 megabytes. *)
  really_input fp img 0 (w * h * 3); (* end of file *)

  close_in fp;

  let ww = 3 * w  in
  for i = 0 to ww - 1 do
    for j = 0 to h - 1 do
      imf_o.(i).(j) <- float_of_int (int_of_char (img.[(h - 1 - j ) * ww + i ]));
    done
  done;

  imf_o, w, h, num_col
 
let read_ppm fname = 
  let img, w, h, num_col = _read_ppm fname in 
  let m = Dense.Matrix.S.of_arrays img in
  let m = Dense.Matrix.S.rotate m 270 in
  (* r,g, b: Mat of size h * w *)
  let r = Dense.Ndarray.S.get_slice_simple [[];[0;-1;3]] m in
  let g = Dense.Ndarray.S.get_slice_simple [[];[1;-1;3]] m in
  let b = Dense.Ndarray.S.get_slice_simple [[];[2;-1;3]] m in

  let r' = Dense.Ndarray.S.reshape r [|h;w;1|] in
  let g' = Dense.Ndarray.S.reshape g [|h;w;1|] in
  let b' = Dense.Ndarray.S.reshape b [|h;w;1|] in

  let img = Dense.Ndarray.S.zeros [|h;w;3|] in
  Dense.Ndarray.S.set_slice  [R []; R []; I 0] img r';
  Dense.Ndarray.S.set_slice  [R []; R []; I 1] img g';
  Dense.Ndarray.S.set_slice  [R []; R []; I 2] img b';
  img

let extend_dim img = 
  let shape = Dense.Ndarray.S.shape img in
  let shape = Array.append [|1|] shape in
  Dense.Ndarray.S.reshape img shape

let normalise img = 
  let img = Dense.Ndarray.S.div_scalar img 255. in 
  let img = Dense.Ndarray.S.sub_scalar img 0.5  in
  let img = Dense.Ndarray.S.mul_scalar img 2.   in
  img