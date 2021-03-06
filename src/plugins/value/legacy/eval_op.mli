(**************************************************************************)
(*                                                                        *)
(*  This file is part of Frama-C.                                         *)
(*                                                                        *)
(*  Copyright (C) 2007-2017                                               *)
(*    CEA (Commissariat à l'énergie atomique et aux énergies              *)
(*         alternatives)                                                  *)
(*                                                                        *)
(*  you can redistribute it and/or modify it under the terms of the GNU   *)
(*  Lesser General Public License as published by the Free Software       *)
(*  Foundation, version 2.1.                                              *)
(*                                                                        *)
(*  It is distributed in the hope that it will be useful,                 *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU Lesser General Public License for more details.                   *)
(*                                                                        *)
(*  See the GNU Lesser General Public License version 2.1                 *)
(*  for more details (enclosed in the file licenses/LGPLv2.1).            *)
(*                                                                        *)
(**************************************************************************)

(** Numeric evaluation. Factored with evaluation in the logic. *)

open Cil_types
open Cvalue

(** Transformation a value into an offsetmap of size [sizeof(typ)] bytes. *)
val offsetmap_of_v: typ:Cil_types.typ -> V.t -> V_Offsetmap.t

(** Specialization of the function above for standard types *)
val wrap_size_t: V.t -> V_Offsetmap.t option
val wrap_int: V.t -> V_Offsetmap.t option
val wrap_ptr: V.t -> V_Offsetmap.t option
val wrap_double: V.t -> V_Offsetmap.t option
val wrap_float: V.t -> V_Offsetmap.t option

val reinterpret_float:
  with_alarms:CilE.warn_mode -> Cil_types.fkind -> V.t -> V.t
(** Read the given value value as a float int of the given [fkind]. Warn if the
    value contains an address, or is not representable as a finite float.  *)

val reinterpret:
  with_alarms:CilE.warn_mode -> Cil_types.typ -> V.t -> V.t


val eval_binop_float :
  with_alarms:CilE.warn_mode ->
  Fval.rounding_mode ->
  Cvalue.V.t -> binop -> Cvalue.V.t -> Cvalue.V.t

val eval_binop_int :
  with_alarms:CilE.warn_mode ->
  te1:typ ->
  Cvalue.V.t -> binop -> Cvalue.V.t -> Cvalue.V.t

val eval_unop:
  check_overflow:bool ->
  with_alarms:CilE.warn_mode ->
  Cvalue.V.t ->
  typ (** Type of the expression under the unop *) ->
  Cil_types.unop -> Cvalue.V.t

val do_promotion:
  with_alarms:CilE.warn_mode ->
  Fval.rounding_mode ->
  src_typ:Cil_types.typ ->
  dst_typ:Cil_types.typ ->
  Cvalue.V.t -> Cvalue.V.t

val backward_comp_left_from_type:
  Cil_types.typ ->
  (bool -> Abstract_interp.Comp.t -> Cvalue.V.t -> Cvalue.V.t -> Cvalue.V.t)
(** Reduction of a {!Cvalue.V.t} by [==], [!=], [>=], [>], [<=] and [<].
    [backward_comp_left_from_type positive op l r] reduces [l]
    so that the relation [l op r] holds. [typ] is the type of [l]. *)

val reduce_by_initialized_defined :
  (V_Or_Uninitialized.t -> V_Or_Uninitialized.t) ->
  Locations.location -> Model.t -> Model.t

val apply_on_all_locs:
  (Locations.location -> 'a -> 'a) -> Locations.location -> 'a -> 'a
(** [apply_all_locs f loc state] folds [f] on all the atomic locations
    in [loc], provided there are less than [plevel]. Useful mainly
    when [loc] is exact or an over-approximation. *)

val reduce_by_valid_loc:
  positive:bool ->
  for_writing:bool ->
  Locations.location -> typ -> Model.t -> Model.t
(* [reduce_by_valid_loc positive ~for_writing loc typ state] reduces
   [state] so that [loc] contains a pointer [p] such that [(typ* )p] is
   valid if [positive] holds (or invalid otherwise). *)

val make_loc_contiguous: Locations.location -> Locations.location
(** 'Simplify' the location if it represents a contiguous zone: instead
    of multiple offsets with a small size, change it into a single offset
    with a size that covers the entire range. *)

val pretty_stitched_offsetmap: Format.formatter -> typ -> V_Offsetmap.t -> unit

(*
Local Variables:
compile-command: "make -C ../../../.."
End:
*)
