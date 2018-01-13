open Owl

let preprocess img = 
  let r = Dense.Ndarray.S.get_slice_simple [[];[];[];[0]] img in 
  let r = Dense.Ndarray.S.sub_scalar r 123.68 in 
  Dense.Ndarray.S.set_slice_simple [[];[];[];[0]] img r;

  let g = Dense.Ndarray.S.get_slice_simple [[];[];[];[1]] img in 
  let g = Dense.Ndarray.S.sub_scalar g 116.779 in 
  Dense.Ndarray.S.set_slice_simple [[];[];[];[1]] img g;

  let b = Dense.Ndarray.S.get_slice_simple [[];[];[];[2]] img in 
  let b = Dense.Ndarray.S.sub_scalar b 103.939 in 
  Dense.Ndarray.S.set_slice_simple [[];[];[];[2]] img b;
  img