(*
   =====================================================================
   PPL Memory Bug Reproduction Suite — by Mikael Dahlsen-Jensen
   =====================================================================

   This OCaml program reproduces several memory management issues observed
   when using the Parma Polyhedra Library (PPL) through its OCaml bindings.

   The issues manifest as either:
     - immediate segmentation faults
     - "Out_of_memory" OCaml exceptions

   The failures are triggered by using:
     - ppl_Pointset_Powerset_NNC_Polyhedron_get_disjunct
     - ppl_new_NNC_Polyhedron_from_NNC_Polyhedron
     - ppl_new_Pointset_Powerset_NNC_Polyhedron_from_Pointset_Powerset_NNC_Polyhedron
     - ppl_Pointset_Powerset_NNC_Polyhedron_add_disjunct
     - iterator begin/end APIs

   Observed results:
     - Iterator.test_with_copy -> fails after ~3k iterations
     - Iterator.test_without_copy -> seems stable 
     - Original.test_with_copy -> fails after ~3k iterations
     - Original.test_with_leaking_disjunct -> fails around ~130k iterations
     - Original.test_without_copy -> survives up to ~18M iterations before crash
     - Copy.test -> seems stable
*)

let iterations = 1_000_000_000
let progress_interval = 1000        

let base_poly () = 
  let open Ppl_ocaml in
  let var = Variable 0 in
  let rhs = Coefficient (Gmp.Z.of_int 0) in
  let ineq = Greater_Or_Equal (var, rhs) in
  let p = ppl_new_NNC_Polyhedron_from_space_dimension 1 Universe in
  ppl_Polyhedron_add_constraints p [ineq];
  p 

let base_ps_poly () =
  Ppl_ocaml.ppl_new_Pointset_Powerset_NNC_Polyhedron_from_NNC_Polyhedron @@ base_poly ()


module Iterator = struct 
  (* These tests use the iterator to extract disjuncts (only one in this case)
     and then use the result for something.
     One test uses the disjunct directly, the other copies it first. *)

  let test_without_copy  () =
    let open Ppl_ocaml in 
    let i = ref 0 in
    while !i < iterations do
      let ps = base_ps_poly() in
      let ps2 = base_ps_poly () in 

      let it = ppl_Pointset_Powerset_NNC_Polyhedron_begin_iterator ps in
      let it_end = ppl_Pointset_Powerset_NNC_Polyhedron_end_iterator ps in

      if ppl_Pointset_Powerset_NNC_Polyhedron_iterator_equals_iterator it it_end then (
        Printf.printf "Empty powerset, aborting\n%!";
        exit 1
      );
      if (!i mod progress_interval) = 0 then
        Printf.printf "Iteration %d / %d\n%!" !i iterations;

      let d_raw = ppl_Pointset_Powerset_NNC_Polyhedron_get_disjunct it in
    
      ignore (Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_add_disjunct ps2 d_raw);
      ignore (Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_add_disjunct ps2 d_raw);
  
      ppl_Pointset_Powerset_NNC_Polyhedron_increment_iterator it;
      incr i
    done;
    
    Printf.printf "Completed %d iterations without crash.\n%!" iterations

  (* This fails very quickly with either a segfault or Out_of_memory *)
  let test_with_copy () = 
    let open Ppl_ocaml in 
    let i = ref 0 in
    while !i < iterations do
      let ps = base_ps_poly() in
      let ps2 = base_ps_poly () in 

      let it = ppl_Pointset_Powerset_NNC_Polyhedron_begin_iterator ps in
      let it_end = ppl_Pointset_Powerset_NNC_Polyhedron_end_iterator ps in

      if ppl_Pointset_Powerset_NNC_Polyhedron_iterator_equals_iterator it it_end then (
        Printf.printf "Empty powerset, aborting\n%!";
        exit 1
      );
      if (!i mod progress_interval) = 0 then
        Printf.printf "Iteration %d / %d\n%!" !i iterations;

      let d_raw = ppl_Pointset_Powerset_NNC_Polyhedron_get_disjunct it in
      let d_copy = ppl_new_NNC_Polyhedron_from_NNC_Polyhedron d_raw in 
    
      ignore (Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_add_disjunct ps2 d_copy);
  
      ppl_Pointset_Powerset_NNC_Polyhedron_increment_iterator it;
      incr i
    done;
    
    Printf.printf "Completed %d iterations without crash.\n%!" iterations
end

module Copy = struct 
  (* Tests the copy function (new [PS] NNC from existing [PS] NNC) *)
  (* This test does NOT cause issues, even though it uses the same copy function
     that appears to break other tests. *)
  let test () = 
    let open Ppl_ocaml in 
    let i = ref 0 in 
    while !i < iterations do 
      if (!i mod progress_interval) = 0 then 
        Printf.printf "Iteration %d / %d\n%!" !i iterations; 
      begin 
        try
          let p1 = base_poly () in 
          let p2 =  base_ps_poly () in 
          
          ignore @@ ppl_new_NNC_Polyhedron_from_NNC_Polyhedron p1;
          ignore @@ ppl_new_Pointset_Powerset_NNC_Polyhedron_from_Pointset_Powerset_NNC_Polyhedron p2
        with 
          | Out_of_memory -> 
            Printf.printf "Out of memory at iteration %d\n%!" !i; 
            exit 1 
          | e -> 
            Printf.printf "Exception at iteration %d: %s\n%!" !i (Printexc.to_string e); 
      end; 
        incr i 
    done; 
    Printf.printf "Finished %d iterations — exiting.\n%!" iterations
