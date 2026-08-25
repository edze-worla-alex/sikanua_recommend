class HealthConditions {
  final bool diabetes;
  final bool hypertension;
  final bool ckd;
  final bool celiac;
  final bool ibs;
  final bool pcos;
  final bool cardiacHistory;
  final bool osteoporosis;
  final bool eatingDisorderRecovery;
  final bool thyroidCondition;
  final bool highCholesterol;

  const HealthConditions({
    this.diabetes = false,
    this.hypertension = false,
    this.ckd = false,
    this.celiac = false,
    this.ibs = false,
    this.pcos = false,
    this.cardiacHistory = false,
    this.osteoporosis = false,
    this.eatingDisorderRecovery = false,
    this.thyroidCondition = false,
    this.highCholesterol = false,
  });

  HealthConditions copyWith({
    bool? diabetes,
    bool? hypertension,
    bool? ckd,
    bool? celiac,
    bool? ibs,
    bool? pcos,
    bool? cardiacHistory,
    bool? osteoporosis,
    bool? eatingDisorderRecovery,
    bool? thyroidCondition,
    bool? highCholesterol,
  }) =>
      HealthConditions(
        diabetes: diabetes ?? this.diabetes,
        hypertension: hypertension ?? this.hypertension,
        ckd: ckd ?? this.ckd,
        celiac: celiac ?? this.celiac,
        ibs: ibs ?? this.ibs,
        pcos: pcos ?? this.pcos,
        cardiacHistory: cardiacHistory ?? this.cardiacHistory,
        osteoporosis: osteoporosis ?? this.osteoporosis,
        eatingDisorderRecovery:
            eatingDisorderRecovery ?? this.eatingDisorderRecovery,
        thyroidCondition: thyroidCondition ?? this.thyroidCondition,
        highCholesterol: highCholesterol ?? this.highCholesterol,
      );

  Map<String, dynamic> toJson() => {
        'diabetes': diabetes,
        'hypertension': hypertension,
        'ckd': ckd,
        'celiac': celiac,
        'ibs': ibs,
        'pcos': pcos,
        'cardiac_history': cardiacHistory,
        'osteoporosis': osteoporosis,
        'eating_disorder_recovery': eatingDisorderRecovery,
        'thyroid_condition': thyroidCondition,
        'high_cholesterol': highCholesterol,
      };
}

class UserProfile {
  final int age;
  final String sex;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final String goal;
  final String dietStyle;
  final int mealsPerDay;
  final String cookingSkill;
  final int trainingDays;
  final String sessionDuration;
  final String budget;
  final String equipmentAccess;
  final String exerciseHistory;
  final HealthConditions healthConditions;
  final double sleepHours;
  final int stressLevel;
  final double waterLitres;

  const UserProfile({
    this.age = 28,
    this.sex = 'female',
    this.heightCm = 165,
    this.weightKg = 68,
    this.activityLevel = 'moderately_active',
    this.goal = 'general_health',
    this.dietStyle = 'omnivore',
    this.mealsPerDay = 3,
    this.cookingSkill = 'beginner',
    this.trainingDays = 3,
    this.sessionDuration = 'medium',
    this.budget = 'moderate',
    this.equipmentAccess = 'home',
    this.exerciseHistory = 'beginner',
    this.healthConditions = const HealthConditions(),
    this.sleepHours = 7,
    this.stressLevel = 4,
    this.waterLitres = 2.0,
  });

  UserProfile copyWith({
    int? age,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? goal,
    String? dietStyle,
    int? mealsPerDay,
    String? cookingSkill,
    int? trainingDays,
    String? sessionDuration,
    String? budget,
    String? equipmentAccess,
    String? exerciseHistory,
    HealthConditions? healthConditions,
    double? sleepHours,
    int? stressLevel,
    double? waterLitres,
  }) =>
      UserProfile(
        age: age ?? this.age,
        sex: sex ?? this.sex,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        goal: goal ?? this.goal,
        dietStyle: dietStyle ?? this.dietStyle,
        mealsPerDay: mealsPerDay ?? this.mealsPerDay,
        cookingSkill: cookingSkill ?? this.cookingSkill,
        trainingDays: trainingDays ?? this.trainingDays,
        sessionDuration: sessionDuration ?? this.sessionDuration,
        budget: budget ?? this.budget,
        equipmentAccess: equipmentAccess ?? this.equipmentAccess,
        exerciseHistory: exerciseHistory ?? this.exerciseHistory,
        healthConditions: healthConditions ?? this.healthConditions,
        sleepHours: sleepHours ?? this.sleepHours,
        stressLevel: stressLevel ?? this.stressLevel,
        waterLitres: waterLitres ?? this.waterLitres,
      );

  Map<String, dynamic> toJson() => {
        'age': age,
        'sex': sex,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'activity_level': activityLevel,
        'goal': goal,
        'diet_style': dietStyle,
        'meals_per_day': mealsPerDay,
        'cooking_skill': cookingSkill,
        'training_days': trainingDays,
        'session_duration': sessionDuration,
        'budget': budget,
        'equipment_access': equipmentAccess,
        'exercise_history': exerciseHistory,
        'health_conditions': healthConditions.toJson(),
        'sleep_hours': sleepHours,
        'stress_level': stressLevel,
        'water_litres': waterLitres,
      };

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));
}
