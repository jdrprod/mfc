(**************************************************************************)
(*                                                                        *)
(*                      This file is part of MFC                          *)
(*                  it is released under MIT license.                     *)
(*                https://opensource.org/licenses/MIT                     *)
(*                                                                        *)
(*          Copyright (c) 2020 Arthur Correnson, Nathan Graule            *)
(**************************************************************************)

open Mfc_parser
open Mfc_parsing
open Mfc_env
open Mfc_quad
open Mfc_reg_alloc

(** Read all the text from a channel
    @param  ic  input channel *)
let read_all ic =
  let data = ref "" in
  try
    while true do
      data := !data ^ (input_line ic) ^ "\n";
    done;
    !data
  with End_of_file -> !data

(** Generate arm code from sources in channel [ic] to channel [oc]
    @param  ic  input channel
    @param  oc  output channel *)
let generate ?(graph) ic oc =
  let data = read_all ic in
  let ast_opt = parse _prog data in
  match ast_opt with
  | Some (ast, "") ->
    let env = new_env () in
    let () = push_frame env in
    let () = new_function env "print" 0 1 in
    Printf.fprintf oc "@ ==================\n";
    Printf.fprintf oc "@ generated with mfc\n";
    Printf.fprintf oc "@ ==================\n";
    Printf.fprintf oc "int_format: .asciz \"%%d\\n\"\n";
    Printf.fprintf oc ".align\n";
    Printf.fprintf oc "print:\n";
    Printf.fprintf oc "ldr r0, =int_format\n";
    Printf.fprintf oc "pop {r1}\n";
    Printf.fprintf oc "push {lr}\n";
    Printf.fprintf oc "bl printf\n";
    Printf.fprintf oc "pop {pc}\n";
    Printf.fprintf oc ".global main\n";
    Printf.fprintf oc ".extern printf\n";
    Printf.fprintf oc "main:\n";
    Printf.fprintf oc "push {lr}\n";
    let open Mfc_difflist in
    let ql = quad_s ast env |> dmake in
    let rc = env.tmp_counter in
    alloc ql rc |> print_quads oc;
    Printf.fprintf oc "exit: b exit";
    (match graph with
     | Some oc -> dot_output_color oc (get_lifes ql rc |> inter_mat |> inter_graph)
     | None -> ())
  | _ -> failwith "parse error"

