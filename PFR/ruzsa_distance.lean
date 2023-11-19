import Mathlib.Probability.Notation
import Mathlib.Probability.ConditionalProbability
import Mathlib.Probability.IdentDistrib
import PFR.RuzsaDistance.EntropyGroup
import PFR.entropy_basic

/-!
# Ruzsa distance

Here we define Ruzsa distance and establish its basic properties.

## Main definitions

* `rdist`: The Ruzsa distance between two random variables

## Main results

* `rdist_triangle`: The Ruzsa triangle inequality for three random variables.

-/
open MeasureTheory ProbabilityTheory

variable {Ω Ω' Ω'' Ω''' G T : Type*}
  [mΩ : MeasurableSpace Ω] {μ : Measure Ω}
  [mΩ' : MeasurableSpace Ω'] {μ' : Measure Ω'}
  [mΩ'' : MeasurableSpace Ω''] {μ'' : Measure Ω''}
  [mΩ''' : MeasurableSpace Ω'''] {μ''' : Measure Ω'''}
  [hG: MeasurableSpace G] [MeasurableSingletonClass G] [AddCommGroup G]
  [MeasurableSub₂ G] [MeasurableAdd₂ G] [Fintype G]
  [Fintype T] [Nonempty T] [MeasurableSpace T] [MeasurableSingletonClass T]

/-- For mathlib -/
instance : MeasurableNeg G := by
  constructor
  convert measurable_const (a := (0 : G)).sub measurable_id
  ext x
  simp

