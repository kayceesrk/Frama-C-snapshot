(**************************************************************************)
(*                                                                        *)
(*  This file is part of Frama-C.                                         *)
(*                                                                        *)
(*  Copyright (C) 2007-2011                                               *)
(*    INSA  (Institut National des Sciences Appliquees)                   *)
(*    INRIA (Institut National de Recherche en Informatique et en         *)
(*           Automatique)                                                 *)
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

open Cil_types
open Cil
open Cil_datatype
open Ast_info
open Spec_tools

(**************************************************************************************)

(**
  This visitor does not modify the AST.
  It just generates a first abstract specification for each function.
  This specification is stored into Data_for_aorai and can be accessed by using get_func_pre or get_func_post.
*)
class visit_computing_abstract_pre_post_from_buch (auto:Promelaast.buchautomata) (root:string) (considerAcceptance:bool)  =

object (*(self) *)
  inherit Visitor.generic_frama_c_visitor
    (Project.current ()) (Cil.inplace_visit ()) as super

  method vfunc f =
    if not (Data_for_aorai.isIgnoredFunction f.svar.vname) then begin
(* Extraction of a first abstraction of pre/post condition of the current function *)
      let pre_st,pre_tr  = (Aorai_utils.mk_asbstract_pre  auto f.svar.vname) in
      let post_st,post_tr = (Aorai_utils.mk_asbstract_post auto f.svar.vname) in



      if f.svar.vname = root then
	begin
	  (* Pre simplification for Root (only initial states) *)
	  List.iter (
	    fun tr ->
	      if (pre_tr.(tr.Promelaast.numt)) &&
		(*if ((pre_tr.(tr.Promelaast.numt)) || pre_st.(tr.Promelaast.stop.Promelaast.nums)) &&*)
		((tr.Promelaast.start.Promelaast.init==Bool3.False) || not (Aorai_utils.isCrossableAtInit tr root) )
	      then
		begin
		  pre_tr.(tr.Promelaast.numt)<- false;
		  pre_st.(tr.Promelaast.stop.Promelaast.nums)<- false
		end
	  ) ((snd auto):Promelaast.trans list);


	  List.iter (
	    fun tr ->
	      if (pre_tr.(tr.Promelaast.numt)) then
		pre_st.(tr.Promelaast.stop.Promelaast.nums) <- true
	  ) ((snd auto):Promelaast.trans list);




	  if considerAcceptance then begin
	    (* Post simplification for Root (Only acceptance states) *)
	    List.iter (
	      fun tr ->
		if (post_tr.(tr.Promelaast.numt)) &&
		  (*if ((post_tr.(tr.Promelaast.numt)) || post_st.(tr.Promelaast.stop.Promelaast.nums)) &&*)
		  (tr.Promelaast.stop.Promelaast.acceptation==Bool3.False)
		then
		  begin
		    post_tr.(tr.Promelaast.numt)<- false;
		    post_st.(tr.Promelaast.stop.Promelaast.nums)<- false
		  end
	    ) ((snd auto):Promelaast.trans list);


	    List.iter (
	      fun tr ->
		if (post_tr.(tr.Promelaast.numt)) then
		  post_st.(tr.Promelaast.stop.Promelaast.nums) <- true
	    ) ((snd auto):Promelaast.trans list)
	  end
	end;

      Data_for_aorai.set_func_pre  f.svar.vname (pre_st,pre_tr) ;
      Data_for_aorai.set_func_post f.svar.vname (post_st,post_tr)
    end;
    DoChildren
end





(**************************************************************************************)


(**
  This visitor add a ghost code before each call and return functions in order to compute the modification of the buchi automata.
*)
class visit_adding_code_for_synchronisation (auto:Promelaast.buchautomata) =
  let current_function = ref "" in
  let get_call_name exp =
    match exp.enode with
      | Const(CStr(s)) -> s
      | Lval(Var(vi),NoOffset) -> vi.vname
      | _ ->
          Aorai_option.abort
            "At this time, only explicit calls are allowed by the \
             Aorai plugin.;"
  in