end

module Original = struct
  (* The base tests derived from IMITATOR's code paths (union of NNC constraints). *)

  let combine_without_copy c1 c2 = 
    let disjuncts = ref [] in
    let iterator = Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_begin_iterator c2 in
    let end_iterator = Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_end_iterator c2 in
    while not (Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_iterator_equals_iterator iterator end_iterator) do
      let disjunct = Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_get_disjunct iterator in
      disjuncts := disjunct :: !disjuncts;
      Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_increment_iterator iterator;
    done;
    let result = !disjuncts in
    List.iter (Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_add_disjunct c1) result;
    c1

  let combine_without_copy_leak_disjunct c1 c2 = 
    let disjuncts = ref [] in
    let iterator = Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_begin_iterator c2 in
    let end_iterator = Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_end_iterator c2 in
    while not (Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_iterator_equals_iterator iterator end_iterator) do
      let disjunct = Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_get_disjunct iterator in
      disjuncts := disjunct :: !disjuncts;
      Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_increment_iterator iterator;
    done;
    let result = !disjuncts in
    List.iter (Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_add_disjunct c1) result;
    c1, result
  
  let combine_with_copy c1 c2 = 
    let disjuncts = ref [] in
    let iterator = Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_begin_iterator c2 in
    let end_iterator = Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_end_iterator c2 in
    while not (Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_iterator_equals_iterator iterator end_iterator) do
      let disjunct = Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_get_disjunct iterator in
      let copy = Ppl_ocaml.ppl_new_NNC_Polyhedron_from_NNC_Polyhedron disjunct in 
      disjuncts := copy :: !disjuncts;
      Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_increment_iterator iterator;
    done;
    let result = !disjuncts in
    List.iter (Ppl_ocaml.ppl_Pointset_Powerset_NNC_Polyhedron_add_disjunct c1) result;
    c1

  let test_without_copy () = 
    let i = ref 0 in 
    while !i < iterations do 
      if (!i mod progress_interval) = 0 then 
        Printf.printf "Iteration %d / %d\n%!" !i iterations; 
      begin 
        try 
          let c1 = base_ps_poly () in 
          let c2 = base_ps_poly () in 
          let combined = combine_without_copy c1 c2 in ignore combined 
        with 
        | Out_of_memory -> 
          Printf.printf "Out of memory at iteration %d\n%!" !i; 
          exit 1 
        | e -> 
          Printf.printf "Exception at iteration %d: %s\n%!" !i (Printexc.to_string e);
      end;
      incr i 
    done; 
    Printf.printf "Finished %d iterations — exiting.\n%!" iterations

  let test_with_copy () = 
    let i = ref 0 in 
    while !i < iterations do 
      if (!i mod progress_interval) = 0 then 
        Printf.printf "Iteration %d / %d\n%!" !i iterations; 
      begin 
        try 
          let c1 = base_ps_poly () in 
          let c2 = base_ps_poly () in 
          let combined = combine_with_copy c1 c2 in ignore combined 
        with 
        | Out_of_memory -> 
          Printf.printf "Out of memory at iteration %d\n%!" !i; 
          exit 1 
        | e -> 
          Printf.printf "Exception at iteration %d: %s\n%!" !i (Printexc.to_string e);
      end;
      incr i 
    done; 
    Printf.printf "Finished %d iterations — exiting.\n%!" iterations

  let test_with_leaking_disjunct () = 
    let i = ref 0 in 
    while !i < iterations do 
      if (!i mod progress_interval) = 0 then 
        Printf.printf "Iteration %d / %d\n%!" !i iterations; 
      begin 
        try 
          let c1 = base_ps_poly () in 
          let c2 = base_ps_poly () in 
          let combined = combine_without_copy_leak_disjunct c1 c2 in ignore combined 
        with 
        | Out_of_memory -> 
          Printf.printf "Out of memory at iteration %d\n%!" !i; 
          exit 1 
        | e -> 
          Printf.printf "Exception at iteration %d: %s\n%!" !i (Printexc.to_string e);
      end;
      incr i 
    done; 
    Printf.printf "Finished %d iterations — exiting.\n%!" iterations
end

let () =
  let open Sys in
  if Array.length argv < 2 then (
    Printf.printf
      "Usage: %s [iterator-nocopy|iterator-copy|copy|orig-nocopy|orig-copy|orig-leak]\n%!"
      argv.(0);
    exit 1
  );
  match argv.(1) with
  | "iterator-nocopy" -> Iterator.test_without_copy ()
  | "iterator-copy" -> Iterator.test_with_copy ()
  | "copy" -> Copy.test ()
  | "orig-nocopy" -> Original.test_without_copy ()
  | "orig-copy" -> Original.test_with_copy ()
  | "orig-leak" -> Original.test_with_leaking_disjunct ()
  | _ -> Printf.printf "Unknown test: %s\n%!" argv.(1)
