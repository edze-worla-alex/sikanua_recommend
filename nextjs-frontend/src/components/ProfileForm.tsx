"use client";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ChevronLeft, ChevronRight, Check } from "lucide-react";
import { useSikanuaStore } from "@/store";
import { UserProfile, HealthConditions } from "@/types";

// ── Helpers ──────────────────────────────────────────────────────────────────

const Select = ({
  label, value, onChange, options,
}: {
  label: string;
  value: string | number;
  onChange: (v: string) => void;
  options: { value: string | number; label: string }[];
}) => (
  <label className="flex flex-col gap-1.5">
    <span className="text-xs font-semibold text-ink/70 uppercase tracking-wider">{label}</span>
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="bg-white border border-forest-light rounded-xl px-3 py-2.5 text-sm
                 text-ink focus:outline-none focus:ring-2 focus:ring-forest/30 cursor-pointer"
    >
      {options.map((o) => (
        <option key={o.value} value={o.value}>{o.label}</option>
      ))}
    </select>
  </label>
);

const NumberInput = ({
  label, value, onChange, min, max, unit,
}: {
  label: string; value: number; onChange: (v: number) => void;
  min: number; max: number; unit?: string;
}) => (
  <label className="flex flex-col gap-1.5">
    <span className="text-xs font-semibold text-ink/70 uppercase tracking-wider">{label}</span>
    <div className="relative">
      <input
        type="number" min={min} max={max} value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        className="bg-white border border-forest-light rounded-xl px-3 py-2.5 text-sm
                   text-ink w-full focus:outline-none focus:ring-2 focus:ring-forest/30"
      />
      {unit && (
        <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-ink/40">{unit}</span>
      )}
    </div>
  </label>
);

const Toggle = ({
  label, value, onChange,
}: {
  label: string; value: boolean; onChange: (v: boolean) => void;
}) => (
  <button
    onClick={() => onChange(!value)}
    className={`flex items-center gap-2 px-3 py-2 rounded-xl border text-xs font-medium
                transition-all cursor-pointer ${
                  value
                    ? "bg-forest text-white border-forest"
                    : "bg-white text-ink/70 border-forest-light hover:border-forest/40"
                }`}
  >
    {value && <Check className="w-3 h-3 flex-shrink-0" />}
    {label}
  </button>
);

// ── Step definitions ──────────────────────────────────────────────────────────

const STEPS = ["About You", "Goals", "Diet", "Fitness", "Health"];

const defaultProfile: UserProfile = {
  age: 28, sex: "female", height_cm: 165, weight_kg: 68,
  activity_level: "moderately_active", goal: "general_health",
  diet_style: "omnivore", meals_per_day: 3, cooking_skill: "beginner",
  training_days: 3, session_duration: "medium", budget: "moderate",
  equipment_access: "home", exercise_history: "beginner",
  health_conditions: {},
  stress_level: 4, sleep_hours: 7, water_litres: 2,
};

const CONDITIONS: { key: keyof HealthConditions; label: string }[] = [
  { key: "diabetes",                  label: "Diabetes" },
  { key: "hypertension",              label: "Hypertension" },
  { key: "ckd",                       label: "Kidney Disease" },
  { key: "celiac",                    label: "Celiac / Gluten-Free" },
  { key: "ibs",                       label: "IBS" },
  { key: "pcos",                      label: "PCOS" },
  { key: "cardiac_history",           label: "Heart Condition" },
  { key: "osteoporosis",              label: "Osteoporosis" },
  { key: "eating_disorder_recovery",  label: "ED Recovery" },
  { key: "thyroid_condition",         label: "Thyroid Condition" },
  { key: "high_cholesterol",          label: "High Cholesterol" },
];

// ── Main Component ────────────────────────────────────────────────────────────