variable {X : Ω → G} {Y : Ω' → G} {Z : Ω'' → G}

-- may also want [DecidableEq G]

/-- If $X$ is $G$-valued, then $H[-X]=H[X]$. -/
lemma entropy_neg (hX : Measurable X) : H[-X ; μ] = H[X ; μ] :=
  entropy_comp_of_injective μ hX (fun x ↦ - x) neg_injective

lemma entropy_sub_comm {Y : Ω → G} (hX : Measurable X) (hY : Measurable Y) :
    H[X - Y; μ] = H[Y - X; μ] := by
  rw [← neg_sub]
  exact entropy_neg (hY.sub hX)

lemma entropy_sub_mutualInformation_le_entropy_add
    {Y : Ω → G} (hX : Measurable X) (hY : Measurable Y) [IsProbabilityMeasure μ] :
    H[X; μ] - I[X : Y; μ] ≤ H[X + Y; μ] := by
  rw [mutualInformation_eq_entropy_sub_condEntropy hX hY]
  ring_nf
  calc H[X|Y; μ]
    = H[X + Y | Y; μ] := by
        refine (condEntropy_of_inj_map μ hX hY (fun y x ↦ x + y) ?_).symm
        intro y
        exact add_left_injective y
  _ ≤ H[X + Y; μ] := condEntropy_le_entropy _ (hX.add hY) hY

lemma entropy_sub_mutualInformation_le_entropy_sub
    {Y : Ω → G} (hX : Measurable X) (hY : Measurable Y) [IsProbabilityMeasure μ] :
    H[X; μ] - I[X : Y; μ] ≤ H[X - Y; μ] := by
  rw [mutualInformation_eq_entropy_sub_condEntropy hX hY]
  ring_nf
  calc H[X|Y; μ]
    = H[X - Y | Y; μ] := by
        refine (condEntropy_of_inj_map μ hX hY (fun y x ↦ x - y) ?_).symm
        intro y
        exact sub_left_injective
  _ ≤ H[X - Y; μ] := condEntropy_le_entropy _ (hX.sub hY) hY

/-- $$ \max(H[X], H[Y]) - I[X:Y] \leq H[X + Y].$$ -/
lemma ent_of_sum_lower {Y : Ω → G} (hX : Measurable X) (hY : Measurable Y)
    [IsProbabilityMeasure μ] :
    (max H[X; μ] H[Y; μ]) - I[X : Y; μ] ≤ H[X + Y; μ] := by
  rw [sub_le_iff_le_add']
  refine max_le ?_ ?_
  · rw [← sub_le_iff_le_add']
    exact entropy_sub_mutualInformation_le_entropy_add hX hY
  · rw [← sub_le_iff_le_add', mutualInformation_comm hX hY, add_comm X]
    exact entropy_sub_mutualInformation_le_entropy_add hY hX

/-- $$ \max(H[X], H[Y]) - I[X:Y] \leq H[X - Y].$$ -/
lemma ent_of_diff_lower {Y : Ω → G} (hX : Measurable X) (hY : Measurable Y)
    [IsProbabilityMeasure μ] :
  (max H[X; μ] H[Y; μ]) - I[X : Y; μ] ≤ H[X - Y; μ] := by
  rw [sub_le_iff_le_add']
  refine max_le ?_ ?_
  · rw [← sub_le_iff_le_add']
    exact entropy_sub_mutualInformation_le_entropy_sub hX hY
  · rw [← sub_le_iff_le_add', mutualInformation_comm hX hY, entropy_sub_comm hX hY]
    exact entropy_sub_mutualInformation_le_entropy_sub hY hX

/-- $$ \max(H[X|Z], H[Y|Z]) - I[X:Y|Z] \leq H[X+ Y|Z] $$ -/
lemma condEnt_of_sum_lower {Y : Ω → G} {Z : Ω → T}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    [IsProbabilityMeasure μ] :
    (max H[X | Z; μ] H[Y | Z; μ]) - I[X : Y | Z ; μ] ≤ H[X + Y | Z; μ] := by
  have : IsMarkovKernel (condEntropyKernel (fun a ↦ (Y a, X a)) Z μ) :=
    isMarkovKernel_condEntropyKernel (hY.prod_mk hX) hZ μ
  have : IsProbabilityMeasure (μ.map Z) := isProbabilityMeasure_map hZ.aemeasurable
  rw [condMutualInformation_comm hX hY, condEntropy_eq_kernel_entropy hX hZ,
    condEntropy_eq_kernel_entropy hY hZ, condMutualInformation_eq_kernel_mutualInfo hY hX hZ,
    condEntropy_eq_kernel_entropy ?_ hZ]
  swap; · exact hX.add hY
  rw [kernel.entropy_congr (condEntropyKernel_snd_ae_eq hY hX hZ μ).symm,
    kernel.entropy_congr (condEntropyKernel_fst_ae_eq hY hX hZ μ).symm,
    max_comm]
  refine (kernel.ent_of_sum_lower _ _ ).trans_eq ?_
  have h := condEntropyKernel_comp (hY.prod_mk hX) hZ μ (fun x ↦ x.1 + x.2)
  rw [kernel.entropy_congr h.symm]
  congr with ω
  simp [add_comm (X ω)]

/-- $$ \max(H[X|Z], H[Y|Z]) - I[X:Y|Z] \leq H[X - Y|Z] $$ -/
lemma condEnt_of_diff_lower {Y : Ω → G} {Z : Ω → T}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    [IsProbabilityMeasure μ] :
    (max H[X | Z; μ] H[Y | Z; μ]) - I[X : Y | Z ; μ] ≤ H[X - Y | Z; μ] := by
  have : IsMarkovKernel (condEntropyKernel (fun a ↦ (Y a, X a)) Z μ) :=
    isMarkovKernel_condEntropyKernel (hY.prod_mk hX) hZ μ
  have : IsProbabilityMeasure (μ.map Z) := isProbabilityMeasure_map hZ.aemeasurable
  rw [condMutualInformation_comm hX hY, condEntropy_eq_kernel_entropy hX hZ,
    condEntropy_eq_kernel_entropy hY hZ, condMutualInformation_eq_kernel_mutualInfo hY hX hZ,
    condEntropy_eq_kernel_entropy ?_ hZ]
  swap; · exact hX.sub hY
  rw [kernel.entropy_congr (condEntropyKernel_snd_ae_eq hY hX hZ μ).symm,
    kernel.entropy_congr (condEntropyKernel_fst_ae_eq hY hX hZ μ).symm,
    max_comm]
  refine (kernel.ent_of_diff_lower _ _ ).trans_eq ?_
  rw [kernel.entropy_sub_comm]
  have h := condEntropyKernel_comp (hY.prod_mk hX) hZ μ (fun x ↦ x.2 - x.1)
  rw [kernel.entropy_congr h.symm]
  rfl

/-- If $X,Y$ are independent, then
$$ \max(H[X], H[Y]) \leq H[X + Y].$$ -/
lemma ent_of_indep_sum_lower {Y : Ω → G} (hX : Measurable X) (hY : Measurable Y)
    (h : IndepFun X Y μ) :
    (max H[X; μ] H[Y; μ]) ≤ H[X + Y; μ] := by sorry

/--  If $X,Y$ are independent, then
$$ \max(H[X], H[Y]) \leq H[X - Y].$$ -/
lemma ent_of_indep_diff_lower  {X : Ω → G} {Y : Ω → G} (hX : Measurable X) (hY : Measurable Y)
    (h : IndepFun X Y μ) : (max H[X; μ] H[Y; μ]) ≤ H[X - Y; μ] := by
  have : IndepFun X (-Y) μ := h.comp measurable_id measurable_neg
  convert ent_of_indep_sum_lower hX hY.neg this using 2
  · exact (entropy_neg hY).symm
  · ext x; simp [sub_eq_add_neg]

/-- The Ruzsa distance `dist X Y` between two random variables is defined as
$H[X'-Y'] - H[X']/2 - H[Y']/2$, where $X',Y'$ are independent copies of $X, Y$. -/
noncomputable
def rdist (X : Ω → G) (Y : Ω' → G) (μ : Measure Ω := by volume_tac)
    (μ' : Measure Ω' := by volume_tac) : ℝ :=
  H[fun x ↦ x.1 - x.2 ; (μ.map X).prod (μ'.map Y)] - H[X ; μ]/2 - H[Y ; μ']/2

/-- Needed a new separator here, chose `#` arbitrarily, but am open to other suggestions -/
notation3:max "d[" X " ; " μ " # " Y " ; " μ' "]" => rdist X Y μ μ'


lemma rdist_def (X : Ω → G) (Y : Ω' → G) (μ : Measure Ω) (μ' : Measure Ω') :
    d[ X ; μ # Y ; μ' ]
      = H[fun x ↦ x.1 - x.2 ; (μ.map X).prod (μ'.map Y)] - H[X ; μ]/2 - H[Y ; μ']/2 := rfl

-- may also want to make further notations for Ruzsa distance

/-- If $X',Y'$ are copies of $X,Y$ respectively then $d[X';Y']=d[X;Y]$. -/
lemma ProbabilityTheory.IdentDistrib.rdist_eq {X' : Ω'' → G} {Y' : Ω''' →G}
    (hX : IdentDistrib X X' μ μ'') (hY : IdentDistrib Y Y' μ' μ''') :
    d[X ; μ # Y ; μ'] = d[X' ; μ'' # Y' ; μ'''] := by
  simp [rdist, hX.map_eq, hY.map_eq, hX.entropy_eq, hY.entropy_eq]

/--   If $X,Y$ are independent $G$-random variables then
  $$ d[X;Y] := H[X - Y] - H[X]/2 - H[Y]/2.$$-/
lemma ProbabilityTheory.IndepFun.rdist_eq [IsFiniteMeasure μ]
    {Y : Ω → G} (h : IndepFun X Y μ) (hX : Measurable X) (hY : Measurable Y) :
    d[X ; μ # Y ; μ] = H[X-Y ; μ] - H[X ; μ]/2 - H[Y ; μ]/2 := by
  rw [rdist_def]
  congr 2
  have h_prod : (μ.map X).prod (μ.map Y) = μ.map (⟨ X, Y ⟩) :=
    ((indepFun_iff_map_prod_eq_prod_map_map hX hY).mp h).symm
  rw [h_prod, entropy_def, Measure.map_map (measurable_fst.sub measurable_snd) (hX.prod_mk hY)]
  rfl

/-- $$ d[X;Y] = d[Y;X].$$ -/
lemma rdist_symm [IsFiniteMeasure μ] [IsFiniteMeasure μ'] :
    d[ X ; μ # Y ; μ'] = d[ Y ; μ' # X ; μ] := by
  rw [rdist_def, rdist_def, sub_sub, sub_sub, add_comm]
  congr 1
  rw [← entropy_neg (measurable_fst.sub measurable_snd)]
  have : (-fun x : G × G ↦ x.1 - x.2) = (fun x ↦ x.1 - x.2) ∘ Prod.swap := by ext; simp
  rw [this, entropy_def, ← Measure.map_map (measurable_fst.sub measurable_snd) measurable_swap,
    Measure.prod_swap]
  rfl

/-- $$|H[X]-H[Y]| \leq 2 d[X;Y].$$ -/
lemma diff_ent_le_rdist : |H[X ; μ] - H[Y ; μ']| ≤ 2 * d[X ; μ # Y ; μ' ] := by sorry

/-- $$  H[X-Y] - H[X] \leq 2d[X;Y].$$ -/
lemma diff_ent_le_rdist' {Y : Ω → G} (h : IndepFun X Y μ) : H[X-Y; μ] - H[X; μ] ≤ 2 * d[X ; μ # Y ; μ ] := by sorry

/-- $$  H[X-Y] - H[Y] \leq 2d[X;Y].$$ -/
lemma diff_ent_le_rdist'' {Y : Ω → G} (h : IndepFun X Y μ) : H[X-Y; μ] - H[X; μ] ≤ 2 * d[X ; μ # Y ; μ ] := by sorry

/--   $$ d[X;Y] \geq 0.$$  -/
lemma rdist_nonneg : 0 ≤ d[ X ; μ # Y ; μ' ] := by
  linarith [ge_trans diff_ent_le_rdist (abs_nonneg (H[X; μ] - H[Y; μ']))]

/-- The improved Ruzsa triangle inequality -/
lemma ent_of_diff_le (X : Ω → G) (Y : Ω → G) (Z : Ω → G) (h : IndepFun (⟨ X, Z ⟩) Y μ):
    H[ X - Z; μ] ≤ H[ X - Y; μ] + H[ Y - Z; μ] - H[ Y; μ ]:= by sorry

/-- The Ruzsa triangle inequality -/
lemma rdist_triangle (X : Ω → G) (Y : Ω' → G) (Z : Ω'' → G) :
    d[ X ; μ # Z ; μ'' ] ≤ d[ X ; μ # Y ; μ' ] + d[ Y ; μ' # Z ; μ'' ] := sorry

/-- definition of d[ X|Z ; Y| W ]-/
def cond_rdist [MeasurableSpace S] [MeasurableSpace T] (X : Ω → G) (Z : Ω → S) (Y : Ω' → G) (W : Ω' → T) (μ : Measure Ω := by volume_tac) (μ' : Measure Ω' := by volume_tac): ℝ := sorry

notation3:max "d[" X " | " Z "; " μ " # " Y " | " W "; " μ'"]" => cond_rdist X Z Y W μ μ'

/-- definition of d[ X ; Y| W ]-/
def cond_rdist' [MeasurableSpace T] (X : Ω → G) (Y : Ω' → G) (W : Ω' → T) (μ : Measure Ω := by volume_tac) (μ' : Measure Ω' := by volume_tac): ℝ := sorry

notation3:max "d[" X "; " μ " # " Y " | " W "; " μ' "]" => cond_rdist' X Y W μ μ'



/-- $$  d[X  | Z;Y | W] = H[X'-Y'|Z',W'] - H[X'|Z']/2 - H[Y'|W']/2$$ -/
lemma cond_rdist_of_indep [MeasurableSpace S] [MeasurableSpace T]
    {X : Ω → G} {Z : Ω → S} {Y : Ω → G} {W : Ω → T} (h : IndepFun (⟨X, Z⟩) (⟨ Y, W ⟩) μ) :
    d[ X | Z ; μ # Y | W ; μ] = H[X-Y | ⟨ Z, W ⟩; μ ] - H[X | Z; μ ]/2 - H[Y | W; μ ]/2 := by sorry

lemma cond_rdist'_of_indep  [MeasurableSpace T] {X : Ω → G} {Y : Ω → G} {W : Ω → T} (h : IndepFun X (⟨ Y, W ⟩) μ) : d[ X ; μ # Y | W ; μ] = H[X-Y | W; μ ] - H[X; μ ]/2 - H[Y | W; μ ]/2 := by sorry

lemma cond_rdist_of_copy [MeasurableSpace S] [MeasurableSpace T] {X : Ω → G} {Z : Ω → S} {Y : Ω' → G} {W : Ω' → T} {X' : Ω'' → G} {Z' : Ω'' → S} {Y' : Ω''' → G} {W' : Ω''' → T} (h1 : IdentDistrib (⟨X, Z⟩) (⟨X', Z'⟩) μ μ'') (h2: IdentDistrib (⟨Y, W⟩) (⟨Y', W'⟩) μ' μ'''): d[ X | Z ; μ # Y | W ; μ'] = d[ X' | Z' ; μ'' # Y' | W' ; μ'''] := by rfl

lemma cond_rdist'_of_copy [MeasurableSpace T] {X : Ω → G} {Y : Ω' → G} {W : Ω' → T} {X' : Ω'' → G} {Y' : Ω''' → G} {W' : Ω''' → T} (h1 : IdentDistrib X X' μ μ'') (h2: IdentDistrib (⟨Y, W⟩) (⟨Y', W'⟩) μ' μ'''): d[ X ; μ # Y | W ; μ'] = d[ X' ; μ'' # Y' | W' ; μ'''] := by rfl


/-- H[X + Y + Z] - H[X + Y] \leq H[Y+Z] - H[Y]. -/
lemma Kaimonovich_Vershik {X : Fin 3 → Ω → G} (h: iIndepFun (fun (i : Fin 3) ↦ hG) X μ) :
    H[ (X 0) + (X 1) + (X 2) ; μ] - H[ (X 0) + (X 1) ; μ] ≤ H[ (X 1) + (X 2) ; μ] - H[ X 1; μ ] := by sorry

section Balog_Szemeredi_Gowers

/--  Let $A,B$ be $G$-valued random variables on $\Omega$, and set $Z \coloneq A+B$.
Then $$ \sum_{z} P[Z=z] d[(A | Z = z); (B | Z = z)] \leq 3 I[A:B] + 2 H[Z] - H[A] - H[B]. $$ -/
lemma ent_bsg : 0 = 1 := by sorry


end Balog_Szemeredi_Gowers


/--   Suppose that $(X, Z)$ and $(Y, W)$ are random variables, where $X, Y$ take values in an abelian group. Then
$$   d[X  | Z;Y | W] \leq d[X; Y] + \tfrac{1}{2} I[X : Z] + \tfrac{1}{2} I[Y : W].$$
-/
lemma condDist_le [Fintype S] [Fintype T] (X : Ω → G) (Z : Ω → S) (Y : Ω' → G) (W : Ω' → T) : d[ X | Z; μ # Y|W; μ'] ≤ d[X; μ # Y; μ'] + I[ X : Z; μ]/2 + I[Y : W; μ']/2 := by sorry

lemma condDist_le' [Fintype T] (X : Ω → G) (Y : Ω' → G) (W : Ω' → T) : d[ X; μ # Y|W; μ'] ≤ d[X; μ # Y; μ'] + I[Y : W; μ']/2 := by sorry


/-- Let $X, Y, Z$ be random variables taking values in some abelian group, and with $Y, Z$ independent. Then we have
  $$ d[X; Y + Z] -d[X; Y]  \leq \tfrac{1}{2} (H[Y+Z] - H[Y]) $$
  $$ = \tfrac{1}{2} d[Y; Z] + \tfrac{1}{4} H[Z] - \tfrac{1}{4} H[Y]$$
  and
$$
  d[X;Y|Y+Z] - d[X;Y] \leq \tfrac{1}{2} \bigl(H[Y+Z] - H[Z]\bigr) $$
   = \tfrac{1}{2} d[Y;Z] + \tfrac{1}{4} H[Y] - \tfrac{1}{4} H[Z].
-/
lemma condDist_diff_le (X : Ω → G) (Y : Ω' → G) (Z : Ω' → G) (h: IndepFun Y Z μ') : d[ X; μ # Y+Z; μ'] - d[X; μ # Y; μ'] ≤ (H[Y+Z; μ'] - H[Y; μ'])/2 := by sorry

lemma condDist_diff_le' (X : Ω → G) (Y : Ω' → G) (Z : Ω' → G) (h: IndepFun Y Z μ') : d[ X; μ # Y+Z; μ'] - d[X; μ # Y; μ'] ≤ d[Y;μ' # Z; μ']/2 + H[Z; μ']/4 - H[Y; μ']/4 := by sorry

lemma condDist_diff_le'' (X : Ω → G) (Y : Ω' → G) (Z : Ω' → G) (h: IndepFun Y Z μ') : d[ X; μ # Y|Y+Z; μ'] - d[X; μ # Y; μ'] ≤ (H[Y+Z; μ'] - H[Z; μ'])/2 := by sorry

lemma condDist_diff_le''' (X : Ω → G) (Y : Ω' → G) (Z : Ω' → G) (h: IndepFun Y Z μ') : d[ X; μ # Y|Y+Z; μ'] - d[X; μ # Y; μ'] ≤ d[Y;μ' # Z; μ']/2 + H[Y; μ']/4 - H[Z; μ']/4 := by sorry


/--   Let $X, Y, Z, Z'$ be random variables taking values in some abelian group, and with $Y, Z, Z'$ independent. Then we have
$$ d[X;Y + Z | Y + Z + Z'] - d[X;Y] $$
$$ \leq \tfrac{1}{2} ( H[Y + Z + Z'] + H[Y + Z] - H[Y] - H[Z']).$$
-/
lemma condDist_diff_ofsum_le : 0 = 1 := by sorry
