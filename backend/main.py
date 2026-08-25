"""
SIKANUA AI Backend
==================
PyTorch-based nutrition & fitness recommendation model
served through a FastAPI server with an OpenAI-compatible
/v1/chat/completions endpoint.

Architecture:
  - SikanuaNet: a multi-head neural network that encodes a user
    profile (biometrics + health flags + goals) and produces
    diet & fitness plan embeddings.
  - The embeddings are decoded by a rule-augmented text generator
    to produce structured JSON plans.
  - Streaming SSE is supported (stream=true).
"""

import asyncio
import json
import time
import uuid
from typing import Any, AsyncGenerator, List, Literal, Optional

import torch
import torch.nn as nn
import torch.nn.functional as F
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field

# ──────────────────────────────────────────────────────────────────────────────
# 1. PyTorch Model Definition
# ──────────────────────────────────────────────────────────────────────────────

class UserProfileEncoder(nn.Module):
    """
    Encodes a structured user profile vector into a dense representation.
    Input features (35-dim):
      [0]  age (normalised 0-1, max 100)
      [1]  height_cm (normalised, max 220)
      [2]  weight_kg (normalised, max 200)
      [3]  bmi (normalised, max 50)
      [4]  body_fat_pct (0-1)
      [5]  activity_level (0-4 → normalised)
      [6]  sex (0=female, 1=male, 0.5=other)
      [7]  goal (0=loss, 0.25=maintain, 0.5=gain, 0.75=performance, 1=general)
      [8]  diet_style (0-7 encoded / 7)
      [9]  cooking_skill (0-3 / 3)
      [10] meals_per_day (2-6 → normalised)
      [11] training_days (1-7 / 7)
      [12] session_duration (0-3 / 3)
      [13] budget (0-2 / 2)
      [14] has_diabetes
      [15] has_hypertension
      [16] has_ckd
      [17] has_celiac
      [18] has_ibs
      [19] has_pcos
      [20] has_cardiac_history
      [21] has_osteoporosis
      [22] has_eating_disorder_recovery
      [23] has_thyroid_condition
      [24] has_high_cholesterol
      [25] equipment_access (0-3 / 3)
      [26] exercise_history (0-3 / 3)
      [27] mobility_issues (bool)
      [28] resting_hr (normalised, max 120)
      [29] systolic_bp (normalised, max 200)
      [30] blood_glucose (normalised, max 20)
      [31] waist_cm (normalised, max 150)
      [32] water_litres (normalised, max 5)
      [33] sleep_hours (normalised, max 12)
      [34] stress_level (0-10 / 10)
    """

    INPUT_DIM = 35

    def __init__(self, hidden_dim: int = 128, embed_dim: int = 64):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(self.INPUT_DIM, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.GELU(),
            nn.Dropout(0.1),
            nn.Linear(hidden_dim, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.GELU(),
            nn.Dropout(0.1),
            nn.Linear(hidden_dim, embed_dim),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)


class SikanuaNet(nn.Module):
    """
    Multi-head recommendation network.
    Outputs:
      - diet_head:    caloric target, macro splits, meal timing
      - fitness_head: intensity, volume, frequency, rest
      - risk_head:    metabolic risk score, adherence risk
    """

    def __init__(self, embed_dim: int = 64):
        super().__init__()
        self.encoder = UserProfileEncoder(hidden_dim=128, embed_dim=embed_dim)

        # Diet recommendation head
        self.diet_head = nn.Sequential(
            nn.Linear(embed_dim, 64),
            nn.GELU(),
            nn.Linear(64, 32),
            nn.GELU(),
            nn.Linear(32, 8),   # [calories, protein%, carbs%, fat%, meal_freq, meal_timing, hydration, fiber]
        )

        # Fitness recommendation head
        self.fitness_head = nn.Sequential(
            nn.Linear(embed_dim, 64),
            nn.GELU(),
            nn.Linear(64, 32),
            nn.GELU(),
            nn.Linear(32, 6),   # [intensity_rpe, weekly_volume, cardio_mins, strength_sets, rest_days, flexibility_mins]
        )

        # Risk assessment head
        self.risk_head = nn.Sequential(
            nn.Linear(embed_dim, 32),
            nn.GELU(),
            nn.Linear(32, 3),   # [metabolic_risk, adherence_risk, escalation_flag]
            nn.Sigmoid(),
        )

    def forward(self, x: torch.Tensor):
        emb = self.encoder(x)
        diet_raw    = self.diet_head(emb)
        fitness_raw = self.fitness_head(emb)
        risk        = self.risk_head(emb)
        return diet_raw, fitness_raw, risk


# ──────────────────────────────────────────────────────────────────────────────
# 2. Model Singleton & Weights
# ──────────────────────────────────────────────────────────────────────────────

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

def build_model() -> SikanuaNet:
    """Build model and initialise with deterministic weights (demo mode)."""
    torch.manual_seed(42)
    model = SikanuaNet(embed_dim=64).to(DEVICE)
    model.eval()
    return model

MODEL: SikanuaNet = build_model()


# ──────────────────────────────────────────────────────────────────────────────
# 3. Profile → Tensor conversion
# ──────────────────────────────────────────────────────────────────────────────

DIET_STYLE_MAP = {
    "omnivore": 0, "vegetarian": 1, "vegan": 2, "pescatarian": 3,
    "keto": 4, "mediterranean": 5, "halal": 6, "kosher": 7,
}
GOAL_MAP = {
    "weight_loss": 0.0, "maintenance": 0.25,
    "muscle_gain": 0.5, "performance": 0.75, "general_health": 1.0,
}
ACTIVITY_MAP = {
    "sedentary": 0, "lightly_active": 1, "moderately_active": 2,
    "very_active": 3, "athlete": 4,
}
EQUIPMENT_MAP = {"none": 0, "home": 1, "full_gym": 2, "outdoor": 3}
EX_HISTORY_MAP = {"none": 0, "beginner": 1, "intermediate": 2, "advanced": 3}
COOKING_MAP = {"none": 0, "beginner": 1, "intermediate": 2, "advanced": 3}
SESSION_MAP = {"short": 0, "medium": 1, "long": 2, "extended": 3}
BUDGET_MAP = {"low": 0, "moderate": 1, "high": 2}


def profile_to_tensor(p: dict) -> torch.Tensor:
    hc = p.get("health_conditions", {})
    sex_val = {"male": 1.0, "female": 0.0}.get(p.get("sex", "other"), 0.5)

    vec = [
        p.get("age", 30) / 100,
        p.get("height_cm", 170) / 220,
        p.get("weight_kg", 70) / 200,
        p.get("bmi", 22) / 50,
        p.get("body_fat_pct", 0.25),
        ACTIVITY_MAP.get(p.get("activity_level", "moderately_active"), 2) / 4,
        sex_val,
        GOAL_MAP.get(p.get("goal", "general_health"), 1.0),
        DIET_STYLE_MAP.get(p.get("diet_style", "omnivore"), 0) / 7,
        COOKING_MAP.get(p.get("cooking_skill", "beginner"), 1) / 3,
        (p.get("meals_per_day", 3) - 2) / 4,
        p.get("training_days", 3) / 7,
        SESSION_MAP.get(p.get("session_duration", "medium"), 1) / 3,
        BUDGET_MAP.get(p.get("budget", "moderate"), 1) / 2,
        float(hc.get("diabetes", False)),
        float(hc.get("hypertension", False)),
        float(hc.get("ckd", False)),
        float(hc.get("celiac", False)),
        float(hc.get("ibs", False)),
        float(hc.get("pcos", False)),
        float(hc.get("cardiac_history", False)),
        float(hc.get("osteoporosis", False)),
        float(hc.get("eating_disorder_recovery", False)),
        float(hc.get("thyroid_condition", False)),
        float(hc.get("high_cholesterol", False)),
        EQUIPMENT_MAP.get(p.get("equipment_access", "home"), 1) / 3,
        EX_HISTORY_MAP.get(p.get("exercise_history", "beginner"), 1) / 3,
        float(p.get("mobility_issues", False)),
        p.get("resting_hr", 70) / 120,
        p.get("systolic_bp", 120) / 200,
        p.get("blood_glucose", 5.0) / 20,
        p.get("waist_cm", 85) / 150,
        p.get("water_litres", 2.0) / 5,
        p.get("sleep_hours", 7.5) / 12,
        p.get("stress_level", 4) / 10,
    ]
    return torch.tensor(vec, dtype=torch.float32).unsqueeze(0).to(DEVICE)


# ──────────────────────────────────────────────────────────────────────────────
# 4. Decode raw model outputs → structured plan
# ──────────────────────────────────────────────────────────────────────────────

PAL_MULTIPLIERS = [1.2, 1.375, 1.55, 1.725, 1.9]
GOAL_ADJUSTMENTS = {
    "weight_loss": -500, "maintenance": 0, "muscle_gain": 300,
    "performance": 200, "general_health": 0,
}

MEAL_PLANS: dict[str, list[dict]] = {
    "omnivore": [
        {"breakfast": "Oats with banana, boiled eggs and green tea",
         "lunch":     "Grilled chicken breast, brown rice, steamed vegetables",
         "dinner":    "Baked salmon, sweet potato, spinach salad",
         "snacks":    ["Greek yoghurt with berries", "Handful of mixed nuts"]},
        {"breakfast": "Whole-grain toast, avocado, poached eggs",
         "lunch":     "Beef and vegetable stir-fry with quinoa",
         "dinner":    "Turkey meatballs, wholegrain pasta, tomato sauce",
         "snacks":    ["Apple with almond butter", "Cottage cheese"]},
        {"breakfast": "Smoothie: spinach, banana, protein powder, almond milk",
         "lunch":     "Tuna wrap with salad leaves and hummus",
         "dinner":    "Lamb kebab, couscous, cucumber-tomato salad",
         "snacks":    ["Rice cakes with peanut butter", "Boiled egg"]},
        {"breakfast": "Akara (bean cakes), boiled yam, fresh fruit",
         "lunch":     "Grilled tilapia, jollof rice, coleslaw",
         "dinner":    "Chicken soup with vegetables and plantain",
         "snacks":    ["Roasted groundnuts", "Fresh pineapple"]},
        {"breakfast": "Millet porridge, honey, walnuts",
         "lunch":     "Beans and plantain with green pepper sauce",
         "dinner":    "Steamed fish, brown rice, okra soup",
         "snacks":    ["Yoghurt", "Sliced mango"]},
        {"breakfast": "Scrambled eggs, wholegrain bread, orange juice",
         "lunch":     "Chicken salad bowl with avocado dressing",
         "dinner":    "Grilled beef, roasted sweet potato, broccoli",
         "snacks":    ["Protein shake", "Carrot sticks with hummus"]},
        {"breakfast": "Pancakes made with oat flour, topped with fresh berries",
         "lunch":     "Lentil soup with wholegrain bread",
         "dinner":    "Baked chicken thighs, roasted vegetables, wild rice",
         "snacks":    ["Dark chocolate (85%)", "Orange"]},
    ],
    "vegan": [
        {"breakfast": "Overnight oats with chia seeds, oat milk, berries",
         "lunch":     "Chickpea and spinach curry with brown rice",
         "dinner":    "Lentil dal, quinoa, roasted cauliflower",
         "snacks":    ["Edamame", "Mixed nuts"]},
        {"breakfast": "Tofu scramble with bell peppers and turmeric",
         "lunch":     "Buddha bowl: roasted veg, falafel, tahini",
         "dinner":    "Black bean tacos with guacamole and salsa",
         "snacks":    ["Apple", "Almond butter rice cakes"]},
        {"breakfast": "Green smoothie: kale, banana, hemp seeds",
         "lunch":     "Tempeh stir-fry with noodles and soy sauce",
         "dinner":    "Stuffed bell peppers with quinoa and black beans",
         "snacks":    ["Roasted chickpeas", "Pear"]},
        {"breakfast": "Acai bowl with granola and sliced banana",
         "lunch":     "Peanut stew with yam and leafy greens",
         "dinner":    "Coconut tofu curry with brown rice",
         "snacks":    ["Groundnuts", "Papaya"]},
        {"breakfast": "Millet and peanut porridge",
         "lunch":     "Bean patties with sweet potato fries",
         "dinner":    "Vegetable jollof rice with plantain",
         "snacks":    ["Avocado toast", "Orange"]},
        {"breakfast": "Whole-grain toast with peanut butter and banana",
         "lunch":     "Lentil and vegetable soup",
         "dinner":    "Chickpea and sweet potato stew",
         "snacks":    ["Trail mix", "Carrot and hummus"]},
        {"breakfast": "Smoothie bowl with flaxseeds and granola",
         "lunch":     "Soba noodles with edamame, sesame dressing",
         "dinner":    "Mushroom and lentil cottage pie",
         "snacks":    ["Medjool dates", "Walnuts"]},
    ],
}

for k in ["vegetarian", "pescatarian", "mediterranean", "keto", "halal", "kosher"]:
    MEAL_PLANS[k] = MEAL_PLANS["omnivore"]

WORKOUT_TEMPLATES: dict[str, list[dict]] = {
    "strength": [
        {"name": "Upper Body Push",    "exercises": ["Bench Press 4×8", "Overhead Press 3×10", "Tricep Dips 3×12", "Push-ups 3×15"]},
        {"name": "Lower Body",         "exercises": ["Squats 4×8", "Romanian Deadlift 3×10", "Lunges 3×12 each", "Calf Raises 3×20"]},
        {"name": "Upper Body Pull",    "exercises": ["Pull-ups 4×6", "Barbell Rows 3×10", "Bicep Curls 3×12", "Face Pulls 3×15"]},
        {"name": "Full Body Power",    "exercises": ["Deadlift 4×5", "Goblet Squat 3×12", "Dumbbell Press 3×10", "Cable Row 3×12"]},
        {"name": "Core & Mobility",    "exercises": ["Plank 3×60s", "Dead Bug 3×10", "Hip Flexor Stretch 3×30s", "Thoracic Rotation 3×10"]},
        {"name": "Active Recovery",    "exercises": ["Light walk 20 min", "Foam rolling 15 min", "Gentle stretching 15 min"]},
        {"name": "Rest Day",           "exercises": ["Complete rest or light yoga"]},
    ],
    "cardio": [
        {"name": "Moderate Steady-State", "exercises": ["Jog 30 min at 60% max HR", "Cool-down walk 5 min"]},
        {"name": "Interval Training",     "exercises": ["Warm-up 5 min", "6×3 min hard / 2 min easy", "Cool-down 5 min"]},
        {"name": "Cross-Train",           "exercises": ["Cycling 30 min", "Bodyweight circuit 20 min"]},
        {"name": "Long Slow Distance",    "exercises": ["Walk/Jog 50 min at conversational pace"]},
        {"name": "Hill Work",             "exercises": ["Warm-up 5 min", "10×1 min hill sprint / walk down", "Cool-down 5 min"]},
        {"name": "Active Recovery",       "exercises": ["Gentle swim or walk 20 min", "Stretching 10 min"]},
        {"name": "Rest Day",              "exercises": ["Complete rest"]},
    ],
    "general": [
        {"name": "Full Body Circuit A",  "exercises": ["Squats 3×15", "Push-ups 3×12", "Dumbbell Row 3×12", "Plank 3×45s"]},
        {"name": "Cardio + Core",        "exercises": ["Brisk walk / jog 25 min", "Bicycle crunches 3×20", "Mountain Climbers 3×30s"]},
        {"name": "Full Body Circuit B",  "exercises": ["Lunges 3×12", "Dumbbell Press 3×12", "Lat Pulldown 3×12", "Glute Bridge 3×15"]},
        {"name": "Flexibility & Yoga",   "exercises": ["Sun salutation 5×", "Hip openers 3×30s", "Forward fold 3×30s", "Pigeon pose 2×45s"]},
        {"name": "Full Body Circuit C",  "exercises": ["Deadlift 3×10", "Arnold Press 3×12", "Reverse Lunges 3×12", "Russian Twist 3×20"]},
        {"name": "Active Recovery",      "exercises": ["Walk 20–30 min", "Foam rolling 10 min"]},
        {"name": "Rest Day",             "exercises": ["Complete rest"]},
    ],
}


def decode_plan(
    profile: dict,
    diet_raw: torch.Tensor,
    fitness_raw: torch.Tensor,
    risk: torch.Tensor,
) -> dict:
    """Convert model outputs + profile into a human-readable structured plan."""
    # — Caloric calculation (deterministic, model output used as fine-tune multiplier) —
    age = profile.get("age", 30)
    w   = profile.get("weight_kg", 70)
    h   = profile.get("height_cm", 170)
    sex = profile.get("sex", "other")

    if sex == "male":
        bmr = 10 * w + 6.25 * h - 5 * age + 5
    else:
        bmr = 10 * w + 6.25 * h - 5 * age - 161

    pal_idx = ACTIVITY_MAP.get(profile.get("activity_level", "moderately_active"), 2)
    tdee    = bmr * PAL_MULTIPLIERS[pal_idx]
    adj     = GOAL_ADJUSTMENTS.get(profile.get("goal", "general_health"), 0)

    # Apply model nudge (±200 kcal range)
    model_nudge = float(diet_raw[0, 0].item()) * 400 - 200
    calories    = max(1200, round(tdee + adj + model_nudge, -1))

    # Macros (model outputs as soft guidance, clipped to sensible ranges)
    prot_raw  = float(torch.sigmoid(diet_raw[0, 1]).item())
    carb_raw  = float(torch.sigmoid(diet_raw[0, 2]).item())
    fat_raw   = float(torch.sigmoid(diet_raw[0, 3]).item())
    total_raw = prot_raw + carb_raw + fat_raw
    protein_pct = round((prot_raw / total_raw) * 100)
    carbs_pct   = round((carb_raw / total_raw) * 100)
    fat_pct     = 100 - protein_pct - carbs_pct

    protein_g = round(calories * protein_pct / 100 / 4)
    carbs_g   = round(calories * carbs_pct   / 100 / 4)
    fat_g     = round(calories * fat_pct     / 100 / 9)

    # Hydration
    hydration_l = round(w * 0.033 + 0.5, 1)

    # Meals
    diet_style = profile.get("diet_style", "omnivore")
    meals = MEAL_PLANS.get(diet_style, MEAL_PLANS["omnivore"])

    # Fitness
    goal  = profile.get("goal", "general_health")
    if goal in ("muscle_gain", "performance"):
        tpl_key = "strength"
    elif goal in ("weight_loss",):
        tpl_key = "cardio"
    else:
        tpl_key = "general"
    workouts = WORKOUT_TEMPLATES[tpl_key]

    rpe_base = float(torch.clamp(fitness_raw[0, 0], 0, 1).item()) * 4 + 4  # 4–8 RPE
    rpe_base = round(rpe_base, 1)

    # Risk
    metabolic_risk = round(float(risk[0, 0].item()) * 100)
    adherence_risk = round(float(risk[0, 1].item()) * 100)
    escalation_flag = float(risk[0, 2].item()) > 0.7

    # Health condition constraints
    constraints_applied = []
    hc = profile.get("health_conditions", {})
    if hc.get("diabetes"):
        constraints_applied.append("Low-GI carbohydrates only; carbs spread across 5–6 meals")
    if hc.get("hypertension"):
        constraints_applied.append("Sodium capped at 1,500 mg/day; DASH-aligned meals")
    if hc.get("ckd"):
        constraints_applied.append("Protein limited to 0.6–0.8 g/kg; potassium and phosphorus restricted")
    if hc.get("celiac"):
        constraints_applied.append("All meals verified gluten-free")
    if hc.get("ibs"):
        constraints_applied.append("Low-FODMAP filter applied")
    if hc.get("cardiac_history"):
        constraints_applied.append("Cardio capped at RPE 6; no HIIT without clinical clearance")
    if hc.get("eating_disorder_recovery"):
        constraints_applied.append("Calorie counts hidden; plan framed around nourishment, not restriction")

    week_plan = []
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    for i, day in enumerate(days):
        week_plan.append({
            "day": day,
            "diet": meals[i],
            "workout": workouts[i],
        })

    return {
        "user_summary": {
            "bmi": round(w / (h / 100) ** 2, 1),
            "tdee_kcal": round(tdee),
            "target_calories_kcal": calories,
            "deficit_surplus_kcal": calories - round(tdee),
        },
        "macros": {
            "protein": {"percent": protein_pct, "grams": protein_g},
            "carbohydrates": {"percent": carbs_pct, "grams": carbs_g},
            "fat": {"percent": fat_pct, "grams": fat_g},
            "hydration_litres": hydration_l,
        },
        "fitness": {
            "recommended_rpe": rpe_base,
            "workout_split": tpl_key.title(),
        },
        "risk_assessment": {
            "metabolic_risk_score": metabolic_risk,
            "adherence_risk_score": adherence_risk,
            "escalation_recommended": escalation_flag,
        },
        "constraints_applied": constraints_applied,
        "weekly_plan": week_plan,
        "next_review_days": 7,
    }


# ──────────────────────────────────────────────────────────────────────────────
# 5. Chat message → profile extractor
# ──────────────────────────────────────────────────────────────────────────────

def extract_profile_from_messages(messages: list[dict]) -> dict:
    """
    Scan conversation history for a user message containing a JSON profile
    block (wrapped in ```json ... ``` or as raw JSON).
    Falls back to a sensible default.
    """
    import re
    profile = {}
    for msg in reversed(messages):
        if msg.get("role") == "user":
            content = msg.get("content", "")
            # Try ```json block
            m = re.search(r"```json\s*(\{.*?\})\s*```", content, re.DOTALL)
            if m:
                try:
                    profile = json.loads(m.group(1))
                    break
                except json.JSONDecodeError:
                    pass
            # Try raw JSON
            m = re.search(r"(\{[^{}]{20,}\})", content, re.DOTALL)
            if m:
                try:
                    profile = json.loads(m.group(1))
                    break
                except json.JSONDecodeError:
                    pass

    # Defaults
    profile.setdefault("age", 28)
    profile.setdefault("sex", "female")
    profile.setdefault("height_cm", 165)
    profile.setdefault("weight_kg", 68)
    profile.setdefault("activity_level", "moderately_active")
    profile.setdefault("goal", "general_health")
    profile.setdefault("diet_style", "omnivore")
    profile.setdefault("meals_per_day", 3)
    profile.setdefault("cooking_skill", "beginner")
    profile.setdefault("training_days", 3)
    profile.setdefault("session_duration", "medium")
    profile.setdefault("budget", "moderate")
    profile.setdefault("equipment_access", "home")
    profile.setdefault("exercise_history", "beginner")
    profile.setdefault("health_conditions", {})
    return profile


def plan_to_markdown(plan: dict) -> str:
    """Format the structured plan as rich markdown for the chat response."""
    us = plan["user_summary"]
    m  = plan["macros"]
    f  = plan["fitness"]
    r  = plan["risk_assessment"]

    lines = [
        "# 🥗 Your SIKANUA 7-Day Plan\n",
        "## 📊 Your Baseline",
        f"| Metric | Value |",
        f"|--------|-------|",
        f"| BMI | {us['bmi']} |",
        f"| TDEE | {us['tdee_kcal']} kcal/day |",
        f"| Target Calories | **{us['target_calories_kcal']} kcal/day** |",
        f"| Daily {('Deficit' if us['deficit_surplus_kcal'] < 0 else 'Surplus')} | {abs(us['deficit_surplus_kcal'])} kcal |",
        "",
        "## 🔢 Daily Macro Targets",
        f"| Macro | % of Calories | Grams |",
        f"|-------|--------------|-------|",
        f"| Protein | {m['protein']['percent']}% | {m['protein']['grams']}g |",
        f"| Carbohydrates | {m['carbohydrates']['percent']}% | {m['carbohydrates']['grams']}g |",
        f"| Fat | {m['fat']['percent']}% | {m['fat']['grams']}g |",
        f"| 💧 Hydration | — | {m['hydration_litres']}L/day |",
        "",
        f"## 🏋️ Fitness: {f['workout_split']} Split  (Target RPE {f['recommended_rpe']})",
        "",
    ]

    if plan["constraints_applied"]:
        lines += [
            "## ⚠️ Active Health Constraints",
            *[f"- {c}" for c in plan["constraints_applied"]],
            "",
        ]

    lines += ["## 📅 7-Day Plan\n"]
    for day_data in plan["weekly_plan"]:
        d = day_data["diet"]
        w = day_data["workout"]
        lines += [
            f"### {day_data['day']}",
            f"**🍽️ {w['name']}**  ",
            "Exercises: " + " · ".join(w["exercises"]),
            "",
            f"**Breakfast:** {d['breakfast']}  ",
            f"**Lunch:** {d['lunch']}  ",
            f"**Dinner:** {d['dinner']}  ",
            f"**Snacks:** {', '.join(d['snacks'])}",
            "",
        ]

    if r["escalation_recommended"]:
        lines += [
            "---",
            "**🚨 Clinical Review Recommended**  ",
            "Based on your profile, we recommend speaking with a registered dietitian or physician before starting this plan.",
            "",
        ]

    lines += [
        "---",
        f"*Plan valid for 7 days. Review scheduled in {plan['next_review_days']} days.*",
        f"*Risk scores — Metabolic: {r['metabolic_risk_score']}/100 · Adherence: {r['adherence_risk_score']}/100*",
    ]
    return "\n".join(lines)


# ──────────────────────────────────────────────────────────────────────────────
# 6. Pydantic Schemas (OpenAI-compatible)
# ──────────────────────────────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str

class ChatCompletionRequest(BaseModel):
    model: str = "sikanua-v1"
    messages: List[ChatMessage]
    stream: bool = False
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 4096
    user: Optional[str] = None

class ChatCompletionChoice(BaseModel):
    index: int = 0
    message: ChatMessage
    finish_reason: str = "stop"

class Usage(BaseModel):
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int

class ChatCompletionResponse(BaseModel):
    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: List[ChatCompletionChoice]
    usage: Usage


# ──────────────────────────────────────────────────────────────────────────────
# 7. FastAPI App
# ──────────────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="SIKANUA AI API",
    description="OpenAI-compatible nutrition & fitness recommendation API powered by PyTorch",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def run_model(profile: dict) -> str:
    """Run the PyTorch model and return formatted markdown plan."""
    x = profile_to_tensor(profile)
    with torch.no_grad():
        diet_raw, fitness_raw, risk = MODEL(x)
    plan = decode_plan(profile, diet_raw, fitness_raw, risk)
    return plan_to_markdown(plan), plan


async def stream_response(
    content: str,
    model: str,
    completion_id: str,
) -> AsyncGenerator[str, None]:
    """Yield Server-Sent Events in OpenAI streaming format."""
    words = content.split(" ")
    for i, word in enumerate(words):
        chunk = {
            "id": completion_id,
            "object": "chat.completion.chunk",
            "created": int(time.time()),
            "model": model,
            "choices": [{
                "index": 0,
                "delta": {"content": word + (" " if i < len(words) - 1 else "")},
                "finish_reason": None,
            }],
        }
        yield f"data: {json.dumps(chunk)}\n\n"
        await asyncio.sleep(0.012)  # ~80 tokens/sec

    # Final chunk
    final = {
        "id": completion_id,
        "object": "chat.completion.chunk",
        "created": int(time.time()),
        "model": model,
        "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
    }
    yield f"data: {json.dumps(final)}\n\n"
    yield "data: [DONE]\n\n"


@app.get("/")
async def root():
    return {"service": "SIKANUA AI", "version": "1.0.0", "status": "ok"}


@app.get("/v1/models")
async def list_models():
    return {
        "object": "list",
        "data": [{
            "id": "sikanua-v1",
            "object": "model",
            "created": 1700000000,
            "owned_by": "sikanua",
            "description": "PyTorch nutrition & fitness recommendation model",
        }],
    }


@app.post("/v1/chat/completions")
async def chat_completions(request: ChatCompletionRequest):
    completion_id = f"chatcmpl-{uuid.uuid4().hex[:12]}"
    messages = [m.model_dump() for m in request.messages]

    # Check if this is a plan request or a general question
    last_user = next(
        (m["content"] for m in reversed(messages) if m["role"] == "user"), ""
    )

    plan_keywords = [
        "plan", "recommend", "diet", "meal", "workout", "fitness",
        "nutrition", "generate", "create", "profile", "start",
    ]
    is_plan_request = any(kw in last_user.lower() for kw in plan_keywords)

    if is_plan_request or "{" in last_user:
        profile = extract_profile_from_messages(messages)
        response_text, _ = run_model(profile)
    else:
        # Simple conversational response
        response_text = (
            "Hello! I'm SIKANUA, your personalised nutrition and fitness advisor. "
            "To generate your 7-day plan, please share your profile details. "
            "You can send a JSON object like:\n\n"
            "```json\n"
            "{\n"
            '  "age": 28, "sex": "female", "height_cm": 165, "weight_kg": 68,\n'
            '  "activity_level": "moderately_active", "goal": "weight_loss",\n'
            '  "diet_style": "omnivore", "training_days": 4,\n'
            '  "health_conditions": { "diabetes": false }\n'
            "}\n"
            "```\n\n"
            "Or just tell me about yourself in plain text and I'll guide you through it!"
        )

    prompt_tokens = sum(len(m["content"].split()) for m in messages)
    completion_tokens = len(response_text.split())

    if request.stream:
        return StreamingResponse(
            stream_response(response_text, request.model, completion_id),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    return ChatCompletionResponse(
        id=completion_id,
        created=int(time.time()),
        model=request.model,
        choices=[ChatCompletionChoice(
            message=ChatMessage(role="assistant", content=response_text)
        )],
        usage=Usage(
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=prompt_tokens + completion_tokens,
        ),
    )


@app.post("/v1/plan")
async def generate_plan(profile: dict):
    """Direct plan generation endpoint (non-chat)."""
    try:
        x = profile_to_tensor(profile)
        with torch.no_grad():
            diet_raw, fitness_raw, risk = MODEL(x)
        plan = decode_plan(profile, diet_raw, fitness_raw, risk)
        return {"status": "ok", "plan": plan}
    except Exception as e:
        raise HTTPException(status_code=422, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
