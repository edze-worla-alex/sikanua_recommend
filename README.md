
# **SIKANUA** 

Nutrition & Fitness Recommendation System 

### **Internal Working Model Document** 

_Confidential — Engineering & Product Teams_ 

Version 1.0   |   June 2026 

## **1. Introduction** 

SIKANUA is an intelligent, adaptive nutrition and fitness recommendation system built on a layered AI architecture. Its core mission is to translate a user's biometric and health profile into a personalised, evidence-based plan that covers both diet and physical activity — and to continuously refine that plan through structured weekly review cycles. 

This document defines the full internal working model: the data inputs the system accepts, the AI reasoning layers it applies, the logic for plan generation, the 7-day review protocol, and the guardrails that keep recommendations safe and equitable. 

Design Principle: SIKANUA treats every user as a unique clinical case. Static one-size-fits-all plans are explicitly excluded. The system is designed to be as useful for a sedentary office worker managing pre-diabetes as it is for an active athlete seeking peak performance. 

### **1.1  Document Scope** 

- Target audience: product engineers, ML engineers, clinical reviewers, and QA teams. 

- This document does not replace clinical guidelines; it describes how SIKANUA interprets and applies them. 

- References to 'the model' mean the ensemble of AI components described in Section 4. 

### **1.2  System Vision** 

SIKANUA sits at the intersection of four AI types drawn from the foundational taxonomy: 

|**AI Type**|**Role in SIKANUA**|**Example Output**|
|---|---|---|
|Diagnostic / Descriptive|Understand the user's<br>current state from intake<br>data|BMI classification, macro gap analysis|
|Predictive|Forecast outcomes under<br>different plan choices|Projected weight change, energy availability|
|Prescriptive|Recommend the optimal<br>plan and next actions|7-day meal plan, workout schedule, supplement flags|
|Limited Memory|Learn from weekly reviews<br>to refine future plans|Adjusted macros after week-1 adherence report|



## **2. User Intake Data Model** 

Before any recommendation is generated, SIKANUA collects a structured intake profile. Every field is classified by tier — Tier 1 fields are mandatory at signup; Tier 2 fields are prompted progressively; Tier 3 fields are optional and typically provided by connected health devices or a clinician. 

### **2.1  Biometric Inputs** 

|**Field**|**Type**|**Tier**|**Notes**|
|---|---|---|---|
|Age|Integer (years)|1|Affects BMR formula selection|
|Biological Sex|Enum: M / F /<br>Intersex|1|Used for hormonal baseline; separate<br>from gender identity|
|Gender Identity|Free text / Enum|2|Stored for inclusive communication<br>only; not used in calculations|
|Height|Float (cm or ft/in)|1|Unit preference stored per user|
|Weight|Float (kg or lbs)|1|Converted to kg internally|
|BMI (computed)|Float|—|BMI = weight(kg) / height(m)²;<br>displayed, not entered|
|Body Fat %|Float|2|Optional; improves lean mass<br>estimates|
|Waist Circumference|Float (cm)|2|Cardiometabolic risk proxy|
|Hip Circumference|Float (cm)|2|Waist-to-hip ratio calculation|
|Resting Heart Rate|Integer (bpm)|3|From wearable or manual entry|
|Blood Pressure|Systolic /<br>Diastolic<br>(mmHg)|3|Flags hypertension tier for plan<br>constraints|
|Blood Glucose (fasting)|Float (mmol/L or<br>mg/dL)|3|Diabetes / pre-diabetes flag|



### **2.2  Health Condition Flags** 

Health conditions are encoded as a boolean flag set plus free-text notes. Each active flag triggers a constraint layer in the prescriptive engine (see Section 4.3). Flags are grouped into five clinical domains: 

#### **2.2.1  Metabolic Domain** 

- Type 1 Diabetes 

- Type 2 Diabetes 

- Pre-diabetes / Insulin Resistance 

- Hypothyroidism / Hyperthyroidism 

- Polycystic Ovary Syndrome (PCOS) 

- Metabolic Syndrome 

#### **2.2.2  Cardiovascular Domain** 

- Hypertension (Stage 1 or 2) 

- Coronary Artery Disease 

- Heart Failure (compensated) 

- Hyperlipidaemia / Dyslipidaemia 

- History of Stroke or TIA 

#### **2.2.3  Musculoskeletal Domain** 

- Osteoporosis / Osteopenia 

- Rheumatoid or Osteoarthritis 

- Chronic Lower Back Pain 

- Post-surgical rehabilitation flag 

- Injury flag (active / recovering) 

#### **2.2.4  Gastrointestinal & Renal Domain** 

