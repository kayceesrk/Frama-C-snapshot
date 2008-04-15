(* This file was originally generated by why.
   It can be modified; only the generated parts will be overwritten. *)

Require Why.
Require Omega.

Parameter q : Z -> Prop.

(* Why obligation from file "good/po.mlw", characters 153-194 *)
Lemma p1_po_1 : 
  (x: Z)
  (Pre1: (q `x + 1`))
  (x0: Z)
  (Post1: x0 = `x + 1`)
  (q x0).
Proof. 
Intros; Rewrite Post1; Assumption.
Save.




(* Why obligation from file "good/po.mlw", characters 205-243 *)
Lemma p2_po_1 : 
  (Pre1: (q `7`))
  (x0: Z)
  (Post1: x0 = `3 + 4`)
  (q x0).
Proof.
Intros; Rewrite Post1; Assumption.
Save.




(* Why obligation from file "good/po.mlw", characters 254-306 *)
Lemma p3_po_1 : 
  (x: Z)
  (x0: Z)
  (Post1: x0 = `x + 1`)
  (x1: Z)
  (Post2: x1 = `x0 + 2`)
  `x1 = x + 3`.
Proof. 
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 317-360 *)
Lemma p4_po_1 : 
  (x0: Z)
  (Post1: x0 = `7`)
  (x1: Z)
  (Post2: x1 = `2 * x0`)
  `x1 = 14`.
Proof. 
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 371-396 *)
Lemma p5_po_1 : 
  `3 + 4 = 7`.
Proof.
Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 424-429 *)
Lemma p6_po_1 : 
  (a: Z)
  (Post1: a = `3`)
  `a + 4 = 7`.
Proof.
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 478-483 *)
Lemma p7_po_1 : 
  (a: Z)
  (Post1: a = `4`)
  `3 + (a + a) = 11`.
Proof.
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 592-594 *)
Lemma p8_po_1 : 
  (x: Z)
  (Pre1: (q `x + 1`))
  (x0: Z)
  (Post1: x0 = `x + 1`)
  (q x0) /\ `3 + x0 = x + 4`.
Proof.
Intuition; Rewrite Post1; Assumption.
Save.




(* Why obligation from file "good/po.mlw", characters 723-724 *)
Lemma p9_po_1 : 
  (x0: Z)
  (Post3: x0 = `2`)
  ((x:Z) (x = `1` -> `1 + 1 = 2` /\ `x = 1`)).
Proof.
Intuition.
Save.


(* Why obligation from file "good/po.mlw", characters 784-785 *)
Lemma p9a_po_1 : 
  (x0: Z)
  (Post2: x0 = `1`)
  `1 + 1 = 2` /\ `x0 = 1`.
Proof.
Intuition.
Save.




(*Why*) Parameter fsucc : (x: Z)(sig_1 Z [result: Z](`result = x + 1`)).

(* Why obligation from file "good/po.mlw", characters 924-951 *)
Lemma p10_po_1 : 
  (result1: Z)
  (Post1: `result1 = 0 + 1`)
  `result1 = 1`.
Proof.
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 963-1004 *)
Lemma p11_po_1 : 
  (aux_2: Z)
  (Post1: `aux_2 = 3 + 1`)
  (aux_1: Z)
  (Post4: `aux_1 = 0 + 1`)
  `aux_1 + aux_2 = 5`.
Proof.
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 1042-1047 *)
Lemma p11a_po_1 : 
  (a: Z)
  (Post1: `a = 1 + 1`)
  `a + a = 4`.
Proof.
Intros; Omega.
Save.




(*Why*) Parameter incrx :
  (_: unit)(x: Z)(sig_2 Z unit [x0: Z][result: unit](`x0 = x + 1`)).

(* Why obligation from file "good/po.mlw", characters 1190-1222 *)
Lemma p12_po_1 : 
  (x: Z)
  (Pre1: `x = 0`)
  (x0: Z)
  (Post1: `x0 = x + 1`)
  `x0 = 1`.
Proof.
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 1234-1288 *)
Lemma p13_po_1 : 
  (x: Z)
  (x0: Z)
  (Post1: `x0 = x + 1`)
  (x1: Z)
  (Post3: `x1 = x0 + 1`)
  `x1 = x + 2`.
Proof.
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 1301-1339 *)
Lemma p13a_po_1 : 
  (x: Z)
  (x0: Z)
  (Post1: `x0 = x + 1`)
  (x1: Z)
  (Post3: `x1 = x0 + 1`)
  `x1 = x + 2`.
Proof.
Intros; Omega.
Save.




(*Why*) Parameter incrx2 :
  (_: unit)(x: Z)
  (sig_2 Z Z [x0: Z][result: Z](`x0 = x + 1` /\ `result = x0`)).

(* Why obligation from file "good/po.mlw", characters 1487-1525 *)
Lemma p14_po_1 : 
  (x: Z)
  (Pre1: `x = 0`)
  (x0: Z)
  (result1: Z)
  (Post1: `x0 = x + 1` /\ `result1 = x0`)
  `result1 = 1`.
Proof.
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 1576-1608 *)
Lemma p15_po_1 : 
  (t: (array Z))
  (Pre2: `(array_length t) = 10`)
  `0 <= 0` /\ `0 < (array_length t)`.
Proof. (* p15_po_1 *)
Intros; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 1621-1658 *)
Lemma p16_po_1 : 
  (t: (array Z))
  (Pre2: `(array_length t) = 10`)
  `0 <= 9` /\ `9 < (array_length t)`.
Proof. (* p16_po_1 *)
Intros; Simpl; Omega.
Save.




(* Why obligation from file "good/po.mlw", characters 1671-1730 *)
Lemma p17_po_1 : 
  (t: (array Z))
  (Pre3: `(array_length t) = 10` /\ `0 <= (access t 0)` /\
         `(access t 0) < 10`)
  `0 <= (access t 0)` /\ `(access t 0) < (array_length t)`.
Proof. (* p17_po_1 *)
Intros; Omega.
Save.


(* 
 Local Variables:
 mode: coq 
  coq-prog-name: "coqtop -emacs -q -I ../../lib/coq"
 End:
*)


(* Why obligation from file "good/po.mlw", characters 1717-1721 *)
Lemma p17_po_2 : 
  (t: (array Z))
  (Pre3: `(array_length t) = 10` /\ `0 <= (access t 0)` /\
         `(access t 0) < 10`)
  (Pre2: `0 <= (access t 0)` /\ `(access t 0) < (array_length t)`)
  `0 <= 0` /\ `0 < (array_length t)`.
Proof.
Intros; Simpl; Omega.
Save.


(* Why obligation from file "good/po.mlw", characters 1788-1790 *)
Lemma p18_po_1 : 
  (t: (array Z))
  (x: Z)
  (Pre2: `(array_length t) = 10`)
  (aux_2: Z)
  (Post2: aux_2 = x)
  (x0: Z)
  (Post1: x0 = `0`)
  `(access (store t x0 aux_2) 0) = x` /\ `0 <= x0` /\ `x0 < (array_length t)`.
Proof.
Intuition.
Subst x0; AccessSame.
Save.