object (*(self) *)
  inherit Visitor.generic_frama_c_visitor
    (Project.current ()) (Cil.inplace_visit ()) as super

  method vfunc f =
    current_function := f.svar.vname;
    DoChildren


  method vstmt_aux stmt =
    match stmt.skind with
      | Return (_,loc)  ->
	  if not (Data_for_aorai.isIgnoredFunction !current_function) then begin
	    let sync_inst_l = Aorai_utils.synch_upd auto (!current_function) Promelaast.Return loc None None in
	    let new_return = mkStmt stmt.skind in
	    new_return.sid<-(Cil.Sid.next ());
	    let new_stmts =
	      List.fold_left
		(fun stmt_l inst ->
		   let n_stmt=(Cil.mkStmtOneInstr inst) in
		   n_stmt.sid<-(Cil.Sid.next ());
		   n_stmt::stmt_l
		)
		[new_return]
		sync_inst_l

	    in
  	    stmt.skind<-Block(Cil.mkBlock(new_stmts))
	  end;
	  SkipChildren



      (* This second treatment can be done easierly with vinst method, but sid is then set to -1 *)
      | Instr(Call (_,funcexp,_,loc)) ->
	  if not (Data_for_aorai.isIgnoredFunction (get_call_name funcexp)) then begin

	    let sync_inst_l = Aorai_utils.synch_upd auto (get_call_name funcexp) Promelaast.Call loc (Some(!current_function)) (Some(stmt.sid)) in
	    let new_call = mkStmt stmt.skind in
	    new_call.sid<-(Cil.Sid.next ());
	    let new_stmts =
	      List.fold_left
		(fun stmt_l inst ->
		   let n_stmt=(Cil.mkStmtOneInstr inst) in
		   n_stmt.sid<-(Cil.Sid.next ());
		   n_stmt::stmt_l
		)
		[new_call]
		sync_inst_l

	    in
  	    stmt.skind<-Block(Cil.mkBlock(new_stmts))
	  end;
	  SkipChildren


      | _ -> DoChildren

end










(**************************************************************************************)

let post_treatment_loops = Hashtbl.create 97;

