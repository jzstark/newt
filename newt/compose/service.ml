let main p1 p2 =
  let r0 = Squeezenet.infer p1 p2 in
  let r1 = Squeezenet.to_json r0 in
  r1