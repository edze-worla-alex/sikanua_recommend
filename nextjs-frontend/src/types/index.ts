export interface HealthConditions {
  diabetes?: boolean;
  hypertension?: boolean;
  ckd?: boolean;
  celiac?: boolean;
  ibs?: boolean;
  pcos?: boolean;
  cardiac_history?: boolean;
  osteoporosis?: boolean;
  eating_disorder_recovery?: boolean;
  thyroid_condition?: boolean;
  high_cholesterol?: boolean;
}

export interface UserProfile {
  age: number;
  sex: "male" | "female" | "other";
  height_cm: number;
  weight_kg: number;
  activity_level: "sedentary" | "lightly_active" | "moderately_active" | "very_active" | "athlete";
  goal: "weight_loss" | "maintenance" | "muscle_gain" | "performance" | "general_health";
  diet_style: "omnivore" | "vegetarian" | "vegan" | "pescatarian" | "keto" | "mediterranean" | "halal" | "kosher";
  meals_per_day: number;
  cooking_skill: "none" | "beginner" | "intermediate" | "advanced";
  training_days: number;
  session_duration: "short" | "medium" | "long" | "extended";
  budget: "low" | "moderate" | "high";
  equipment_access: "none" | "home" | "full_gym" | "outdoor";
  exercise_history: "none" | "beginner" | "intermediate" | "advanced";
  health_conditions: HealthConditions;
  stress_level?: number;
  sleep_hours?: number;
  water_litres?: number;
}

export interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
}

export type Step = "welcome" | "profile" | "chat";
