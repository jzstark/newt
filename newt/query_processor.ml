let syscall cmd =
  let ic, oc = Unix.open_process cmd in
  let buf = Buffer.create 16 in
  (try
     while true do
       Buffer.add_channel buf ic 1
     done
   with End_of_file -> ());
  let _ = Unix.close_process (ic, oc) in
  (Buffer.contents buf)
;;

let predict containerName input t = 
  let output = syscall ("curl -s '127.0.0.1:8888/predict?input1=" ^ input ^ "&input2=1'") in
  output