export default function ProfileForm() {
  const { setProfile, setStep, addMessage, profile } = useSikanuaStore();
  const [current, setCurrent] = useState(0);
  const [form, setForm] = useState<UserProfile>({ ...defaultProfile, ...profile });
  const [direction, setDirection] = useState(1);

  const update = (key: keyof UserProfile, value: unknown) =>
    setForm((f) => ({ ...f, [key]: value }));

  const toggleCondition = (key: keyof HealthConditions) =>
    setForm((f) => ({
      ...f,
      health_conditions: {
        ...f.health_conditions,
        [key]: !f.health_conditions[key],
      },
    }));

  const go = (dir: number) => {
    setDirection(dir);
    setCurrent((c) => Math.max(0, Math.min(STEPS.length - 1, c + dir)));
  };

  const handleSubmit = () => {
    setProfile(form);
    // Pre-seed the chat with the profile as a system message
    addMessage({
      id:        `msg-${Date.now()}`,
      role:      "user",
      content:   "Generate my personalised 7-day nutrition and fitness plan based on my profile:\n\n```json\n" + JSON.stringify(form, null, 2) + "\n```",
      timestamp: new Date(),
    });
    setStep("chat");
  };

  const variants = {
    enter: (d: number) => ({ opacity: 0, x: d > 0 ? 40 : -40 }),
    center: { opacity: 1, x: 0 },
    exit:  (d: number) => ({ opacity: 0, x: d > 0 ? -40 : 40 }),
  };

  const stepContent = [
    // Step 0 — About You
    <div key="about" className="grid grid-cols-2 gap-4">
      <NumberInput label="Age" value={form.age} onChange={(v) => update("age", v)} min={16} max={99} unit="yrs" />
      <Select label="Sex" value={form.sex} onChange={(v) => update("sex", v)}
        options={[{ value: "female", label: "Female" }, { value: "male", label: "Male" }, { value: "other", label: "Other" }]} />
      <NumberInput label="Height" value={form.height_cm} onChange={(v) => update("height_cm", v)} min={130} max={220} unit="cm" />
      <NumberInput label="Weight" value={form.weight_kg} onChange={(v) => update("weight_kg", v)} min={30} max={250} unit="kg" />
      <NumberInput label="Sleep" value={form.sleep_hours ?? 7} onChange={(v) => update("sleep_hours", v)} min={3} max={12} unit="hrs" />
      <NumberInput label="Stress Level" value={form.stress_level ?? 5} onChange={(v) => update("stress_level", v)} min={0} max={10} unit="/10" />
    </div>,

    // Step 1 — Goals
    <div key="goals" className="grid grid-cols-2 gap-4">
      <div className="col-span-2">
        <Select label="Primary Goal" value={form.goal} onChange={(v) => update("goal", v)}
          options={[
            { value: "weight_loss",    label: "Weight Loss" },
            { value: "maintenance",    label: "Maintain Weight" },
            { value: "muscle_gain",    label: "Build Muscle" },
            { value: "performance",    label: "Athletic Performance" },
            { value: "general_health", label: "General Health" },
          ]} />
      </div>
      <Select label="Activity Level" value={form.activity_level} onChange={(v) => update("activity_level", v)}
        options={[
          { value: "sedentary",          label: "Sedentary" },
          { value: "lightly_active",     label: "Lightly Active" },
          { value: "moderately_active",  label: "Moderately Active" },
          { value: "very_active",        label: "Very Active" },
          { value: "athlete",            label: "Athlete" },
        ]} />
      <Select label="Budget" value={form.budget} onChange={(v) => update("budget", v)}
        options={[
          { value: "low",      label: "Low" },
          { value: "moderate", label: "Moderate" },
          { value: "high",     label: "High" },
        ]} />
    </div>,

    // Step 2 — Diet
    <div key="diet" className="grid grid-cols-2 gap-4">
      <div className="col-span-2">
        <Select label="Dietary Style" value={form.diet_style} onChange={(v) => update("diet_style", v)}
          options={[
            { value: "omnivore",       label: "Omnivore" },
            { value: "vegetarian",     label: "Vegetarian" },
            { value: "vegan",          label: "Vegan" },
            { value: "pescatarian",    label: "Pescatarian" },
            { value: "keto",           label: "Ketogenic" },
            { value: "mediterranean",  label: "Mediterranean" },
            { value: "halal",          label: "Halal" },
            { value: "kosher",         label: "Kosher" },
          ]} />
      </div>
      <NumberInput label="Meals per Day" value={form.meals_per_day} onChange={(v) => update("meals_per_day", v)} min={2} max={6} />
      <Select label="Cooking Skill" value={form.cooking_skill} onChange={(v) => update("cooking_skill", v)}
        options={[
          { value: "none",         label: "I don't cook" },
          { value: "beginner",     label: "Beginner" },
          { value: "intermediate", label: "Intermediate" },
          { value: "advanced",     label: "Advanced" },
        ]} />
      <NumberInput label="Daily Water" value={form.water_litres ?? 2} onChange={(v) => update("water_litres", v)} min={0.5} max={5} unit="L" />
    </div>,

    // Step 3 — Fitness
    <div key="fitness" className="grid grid-cols-2 gap-4">
      <NumberInput label="Training Days / Week" value={form.training_days} onChange={(v) => update("training_days", v)} min={1} max={7} />
      <Select label="Session Duration" value={form.session_duration} onChange={(v) => update("session_duration", v)}
        options={[
          { value: "short",    label: "< 20 min" },
          { value: "medium",   label: "20–45 min" },
          { value: "long",     label: "45–75 min" },
          { value: "extended", label: "75+ min" },
        ]} />
      <Select label="Equipment" value={form.equipment_access} onChange={(v) => update("equipment_access", v)}
        options={[
          { value: "none",     label: "No equipment" },
          { value: "home",     label: "Home gym" },
          { value: "full_gym", label: "Full gym" },
          { value: "outdoor",  label: "Outdoor only" },
        ]} />
      <Select label="Experience" value={form.exercise_history} onChange={(v) => update("exercise_history", v)}
        options={[
          { value: "none",         label: "Never trained" },
          { value: "beginner",     label: "Beginner" },
          { value: "intermediate", label: "Intermediate" },
          { value: "advanced",     label: "Advanced" },
        ]} />
    </div>,

    // Step 4 — Health
    <div key="health" className="space-y-3">
      <p className="text-xs text-ink/60 leading-relaxed">
        Select any conditions that apply. Your plan will automatically
        adjust to honour clinical guidelines for each.
      </p>
      <div className="flex flex-wrap gap-2">
        {CONDITIONS.map(({ key, label }) => (
          <Toggle
            key={key}
            label={label}
            value={!!form.health_conditions[key]}
            onChange={() => toggleCondition(key)}
          />
        ))}
      </div>
    </div>,
  ];

  return (
    <div className="min-h-screen flex items-center justify-center px-6 py-12">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-white rounded-3xl shadow-xl border border-forest-light w-full max-w-lg overflow-hidden"
      >
        {/* Header */}
        <div className="bg-forest px-6 pt-6 pb-8">
          <h2 className="font-display text-white text-xl font-bold mb-4">
            {STEPS[current]}
          </h2>
          {/* Progress bar */}
          <div className="flex gap-1.5">
            {STEPS.map((_, i) => (
              <div
                key={i}
                className={`h-1 rounded-full flex-1 transition-all duration-300 ${
                  i <= current ? "bg-amber" : "bg-white/20"
                }`}
              />
            ))}
          </div>
          <p className="text-white/60 text-xs mt-2">
            Step {current + 1} of {STEPS.length}
          </p>
        </div>

        {/* Form area */}
        <div className="px-6 py-6 min-h-[240px] overflow-hidden">
          <AnimatePresence mode="wait" custom={direction}>
            <motion.div
              key={current}
              custom={direction}
              variants={variants}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ duration: 0.25, ease: "easeInOut" }}
            >
              {stepContent[current]}
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Navigation */}
        <div className="px-6 pb-6 flex items-center justify-between">
          <button
            onClick={() => current === 0 ? setStep("welcome") : go(-1)}
            className="flex items-center gap-1.5 text-sm text-ink/60 hover:text-ink transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
            {current === 0 ? "Back" : "Previous"}
          </button>

          {current < STEPS.length - 1 ? (
            <motion.button
              whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}
              onClick={() => go(1)}
              className="flex items-center gap-2 bg-forest text-white text-sm font-semibold
                         px-5 py-2.5 rounded-full shadow-md shadow-forest/20 hover:bg-forest-dark transition-colors"
            >
              Next <ChevronRight className="w-4 h-4" />
            </motion.button>
          ) : (
            <motion.button
              whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}
              onClick={handleSubmit}
              className="flex items-center gap-2 bg-amber text-ink text-sm font-bold
                         px-6 py-2.5 rounded-full shadow-md shadow-amber/30 hover:bg-amber/90 transition-colors"
            >
              Generate My Plan ✨
            </motion.button>
          )}
        </div>
      </motion.div>
    </div>
  );
}