- Irritable Bowel Syndrome (IBS) 

- Inflammatory Bowel Disease (Crohn's / Colitis) 

- Celiac Disease 

- Chronic Kidney Disease (CKD, Stage 1–4) 

- Lactose Intolerance 

- GERD / Acid Reflux 

#### **2.2.5  Mental Health & Neurological Domain** 

- Diagnosed eating disorder (recovery flag — restricts caloric floor parameters) 

- Anxiety / Depression (affects exercise intensity guidance) 

- Epilepsy (flags exercise safety constraints) 

**Safety Rule: If any Tier-3 clinical condition is flagged (CKD Stage 3+, active eating disorder, cardiac history), the system mandates a clinician review before activating a plan. The user receives a holding message and is placed on a supervised queue.** 

### **2.3  Nutritional Requirements & Preferences** 

|**Input**|**Description**|
|---|---|
|Dietary Style|Omnivore, Vegetarian, Vegan, Pescatarian, Keto, Mediterranean, Halal,<br>Kosher, etc.|
|Food Allergies|Multi-select: peanut, tree nut, shellfish, fish, soy, wheat, egg, milk|
|Food Dislikes|Free-text list; used to filter meal alternatives|
|Preferred Cuisines|Multi-select: West African, Asian, Mediterranean, Latin American, etc.|
|Cooking Skill Level|Enum: None / Beginner / Intermediate / Advanced|
|Meal Prep Time Available|Enum: <15 min / 15–30 min / 30–60 min / 60+ min|
|Number of Meals Per Day|Integer: 2 – 6|



|**Input**|**Description**|
|---|---|
|Budget Category|Enum: Low / Moderate / High — affects ingredient choices|
|Alcohol Consumption|Enum: None / Occasional / Regular|
|Water Intake (current)|Float (litres/day) — used as hydration baseline|
|Supplement Use|Free-text; checked against plan to avoid duplication|



### **2.4  Physical Activity Profile** 

|**Input**|**Description**|
|---|---|
|Current Activity Level|Sedentary / Lightly Active / Moderately Active / Very Active / Athlete|
|Exercise History|None / <6 months / 6–24 months / >2 years|
|Preferred Exercise Types|Multi-select: Strength, Cardio, HIIT, Yoga, Swimming, Sports, etc.|
|Equipment Access|Enum: None / Home Equipment / Full Gym / Outdoor Only|
|Available Training Days/Week|Integer: 1 – 7|
|Session Duration Available|Enum: <20 min / 20–45 min / 45–75 min / 75+ min|
|Mobility / Flexibility Issues|Boolean + free-text notes|
|Primary Fitness Goal|Weight Loss / Muscle Gain / Endurance / Flexibility / General Health /<br>Athletic Performance|



### **2.5  Goal Parameters** 

- Primary Goal: selected from the fitness goal list above. 

- Target Weight (optional): user-specified; system validates against safe minimum BMI thresholds. 

- Target Timeframe: expressed in weeks; used to compute required weekly deficit or surplus. 

- Priority Balance: slider input — Diet-focused vs. Exercise-focused (affects how caloric targets are distributed). 

- Motivation Style: Strict / Flexible / Social / Gamified — affects how reminders and nudges are framed. 

## **3. Baseline Calculation Engine** 

Before the AI recommendation layers engage, a deterministic calculation engine computes the user's energy and macronutrient baselines. These outputs are the numerical ground truth that all subsequent AI layers operate on. 

### **3.1  BMI Classification** 

|**BMI Range**|**Classification**|**System Action**|
|---|---|---|
|< 16.0|Severe Underweight|Block plan; escalate to clinical queue|
|16.0 – 18.4|Underweight|Warn; require clinician clearance for weight-loss goals|
|18.5 – 24.9|Normal Weight|Standard plan generation permitted|
|25.0 – 29.9|Overweight|Standard plan; weight-loss path available|
|30.0 – 34.9|Obese Class I|Standard plan; moderate caloric restriction|
|35.0 – 39.9|Obese Class II|Medical review recommended (non-blocking flag)|
|≥ 40.0|Obese Class III|Clinical queue; plan restricted until cleared|



### **3.2  Basal Metabolic Rate (BMR)** 

SIKANUA uses the Mifflin-St Jeor equation as the primary BMR calculator due to its validated accuracy across diverse adult populations: 

**For Males:    BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5For Females:  BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161** 

If body fat percentage is available (Tier 2), the Katch-McArdle formula is used instead for improved accuracy: 

**BMR (Katch-McArdle) = 370 + (21.6 × Lean Body Mass in kg)** 

### **3.3  Total Daily Energy Expenditure (TDEE)** 

TDEE is derived by multiplying BMR by the user's Physical Activity Level (PAL) multiplier: 

|**Activity Level**|**PAL Multiplier**|**Description**|
|---|---|---|
|Sedentary|× 1.2|Little or no exercise; desk job|
|Lightly Active|× 1.375|Light exercise 1–3 days/week|
|Moderately Active|× 1.55|Moderate exercise 3–5 days/week|
|Very Active|× 1.725|Hard exercise 6–7 days/week|
|Athlete / Extra Active|× 1.9|Very hard exercise, physical job|



### **3.4  Caloric Target Computation** 

The caloric target is the TDEE adjusted by the user's primary goal: 

|**Goal**|**Caloric Adjustment**|
|---|---|
|Weight Loss (Standard)|TDEE − 500 kcal/day (approx. 0.45 kg/week loss)|
|Weight Loss (Aggressive)|TDEE − 750 kcal/day (max; never below 1200 F / 1500 M)|
|Maintenance|TDEE (no adjustment)|
|Muscle Gain (Lean Bulk)|TDEE + 250 kcal/day (minimised fat gain)|
|Muscle Gain (Standard Bulk)|TDEE + 500 kcal/day|
|Athletic Performance|TDEE + periodisation adjustment (training phase dependent)|



**Hard Floor Rule: No plan may set a daily caloric target below 1,200 kcal for female users or 1,500 kcal for male users. If the computed target falls below this floor, the system locks the target at the floor value and adjusts the projected timeframe accordingly, notifying the user.** 

### **3.5  Macronutrient Distribution** 

Macronutrient targets are computed as percentages of total caloric target, then adjusted by health condition flags: 

|**Goal / Profile**|**Protein**|**Carbohydrate**|**Fat**|
|---|---|---|---|
|General Health /<br>Maintenance|20–25%|45–55%|25–30%|
|Weight Loss|25–30%|35–45%|25–30%|
|Muscle Gain|30–35%|40–50%|20–25%|
|Ketogenic (if selected)|25–30%|< 5%|65–75%|
|Diabetes / Pre-diabetes|25–30%|30–40% (low GI<br>only)|25–30%|
|CKD (Stage 3–4)|0.6–0.8 g/kg body<br>weight|Adjusted to target|Remainder|
|Endurance / Athletic|20–25%|55–65%|20–25%|



Protein targets are always cross-validated against a per-kilogram-body-weight minimum (1.2–2.2 g/kg depending on goal), and the higher of the two values is used. 

## **4. AI Recommendation Engine** 

The recommendation engine is a four-layer AI pipeline. Each layer processes the outputs of the previous layer and adds reasoning, constraints, or content. The architecture deliberately separates calculation (deterministic), prediction (probabilistic), prescription (optimisation), and memory (adaptive learning). 

### **4.1  Layer 1 — Diagnostic AI: User State Assessment** 

This layer runs immediately after intake. It analyses the full user profile to produce a structured State Report, which is the input to all downstream layers. 

#### **Outputs of Layer 1:** 

- BMI classification and risk tier. 

- Metabolic risk score (0–100) aggregated from BMI, waist circumference, blood glucose, and BP. 

- Nutritional gap analysis: comparison of current estimated intake (if provided) vs. computed targets. 

- Activity sufficiency score: current activity level vs. WHO minimum recommendations. 

- Active constraint flags: list of all health-condition-derived restrictions that must be honoured. 

- Readiness-to-train classification: Safe / Conditional / Restricted. 

The State Report is logged with a timestamp. Every future week-1 review will diff the new state against the original State Report to quantify progress. 

### **4.2  Layer 2 — Predictive AI: Outcome Forecasting** 

Before generating a plan, SIKANUA simulates likely outcomes across multiple plan variants. This layer uses a probabilistic model trained on nutritional and exercise science literature to estimate: 

- Projected weight change trajectory over 4, 8, and 12 weeks under the proposed caloric target. 

- Estimated muscle retention probability under the proposed protein intake. 

- Adherence risk score: based on dietary style match, cooking skill, budget, and historical adherence patterns from similar user cohorts. 

- Energy availability risk: flags if proposed plan may result in Relative Energy Deficiency in Sport (RED-S) for active users. 

- Micronutrient deficiency risk: flags nutrients likely to be low given dietary restrictions (e.g., B12 for vegans, iron for female athletes, calcium for dairy-free users). 

#### **Prediction Confidence Levels:** 

Each prediction is tagged with a confidence level (High / Medium / Low) based on the completeness of the intake profile. Missing Tier-2 or Tier-3 data lowers confidence and widens prediction ranges. 

### **4.3  Layer 3 — Prescriptive AI: Plan Generation** 

This is the core recommendation layer. It synthesises Layer 1's State Report and Layer 2's forecasts to generate the full 7-day plan. The prescriptive engine operates in three sub-modules: 

#### **4.3.1  Diet Plan Module** 

- Selects meals from a curated, nutritionist-reviewed meal database, filtered by dietary style, allergies, cuisine preferences, and cooking skill. 

- Constructs a 7-day meal schedule meeting the computed caloric target and macro distribution within ±5% tolerance. 

- Assigns portion sizes dynamically per user (not fixed cookbook portions). 

- Generates a consolidated shopping list grouped by store section. 

- Flags any days where micronutrient targets are difficult to meet, with specific food suggestions to close the gap. 

- Incorporates meal timing guidance based on training schedule (e.g., pre-/post-workout nutrition windows). 

#### **4.3.2  Fitness Plan Module** 

- Selects exercises filtered by equipment access, injury flags, and readiness-to-train classification. 

- Constructs a weekly training schedule respecting the user's available days and session duration. 

- Applies progressive overload principles for strength plans; periodisation for endurance plans. 

- Assigns intensity levels (RPE scale 1–10) based on exercise history and activity level. 

- Pairs training days with nutritional support (higher carbs on heavy training days, protein emphasis on rest days). 

- Generates video-linked exercise instructions (integration point for exercise media library). 

#### **4.3.3  Constraint Enforcement Module** 

This sub-module applies all active flags as hard constraints before the plan is finalised: 

|**Active Flag**|**Enforced Constraint**|
|---|---|
|Diabetes|All carbs scored ≤ 55 GI; no added sugar meals; carb distribution across 5–6<br>small meals|
|Hypertension|Sodium cap at 1,500 mg/day; no high-sodium condiments; DASH-aligned<br>meals prioritised|
|CKD (Stage 3–4)|Potassium < 2,000 mg/day; phosphorus < 800 mg/day; protein at clinical<br>minimum|
|Celiac / Gluten-Free|All meals verified gluten-free; oat alternatives specified|
|Eating Disorder (Recovery)|No calorie counts shown to user; no weight targets displayed; plan framed as<br>nourishment|
|Cardiac History|Cardio intensity capped at moderate (RPE ≤ 6); no HIIT without clinical<br>clearance|
|Osteoporosis|Impact exercise limited; resistance training emphasised; calcium and Vitamin D<br>intake flagged|
|IBS|Low-FODMAP filter applied to meal database; trigger foods excluded by default|
|PCOS|Anti-inflammatory meals prioritised; refined carbohydrate minimisation;<br>inositol-rich foods suggested|



### **4.4  Layer 4 — Limited Memory AI: Adaptive Learning** 

After the first 7-day cycle, this layer activates. It ingests the review data (Section 5) and updates the user's internal model to improve subsequent plans. The memory layer maintains: 

- Adherence history: per-meal and per-workout completion rate, tracked over all cycles. 

- Biometric deltas: weight, body measurements, and any user-reported biometric changes. 

- Preference refinements: meals rated highly are upweighted; disliked meals are suppressed. 

- Tolerance signals: if a user consistently skips certain meal types, the planner reduces their frequency. 

- • Response patterns: if the predictive layer's forecasts are consistently off for this user, calibration offsets are applied. 

- Workout progression log: weights lifted, distances run, RPE reported — used to auto-progress or regress intensity. 

The adaptive layer does not share data across users. All learning is strictly per-user. Anonymised, aggregated trend data may be used to improve the global model in periodic retraining cycles, subject to explicit user consent. 

## **5. The 7-Day Plan Review Protocol** 

SIKANUA's core operational loop is a rolling 7-day cycle. Every user is placed on a plan for exactly one week before the system triggers a structured review. This cadence balances sufficient time for physiological response with the agility to correct course quickly. 

### **5.1  Review Trigger Mechanism** 

- The review is automatically triggered at 23:59 on Day 7 of each plan cycle, regardless of adherence level. 

- Users receive a push notification at Day 5 previewing that a review is upcoming and prompting them to log any outstanding meals or workouts. 

- Emergency early review is triggered if: the user logs a health symptom (dizziness, chest pain, extreme fatigue); weight drops more than 2 kg in one week; the user manually requests a review. 

### **5.2  Review Data Collection** 

At the end of each 7-day cycle, the system collects the following data points either automatically (from app logs) or through the user's end-of-week check-in: 

#### **5.2.1  Adherence Metrics (Auto-collected)** 

- Meals logged as completed vs. total planned meals. 

- Workouts logged as completed vs. total planned workouts. 

- Water intake average (if tracked). 

- Sleep duration average (if integrated with wearable). 

#### **5.2.2  Biometric Updates (User-reported or Device-synced)** 

- Current weight. 

- Body measurements if tracked (waist, hip). 

- Subjective energy level: 1–10 scale. 

- Subjective hunger level: 1–10 scale (averaged across week). 

- Any new symptoms or health changes. 

#### **5.2.3  Satisfaction & Feedback** 

- Overall plan satisfaction: 1–5 star rating. 

- Diet plan satisfaction: 1–5 star rating with optional notes. 

- Fitness plan satisfaction: 1–5 star rating with optional notes. 

- Specific meals to keep, modify, or remove. 

- Specific exercises to keep, modify, or remove. 

- Open-text field: anything else you want us to know. 

### **5.3  Review Decision Matrix** 

The Layer 4 adaptive engine processes the review data and produces one of five continuation decisions: 

|**Decision**|**Trigger Conditions**|**Action Taken**|
|---|---|---|
|Continue Unchanged|≥80% adherence; biometrics<br>on track; satisfaction ≥4|Regenerate same plan structure for next 7 days<br>with minor variety swaps|
|Minor Adjustment|60–79% adherence OR<br>satisfaction 3–4 OR slight<br>biometric deviation|Swap disliked meals; adjust one training day;<br>recalibrate portions|
|Moderate Revision|<60% adherence OR<br>satisfaction ≤2 OR biometrics<br>not trending correctly|Rebuild diet plan; revise workout intensity; re-run<br>predictive layer|
|Full Rebuild|Combination of low<br>adherence + poor<br>satisfaction + adverse<br>biometrics|Full new plan generation as if new user,<br>incorporating all memory data|
|Clinical Escalation|Any red-flag symptom<br>logged; BMI drop > 1.5 in<br>one week; health flags<br>triggered|Plan paused; user routed to clinician review<br>queue; no new plan until cleared|



### **5.4  Review Communication to User** 

After the decision is made, the user receives a Review Summary notification containing: 

- A plain-language progress summary (no clinical jargon). 

- One highlight ('What went well this week'). 

- One focus area ('What to build on next week'). 

- The next 7-day plan, ready to start immediately. 

- An optional 'Chat with Advisor' prompt if they want to discuss the plan. 

Communication Principle: The review summary is framed positively and constructively at all times. The system never uses language that implies failure, guilt, or punishment for low adherence. Low adherence is treated as a signal to adjust the plan, not a character assessment of the user. 

## **6. Safety Architecture & Guardrails** 

SIKANUA is a health system. Safety guardrails are not optional features — they are structural constraints built into every layer of the engine. This section documents all safety mechanisms. 

### **6.1  Caloric & Nutritional Safety Floors** 

- Minimum daily calories: 1,200 kcal (female users), 1,500 kcal (male users). Hard-coded floor; cannot be overridden by any input combination. 

- Minimum protein: 0.8 g/kg/day for general users; higher minimums enforced for active users and those with muscle-preservation goals. 

- Maximum deficit: 1,000 kcal/day below TDEE. Plans requiring a larger deficit to meet a user's timeframe goal will extend the timeframe instead. 

- Micronutrient floor: if any day's plan falls below 50% of the RDA for any tracked micronutrient without a supplement compensating, the meal is replaced. 

### **6.2  Exercise Safety Limits** 

- RPE cap: no first-week plan exceeds RPE 7. The system ramps intensity over weeks 2–4. 

- Cardiac safety: any user with a cardiac history flag is capped at moderate-intensity cardio and must clear HIIT with a clinician first. 

- Progressive overload limit: strength plan increases volume by no more than 10% per week (standard progressive overload safety principle). 

- Rest day enforcement: every 7-day plan must include at least 1 full rest day and 1 active recovery day. 

### **6.3  Clinical Escalation Triggers** 

The following conditions immediately pause the active plan and route the user to a supervised queue: 

- User logs: chest pain, shortness of breath, severe dizziness, fainting, or severe nausea during exercise. 

- Logged weight change exceeds −2 kg in a 7-day period. 

- Blood glucose log (if connected) records a reading < 3.9 mmol/L (hypoglycaemia threshold). 

- Eating disorder recovery flag becomes active mid-plan. 

- User-initiated distress signal via in-app 'I need help' button. 

### **6.4  Data Privacy Guardrails** 

- All health condition data is stored encrypted at rest and in transit. 

- Biometric data is never shared with third parties without explicit, granular user consent. 

- The adaptive learning model is trained per-user; no cross-user data inference. 

- Users may request deletion of all data at any time; deletion cascades to the adaptive memory store. 

- • GDPR, HIPAA, and applicable local health data regulations compliance is mandatory before production deployment. 

### **6.5  Equity & Bias Monitoring** 

SIKANUA is designed to serve a diverse global population. The following bias monitoring protocols are in place: 

- Meal databases are curated to include regional cuisine representation from Africa, Asia, Latin America, the Middle East, and the Caribbean — not defaulted to Western diets. 

- BMI thresholds for Asian populations are adjusted per WHO Asia-Pacific guidelines (overweight threshold: 23.0; obese threshold: 27.5). 

- All recommendation outputs are reviewed quarterly across demographic cohorts to detect and correct disparate outcomes. 

- The system never penalises or downgrades the quality of recommendations based on budget category. 

## **7. End-to-End System Workflow** 

The following outlines the full user journey through SIKANUA from initial signup through the ongoing weekly plan cycle: 

### **7.1  Onboarding Flow (One-Time)** 

1. User registers and completes Tier-1 intake form (biometrics, goal, dietary style, activity level). 

2. System computes BMR, TDEE, and caloric target (Baseline Calculation Engine, Section 3). 

3. Layer 1 Diagnostic AI produces the State Report. 

4. Layer 2 Predictive AI forecasts outcomes and flags adherence risks. 

5. Constraint Enforcement Module applies all active health flags. 

6. Layer 3 Prescriptive AI generates the first 7-day Diet + Fitness Plan. 

7. Clinical safety check: if any escalation trigger is active, plan is held and user is queued. 

8. Plan is delivered to the user via the app dashboard. 

### **7.2  Weekly Operational Cycle** 

9. User follows the 7-day plan; meals and workouts are logged in-app. 

10. Day 5: Preview notification prompts logging completion. 

11. Day 7 (23:59): Review is triggered automatically. 

12. End-of-week check-in form is presented; user submits biometric updates and feedback. 

13. Layer 4 Memory AI ingests all review data and computes adherence, biometric delta, and satisfaction scores. 

14. Review Decision Matrix produces one of five decisions (Section 5.3). 

15. Layer 3 regenerates or revises the next 7-day plan accordingly. 

16. Review Summary is delivered to the user; new plan begins immediately. 

17. Repeat from Step 1. 

### **7.3  Long-Term Progression Logic** 

SIKANUA adjusts its approach based on cumulative plan cycles: 

|**Cycle**|**Behaviour**|
|---|---|
|Week 1–2|Conservative: lower intensity, familiar foods, high variety to identify preferences|
|Week 3–4|Progression: intensity ramps, macro targets tightened based on adherence response|
|Week 5–8|Optimisation: full adaptive personalisation active; meal and workout preferences<br>well-calibrated|
|Week 9–12|Performance: system shifts from learning to optimising — fine-tuning rather than rebuilding|
|12+ Weeks|Maintenance or goal transition: if primary goal is met, system prompts goal re-assessment|



## **8. Integration Points & External Data Sources** 

### **8.1  Wearable & Health Device Integrations** 

SIKANUA supports the following data integrations, all of which are optional and consent-gated: 

- Apple Health / Google Fit: steps, active calories, sleep, heart rate. 

- Garmin / Fitbit / Whoop: workout tracking, recovery scores, HRV. 

- Continuous Glucose Monitors (CGM): real-time blood glucose data for diabetic users. 

- Smart Scales: weight and body composition sync. 

### **8.2  Meal Database & Food API** 

- Primary food database: USDA FoodData Central (global fallback). 

- Regional supplement databases: West Africa Food Composition Table, ASEAN Food Composition Database. 

- Barcode scanning integration for packaged food logging. 

- Restaurant menu API integration (where available) for eating-out logging. 

### **8.3  Clinician Portal** 

Users escalated to the clinical queue are managed through a separate Clinician Portal. The portal exposes: 

- Full user State Report and plan history. 

- Escalation reason and flag detail. 

- Clinician override: ability to modify constraints, approve plans, or mark a case as cleared. 

- Secure messaging channel between clinician and user. 

- Audit log of all clinician actions. 

## **9. Glossary** 

|**Term**|**Definition**|
|---|---|
|BMR|Basal Metabolic Rate — energy expended at complete rest|
|TDEE|Total Daily Energy Expenditure — BMR adjusted for activity level|
|BMI|Body Mass Index — weight in kg divided by height in metres squared|
|PAL|Physical Activity Level — multiplier applied to BMR to estimate TDEE|
|RPE|Rate of Perceived Exertion — subjective 1–10 exercise intensity scale|
|DASH|Dietary Approaches to Stop Hypertension — evidence-based dietary pattern|
|GI|Glycaemic Index — ranking of carbohydrate-containing foods by blood glucose<br>response|
|RED-S|Relative Energy Deficiency in Sport — condition from insufficient energy intake in<br>active individuals|
|FODMAP|Fermentable Oligosaccharides, Disaccharides, Monosaccharides And Polyols —<br>carb group linked to IBS|
|CKD|Chronic Kidney Disease — staged kidney function impairment affecting dietary<br>requirements|
|PCOS|Polycystic Ovary Syndrome — hormonal condition affecting metabolic and dietary<br>needs|
|RDA|Recommended Dietary Allowance — established minimum intake for specific<br>nutrients|
|State Report|SIKANUA's internal diagnostic summary of a user's current health and biometric<br>profile|
|Plan Cycle|A single 7-day diet and fitness plan period, ending in a review|



**Term Definition** 

Constraint Flag A health-condition-derived rule that limits or modifies plan options 


# SIKANUA CODE API — Nutrition & Fitness AI System

A complete full-stack AI application with:

- **PyTorch + FastAPI** backend (OpenAI-compatible `/v1/chat/completions`)
- **Next.js 15** web frontend (streaming chat UI)
- **Flutter** mobile frontend (iOS & Android)

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    SIKANUA SYSTEM                        │
│                                                          │
│  ┌─────────────┐     ┌─────────────┐   ┌─────────────┐  │
│  │  Flutter    │     │  Next.js 15 │   │  Any OpenAI │  │
│  │  Mobile App │     │  Web App    │   │  Client     │  │
│  └──────┬──────┘     └──────┬──────┘   └──────┬──────┘  │
│         │                   │                  │         │
│         └───────────────────┼──────────────────┘         │
│                             │                            │
│                    ┌────────▼────────┐                   │
│                    │  FastAPI Server │                   │
│                    │  :8000          │                   │
│                    │                 │                   │
│                    │  POST /v1/chat/ │                   │
│                    │  completions    │                   │
│                    │  GET  /v1/models│                   │
│                    │  POST /v1/plan  │                   │
│                    └────────┬────────┘                   │
│                             │                            │
│                    ┌────────▼────────┐                   │
│                    │  SikanuaNet     │                   │
│                    │  (PyTorch)      │                   │
│                    │                 │                   │
│                    │  UserEncoder    │                   │
│                    │  DietHead       │                   │
│                    │  FitnessHead    │                   │
│                    │  RiskHead       │                   │
│                    └─────────────────┘                   │
└──────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Option A — Docker Compose (Backend + Next.js)

```bash
git clone <repo>
cd sikanua
docker-compose up --build
```

- Web app:  http://localhost:3000  
- API docs: http://localhost:8000/docs

---

### Option B — Manual

#### 1. Backend (Python 3.11+)

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Verify it's running:
```bash
curl http://localhost:8000/
# {"service":"SIKANUA AI","version":"1.0.0","status":"ok"}
```

#### 2. Next.js Web Frontend

```bash
cd nextjs-frontend
npm install
npm run dev          # http://localhost:3000
```

Set the API URL via env if backend is not on localhost:
```bash
NEXT_PUBLIC_SIKANUA_API_URL=http://your-server:8000 npm run dev
```

#### 3. Flutter Mobile App

```bash
cd flutter-frontend
flutter pub get
flutter run          # connects to localhost:8000 by default
```

To change the backend URL, edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER:8000';
```

For Android emulator, use `http://10.0.2.2:8000` instead of localhost.  
For iOS simulator, `http://localhost:8000` works as-is.

---

## API Reference

The backend exposes an OpenAI-compatible API. You can point **any** OpenAI SDK
client at `http://localhost:8000` with model `sikanua-v1`.

### List models
```bash
curl http://localhost:8000/v1/models
```

### Chat completion (non-streaming)
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "sikanua-v1",
    "messages": [
      {
        "role": "user",
        "content": "Generate my plan:\n```json\n{\"age\":28,\"sex\":\"female\",\"height_cm\":165,\"weight_kg\":68,\"activity_level\":\"moderately_active\",\"goal\":\"weight_loss\",\"diet_style\":\"vegan\",\"training_days\":4,\"health_conditions\":{\"diabetes\":false}}\n```"
      }
    ],
    "stream": false
  }'