(**
   This visitor add a specification to each fonction and to each loop,
   according to specifications stored into Data_for_aorai.
*)
class visit_adding_pre_post_from_buch
  (auto:Promelaast.buchautomata) treatloops =

  let predicate_to_invariant ref_stmt pred =
    (* 4) Add new annotation *)
    Annotations.add
      !ref_stmt
      [ (*Ast.self; *)
	(*Aorai_option.Ltl_File.self;
	Aorai_option.Buchi.self;
	Aorai_option.Ya.self ;*)
	(*Aorai_option.AbstractInterpretationOff.self ;*)
	Aorai_option.AbstractInterpretation.self ]
      (Db_types.Before
	 (Db_types.User
	    (Logic_const.new_code_annotation (AInvariant([],true,pred))))) ;
  in

  (** Given a couple of bool array (States , Transitions),
      this function computes a predicate and add it as an invariant. *)
  let condition_to_invariant cond stmt_ref =
    let pred_l = Aorai_utils.pre_post_to_term cond in
    let pred = Aorai_utils.mk_conjunction_named pred_l in
    predicate_to_invariant stmt_ref pred
  in


  (** Given the number of states a by-case post-condition and a state number,
      it returns a bool array with nb_states cells.
      A cell is true if and only if the associated post-condition is
      equivalent to the one of the given state. *)
  let get_other_states_with_equivalent_post nb_states (post_bc_st,post_bc_tr) index =
    let eq_states=Array.make nb_states false in
    eq_states.(index)<-true;
    Array.iteri
      (fun i post_st ->
	 if i<>index &&
	   (bool_array_eq post_st post_bc_st.(index))&&
	   (bool_array_eq post_bc_tr.(i) post_bc_tr.(index)) (* Toujours Faux tq l'on veut eq des tr *)
	 then
	   eq_states.(i)<-true;
      )
      post_bc_st;
    eq_states
  in



object (*(self) *)

  inherit Visitor.generic_frama_c_visitor
    (Project.current ()) (Cil.inplace_visit ()) as super

  method vfunc f =
    let spec= Kernel_function.get_spec (Globals.Functions.get f.svar) in

(* Rewriting arrays carracterizing status into predicates *)
    let preds_pre  = Aorai_utils.pre_post_to_term (Data_for_aorai.get_func_pre  f.svar.vname) in
    let preds_post_bc = Data_for_aorai.get_func_post_bycase f.svar.vname in

(* if AddingOperationNameAndStatusInSpecification is set*)
(* adding the condition CALLED for pre*)
    let preds_pre_with_called_stat = fun preds_pre -> (

      if Aorai_option.AddingOperationNameAndStatusInSpecification.get() then begin
	let called_pre = Logic_const.prel (Req ,Aorai_utils.mk_term_from_vi (Data_for_aorai.get_varinfo Data_for_aorai.curOpStatus),  (Logic_utils.mk_dummy_term (TConst(Data_for_aorai.op_status_to_cenum Promelaast.Call)) Cil.intType)) in
	let called_pre_2 =  Logic_const.prel (Req ,Aorai_utils.mk_term_from_vi (Data_for_aorai.get_varinfo Data_for_aorai.curOp), (Logic_utils.mk_dummy_term (TConst(Data_for_aorai.func_to_cenum f.svar.vname)) Cil.intType)) in

	List.append [called_pre;called_pre_2] preds_pre
      end
      else
	preds_pre
    )in
    let preds_pre = preds_pre_with_called_stat preds_pre in


    let pre_wrt_params = Aorai_utils.get_preds_pre_wrt_params f.svar.vname in
    let preds_pre = match pre_wrt_params with
      | None -> preds_pre
      | Some (p) -> (Logic_const.unamed p)::preds_pre
    in




(* Registration of the new specification *)

(*   + Pre-condition registration *)

    let new_requires = List.map Logic_const.new_predicate preds_pre in
    let behavior = (* the default behavior having no assume *)
      (Cil.mk_behavior ~requires:new_requires ()) in
      spec.spec_behavior <- Logic_utils.merge_behaviors ~silent:true spec.spec_behavior [behavior] ;


(*   + Post-condition registration *)
(*      If several states are associated to the same post-condition,
	then their specification is factorised. *)
    let nb_states=Data_for_aorai.getNumberOfStates() in
    let treated=ref (Array.make nb_states false) in




(*      the goal is to know how many behavior are created: if only one behavior is created so the assumes is not needed*)

    let nb_behavior = ref 0 in
    let save_assumes_l = ref [] in
    (* Initialized with an empty behavior *)
    let old_behavior =
      ref (Cil.mk_behavior ~name:"" ())
    in


    Array.iteri
      (fun case preds_post ->

	 if   (not (Spec_tools.is_empty_behavior preds_post) )
	   && (not (!treated).(case))
	 then begin
	   let new_behavior = Cil.mk_behavior ~name:("Buchi_property_behavior_"^(string_of_int case)) () in
	   let all_eqs_states = get_other_states_with_equivalent_post nb_states preds_post_bc case in
	   let assumes_l = ref [] in


	   Array.iteri
	     (fun i b -> if b then
		assumes_l:=Logic_const.prel(
		  Rneq,
		  Aorai_utils.zero_term(),
		  Aorai_utils.mk_offseted_array_states_as_enum
		    (Logic_utils.lval_to_term_lval ~cast:true (Cil.var (Data_for_aorai.get_varinfo Data_for_aorai.curState)))
		    i
		)::!assumes_l
	     )
	     all_eqs_states;


(* On the first behavior's creation, we supposed that assumes are not needed*)
(* but on the second, we know that the first must be set so*)
(* we put into the first the omitting behaviors (saved in old_behavior) and all assumes (saved in save_assumes_l)*)
(* After that, the loop is classic (behavior are automatically setted)*)
	   begin
	     match !nb_behavior with
	       | 0 -> nb_behavior:=1;
		   save_assumes_l := !assumes_l ;
		   old_behavior := new_behavior;
		   Aorai_option.debug "one behavior"

	       | 1 -> nb_behavior:=2;
		   new_behavior.b_assumes<-[Logic_const.new_predicate (Aorai_utils.mk_disjunction_named !assumes_l)];
		   (!old_behavior).b_assumes<-[Logic_const.new_predicate (Aorai_utils.mk_disjunction_named !save_assumes_l)];
		   Aorai_option.debug "2 behaviors"

	       | _ -> new_behavior.b_assumes<-[Logic_const.new_predicate (Aorai_utils.mk_disjunction_named !assumes_l)];
	   end;



	   Aorai_option.debug "behaviors registration";
	   treated:=bool_array_or !treated all_eqs_states;

	   (*
	   new_behavior.b_assumes<-
	     [Logic_const.new_predicate
		(Logic_const.prel(
		   Rneq,
		   Aorai_utils.zero_term(),
		   Aorai_utils.mk_offseted_array
		     (Logic_const.lval_to_term_lval (Cil.var (Data_for_aorai.get_varinfo Data_for_aorai.curState)))
		     case))];*)



	   let preds_list = Aorai_utils.pre_post_to_term (preds_post,(snd preds_post_bc).(case)) in
	   List.iter
	     (fun p ->
                new_behavior.b_post_cond <-
                  ((Normal, Logic_const.new_predicate p) ::
                     new_behavior.b_post_cond))
	     preds_list;


	   begin
	     let post_wrt_params = Aorai_utils.get_preds_post_bc_wrt_params f.svar.vname in
	     match post_wrt_params with
	       | None -> ()
	       | Some (p) -> new_behavior.b_post_cond <- (Normal, Logic_const.new_predicate (Logic_const.unamed p))::new_behavior.b_post_cond
	   end;


	   spec.spec_behavior <- new_behavior::spec.spec_behavior

	 end
      )
      (fst preds_post_bc);
(*      spec.spec_complete_behaviors <- new_behavior.b_name::spec.spec_complete_behaviors;*)


    (* if bycase is set*)
    (* adding require called and behavior ensures return *)
    let preds_post_with_return_status  =  fun spec -> (
      if Aorai_option.AddingOperationNameAndStatusInSpecification.get() then begin
        let called_post = Logic_const.new_predicate (Logic_const.prel (Req ,Aorai_utils.mk_term_from_vi (Data_for_aorai.get_varinfo Data_for_aorai.curOpStatus),  (Logic_utils.mk_dummy_term (TConst(Data_for_aorai.op_status_to_cenum Promelaast.Return)) Cil.intType))) in
        let called_post_2 = Logic_const.new_predicate (Logic_const.prel (Req ,Aorai_utils.mk_term_from_vi (Data_for_aorai.get_varinfo Data_for_aorai.curOp), (Logic_utils.mk_dummy_term (TConst(Data_for_aorai.func_to_cenum f.svar.vname)) Cil.intType))) in
        let new_behavior =
          {
            b_name = "Buchi_property_behavior_function_states";
            b_assumes = [] ;
            b_requires = [] ;
            b_post_cond = [Normal, called_post; Normal, called_post_2] ;
            b_assigns = WritesAny ;
            b_extended = []
          }
        in
        spec.spec_behavior <- new_behavior::spec.spec_behavior

      end
      else
        ()
    )in
    preds_post_with_return_status spec;

    DoChildren








  method vstmt_aux stmt =
    let treat_loop body_ref stmt =

      (* varinfo of the init_var associated to this loop *)
      let vi_init = Data_for_aorai.get_varinfo (Data_for_aorai.loopInit^"_"^(string_of_int stmt.sid)) in


(*    1) The associated init variable is set to 0 in first position
         (or in second position if the first stmt is a if)*)

      let stmt_varset =
	Cil.mkStmtOneInstr
	  (Set((Var vi_init,NoOffset),
	       Aorai_utils.mk_int_exp 0, Location.unknown))
      in
      stmt_varset.sid<-(Cil.Sid.next ());
      stmt_varset.ghost<-true;

      begin
        (* Function adaptated from the cil printer *)
        try
	  let rec skipEmpty = function
              [] -> []
            | {skind=Instr (Skip _);labels=[]} :: rest -> skipEmpty rest
            | x -> x
          in

          match skipEmpty !body_ref.bstmts with
            | {skind=If(_,tb,fb,_)} as head:: _ ->
                begin
                  match skipEmpty tb.bstmts, skipEmpty fb.bstmts with
                    | _, {skind=Break _}:: _
                    | _, {skind=Goto _} :: _
                    | {skind=Goto _} :: _, _
                    | {skind=Break _} :: _, _ ->
			!body_ref.bstmts<-head::(stmt_varset::(List.tl !body_ref.bstmts))

		    | _ ->
			raise Not_found
                end
            | _ -> raise Not_found

	with
	  | Not_found ->
	      !body_ref.bstmts<-stmt_varset::!body_ref.bstmts
      end;


(*    2) The associated init variable is set to 1 before the loop *)
      let new_loop = mkStmt stmt.skind in
      new_loop.sid<-(Cil.Sid.next ());
      let stmt_varset =
	Cil.mkStmtOneInstr (Set((Var(vi_init),NoOffset),
				Aorai_utils.mk_int_exp 1, Location.unknown))
      in
      stmt_varset.sid <- Cil.Sid.next ();
      stmt_varset.ghost <- true;
      let block = mkBlock [stmt_varset;new_loop] in
      stmt.skind<-Block(block);




