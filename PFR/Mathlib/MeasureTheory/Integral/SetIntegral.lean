import Mathlib.MeasureTheory.Integral.SetIntegral

open scoped ENNReal

namespace MeasureTheory
variable {α E : Type*} [MeasurableSpace α] [NormedAddCommGroup E] [NormedSpace ℝ E]
lemma integral_eq_setIntegral {μ : Measure α} {s : Set α} (hs : μ sᶜ = 0) (f : α → E) :
    ∫ x, f x ∂μ = ∫ x in s, f x ∂μ := by
  rw [← setIntegral_univ, ← setIntegral_congr_set]; rwa [ae_eq_univ]

variable [MeasurableSingletonClass α] [CompleteSpace E]

lemma setIntegral_eq_sum (μ : Measure α) [IsFiniteMeasure μ] (s : Finset α) (f : α → E) :
    ∫ x in s, f x ∂μ = ∑ x ∈ s, (μ {x}).toReal • f x := by
  refine integral_finset _ _ $ IntegrableOn.integrable ?_
  observe : s = ⋃ x ∈ s, {x}
  simp [this, integrableOn_finset_iUnion, measure_lt_top]

end MeasureTheory