```

### Chat completion (streaming)
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"sikanua-v1","messages":[{"role":"user","content":"Generate plan: ```json\n{\"age\":30,\"sex\":\"male\",\"height_cm\":178,\"weight_kg\":85,\"activity_level\":\"very_active\",\"goal\":\"muscle_gain\",\"diet_style\":\"omnivore\",\"training_days\":5,\"health_conditions\":{}}\n```"}],"stream":true}'
```

### Direct plan endpoint (structured JSON response)
```bash
curl -X POST http://localhost:8000/v1/plan \
  -H "Content-Type: application/json" \
  -d '{
    "age": 35,
    "sex": "male",
    "height_cm": 180,
    "weight_kg": 90,
    "activity_level": "moderately_active",
    "goal": "weight_loss",
    "diet_style": "mediterranean",
    "training_days": 3,
    "health_conditions": { "hypertension": true }
  }'
```

---

## User Profile Schema

```json
{
  "age": 28,
  "sex": "female | male | other",
  "height_cm": 165,
  "weight_kg": 68,
  "activity_level": "sedentary | lightly_active | moderately_active | very_active | athlete",
  "goal": "weight_loss | maintenance | muscle_gain | performance | general_health",
  "diet_style": "omnivore | vegetarian | vegan | pescatarian | keto | mediterranean | halal | kosher",
  "meals_per_day": 3,
  "cooking_skill": "none | beginner | intermediate | advanced",
  "training_days": 3,
  "session_duration": "short | medium | long | extended",
  "budget": "low | moderate | high",
  "equipment_access": "none | home | full_gym | outdoor",
  "exercise_history": "none | beginner | intermediate | advanced",
  "sleep_hours": 7.0,
  "stress_level": 4,
  "water_litres": 2.0,
  "health_conditions": {
    "diabetes": false,
    "hypertension": false,
    "ckd": false,
    "celiac": false,
    "ibs": false,
    "pcos": false,
    "cardiac_history": false,
    "osteoporosis": false,
    "eating_disorder_recovery": false,
    "thyroid_condition": false,
    "high_cholesterol": false
  }
}
```

---

## PyTorch Model Details

**SikanuaNet** is a multi-head neural network:

| Component | Architecture | Output |
|-----------|-------------|--------|
| `UserProfileEncoder` | Linear → LayerNorm → GELU → Dropout (×2) → Linear | 64-dim embedding |
| `DietHead` | Linear(64→64) → GELU → Linear(64→32) → GELU → Linear(32→8) | 8 diet params |
| `FitnessHead` | Linear(64→64) → GELU → Linear(64→32) → GELU → Linear(32→6) | 6 fitness params |
| `RiskHead` | Linear(64→32) → GELU → Linear(32→3) → Sigmoid | 3 risk scores |

Input: 35-dimensional normalised user profile vector  
The model outputs are decoded by a rule-augmented generator that enforces
clinical constraints (sodium caps, GI limits, RPE ceilings, etc.)

---

## Project Structure

```
sikanua/
├── backend/
│   ├── main.py             # FastAPI app + PyTorch model
│   ├── requirements.txt
│   └── Dockerfile
│
├── nextjs-frontend/
│   ├── src/
│   │   ├── app/            # Next.js App Router
│   │   ├── components/     # Welcome, ProfileForm, ChatInterface
│   │   ├── lib/api.ts      # Streaming API client
│   │   ├── store/index.ts  # Zustand state
│   │   └── types/index.ts
│   ├── package.json
│   └── Dockerfile
│
├── flutter-frontend/
│   ├── lib/
│   │   ├── main.dart           # App entry + router
│   │   ├── models/             # UserProfile, ChatMessage
│   │   ├── services/           # ApiService (streaming)
│   │   ├── providers/          # AppProvider (ChangeNotifier)
│   │   ├── screens/            # WelcomeScreen, ProfileScreen, ChatScreen
│   │   ├── widgets/            # Shared UI components
│   │   └── theme/              # SikanuaTheme
│   └── pubspec.yaml
│
├── docker-compose.yml
└── README.md
```

---

## Use with Any OpenAI Client

Because the backend implements the OpenAI spec, you can use it with
any existing OpenAI SDK by just swapping the base URL:

```python
# Python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8000/v1", api_key="not-needed")
response = client.chat.completions.create(
    model="sikanua-v1",
    messages=[{"role": "user", "content": "Generate plan: ..."}],
    stream=True,
)
for chunk in response:
    print(chunk.choices[0].delta.content or "", end="", flush=True)
```

```javascript
// JavaScript / TypeScript
import OpenAI from 'openai';

const client = new OpenAI({ baseURL: 'http://localhost:8000/v1', apiKey: 'x' });
const stream = client.chat.completions.stream({
  model: 'sikanua-v1',
  messages: [{ role: 'user', content: 'Generate plan: ...' }],
});
for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content ?? '');
}
```