(*    3) Generation of the loop invariant *)
      let mk_imply operator predicate =
	(Logic_const.unamed
	   (Pimplies
	      (Logic_const.unamed (Prel(operator,
					Aorai_utils.mk_term_from_vi vi_init,
					Aorai_utils.zero_term())),
	       Logic_const.unamed predicate)))
      in
(* The loop invariant is :
     (Global invariant)  // all never reached state /crossed transition are set to zero
   & (Pre2)              // internal pre-condition
   & (Init => Pre1)      // external pre-condition
   & (not Init => Post2) // internal post-condition
   (init : fresh variable which indicates if the iteration is the first one).
*)
      let global_loop_inv = Aorai_utils.get_global_loop_inv (ref stmt) in
      condition_to_invariant global_loop_inv (ref new_loop);

      let pre2 = Aorai_utils.get_restricted_int_pre_bc (ref stmt) in
      if pre2<>Cil_types.Ptrue then
	predicate_to_invariant (ref new_loop) (Logic_const.unamed pre2);

      let pre1 = Aorai_utils.get_restricted_ext_pre_bc (ref stmt) in
      if pre1<>Cil_types.Ptrue then
	predicate_to_invariant (ref new_loop) (mk_imply Rneq pre1);

      let post2 = Aorai_utils.get_restricted_int_post_bc (ref stmt) in
      if post2<>Cil_types.Ptrue then
	predicate_to_invariant (ref new_loop) (mk_imply Req post2);



(*    4) Keeping in mind to preserve old annotations after visitor end *)
      Hashtbl.add post_treatment_loops (ref stmt) (ref new_loop);


(*    5) Updated stmt is returned *)
	  stmt
    in
    if treatloops then
      match stmt.skind with
	| Loop (_,block,_,_,_) ->
	    ChangeDoChildrenPost(stmt, treat_loop (ref block))

	| _ -> DoChildren
    else
      DoChildren
end





(**************************************************************************************)
(**
  This visitor computes the list of ignored functions.
  A function is ignored if its call is present in the C program, while its declaration is not available.
*)
class visit_computing_ignored_functions () =
  let current_function = ref "" in

  let get_call_name exp =
    match exp.enode with
      | Const(CStr(s)) -> s
      | Lval(Var(vi),NoOffset) -> vi.vname
      | _ ->
          Aorai_option.abort
            "At this time, only explicit calls are allowed by the \
             Aorai plugin.;"
  in

  let declaredFunctions = Data_for_aorai.getFunctions_from_c () in
  let isDeclaredInC fname =
    List.exists
      (fun s -> (String.compare fname s)=0)
      declaredFunctions
  in


object (*(self) *)
  inherit Visitor.generic_frama_c_visitor
    (Project.current ()) (Cil.inplace_visit ()) as super

  method vfunc f =
    current_function := f.svar.vname;
    DoChildren


  method vstmt_aux stmt =
    match stmt.skind with
      | Instr(Call (_,funcexp,_,_)) ->
	  let name = get_call_name funcexp in
	  (* If the called function is neither ignored, nor declared, then it has to be added to ignored functions. *)
	  if (not (Data_for_aorai.isIgnoredFunction name))
	    && (not (isDeclaredInC name)) then
		(Data_for_aorai.addIgnoredFunction name);
	  DoChildren



      | _ -> DoChildren

end






(**************************************************************************************)



(* Call of the visitors *)
let compute_abstract file root (considerAcceptance:bool) =
  let visitor = new visit_computing_abstract_pre_post_from_buch
    (Data_for_aorai.getAutomata()) (root) considerAcceptance
  in
  Cil.visitCilFile (visitor :> Cil.cilVisitor) file

(* This visitor requires the AI to compute loop invariants. *)
let add_pre_post_from_buch file treatloops  =
  let visitor =
    new visit_adding_pre_post_from_buch
      (Data_for_aorai.getAutomata())
      treatloops
  in
  Cil.visitCilFile (visitor :> Cil.cilVisitor) file;
  (* Transfert previous annotation on the new loop statement.
     Variant clause has to be preserved at the end of the annotation.*)
  Hashtbl.iter
    (fun old_stmt new_stmt ->
       Annotations.single_iter_stmt
	 (fun an -> Annotations.add !new_stmt
	    [(* Ast.self; Aorai_option.Ltl_File.self;
		Aorai_option.Buchi.self;
		Aorai_option.Ya.self *) ]  an)
	 !old_stmt;

       (* Erasing annotations from old statement *)
       Annotations.reset_stmt ?reset:true !old_stmt;

    )
    post_treatment_loops














let add_sync_with_buch file  =
  let visitor =
    new visit_adding_code_for_synchronisation (Data_for_aorai.getAutomata())
  in
  Cil.visitCilFile (visitor :> Cil.cilVisitor) file

(* Call of the visitor *)
let compute_ignored_functions file =
  let visitor = new visit_computing_ignored_functions () in
  Cil.visitCilFile (visitor :> Cil.cilVisitor) file

(*
Local Variables:
compile-command: "LC_ALL=C make -C ../.."
End:
*)