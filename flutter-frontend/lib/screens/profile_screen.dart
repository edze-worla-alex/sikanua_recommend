import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _step = 0;
  static const int _totalSteps = 5;

  // Local mutable profile
  UserProfile _p = const UserProfile();

  final _steps = ['About You', 'Goals', 'Diet', 'Fitness', 'Health'];

  // ─ Step helpers ─────────────────────────────────────────────────────────────

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _aboutYou();
      case 1:
        return _goals();
      case 2:
        return _diet();
      case 3:
        return _fitness();
      case 4:
        return _health();
      default:
        return const SizedBox();
    }
  }

  // ─ Step 0: About You ────────────────────────────────────────────────────────
  Widget _aboutYou() => Column(children: [
        LabelledDropdown<String>(
          label: 'Sex',
          value: _p.sex,
          onChanged: (v) => setState(() => _p = _p.copyWith(sex: v)),
          items: const [
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
        ),
        const SizedBox(height: 16),
        NumberStepper(
          label: 'Age', value: _p.age, min: 16, max: 99, unit: 'yrs',
          onChanged: (v) => setState(() => _p = _p.copyWith(age: v.toInt())),
        ),
        const SizedBox(height: 16),
        NumberStepper(
          label: 'Height', value: _p.heightCm, min: 130, max: 220, step: 0.5, unit: 'cm',
          onChanged: (v) => setState(() => _p = _p.copyWith(heightCm: v.toDouble())),
        ),
        const SizedBox(height: 16),
        NumberStepper(
          label: 'Weight', value: _p.weightKg, min: 30, max: 250, step: 0.5, unit: 'kg',
          onChanged: (v) => setState(() => _p = _p.copyWith(weightKg: v.toDouble())),
        ),
        const SizedBox(height: 16),
        _bmiPreview(),
        const SizedBox(height: 16),
        NumberStepper(
          label: 'Sleep', value: _p.sleepHours, min: 3, max: 12, step: 0.5, unit: 'hrs',
          onChanged: (v) => setState(() => _p = _p.copyWith(sleepHours: v.toDouble())),
        ),
        const SizedBox(height: 16),
        NumberStepper(
          label: 'Stress Level', value: _p.stressLevel, min: 0, max: 10, unit: '/ 10',
          onChanged: (v) => setState(() => _p = _p.copyWith(stressLevel: v.toInt())),
        ),
      ]);

  Widget _bmiPreview() {
    final bmi = _p.bmi;
    String cat;
    Color col;
    if (bmi < 18.5) { cat = 'Underweight'; col = Colors.orange; }
    else if (bmi < 25) { cat = 'Normal Weight'; col = SikanuaTheme.forest; }
    else if (bmi < 30) { cat = 'Overweight'; col = Colors.orange; }
    else { cat = 'Obese'; col = Colors.red; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: col.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_weight_outlined, color: col, size: 18),
          const SizedBox(width: 10),
          Text('BMI: ${bmi.toStringAsFixed(1)} — $cat',
              style: TextStyle(color: col, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ─ Step 1: Goals ────────────────────────────────────────────────────────────
  Widget _goals() => Column(children: [
        LabelledDropdown<String>(
          label: 'Primary Goal',
          value: _p.goal,
          onChanged: (v) => setState(() => _p = _p.copyWith(goal: v)),
          items: const [
            DropdownMenuItem(value: 'weight_loss',    child: Text('Weight Loss')),
            DropdownMenuItem(value: 'maintenance',    child: Text('Maintain Weight')),
            DropdownMenuItem(value: 'muscle_gain',    child: Text('Build Muscle')),
            DropdownMenuItem(value: 'performance',    child: Text('Athletic Performance')),
            DropdownMenuItem(value: 'general_health', child: Text('General Health')),
          ],
        ),
        const SizedBox(height: 16),
        LabelledDropdown<String>(
          label: 'Activity Level',
          value: _p.activityLevel,
          onChanged: (v) => setState(() => _p = _p.copyWith(activityLevel: v)),
          items: const [
            DropdownMenuItem(value: 'sedentary',         child: Text('Sedentary')),
            DropdownMenuItem(value: 'lightly_active',    child: Text('Lightly Active')),
            DropdownMenuItem(value: 'moderately_active', child: Text('Moderately Active')),
            DropdownMenuItem(value: 'very_active',       child: Text('Very Active')),
            DropdownMenuItem(value: 'athlete',           child: Text('Athlete')),
          ],
        ),
        const SizedBox(height: 16),
        LabelledDropdown<String>(
          label: 'Budget',
          value: _p.budget,
          onChanged: (v) => setState(() => _p = _p.copyWith(budget: v)),
          items: const [
            DropdownMenuItem(value: 'low',      child: Text('Low')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
            DropdownMenuItem(value: 'high',     child: Text('High')),
          ],
        ),
      ]);

  // ─ Step 2: Diet ─────────────────────────────────────────────────────────────
  Widget _diet() => Column(children: [
        LabelledDropdown<String>(
          label: 'Dietary Style',
          value: _p.dietStyle,
          onChanged: (v) => setState(() => _p = _p.copyWith(dietStyle: v)),
          items: const [
            DropdownMenuItem(value: 'omnivore',      child: Text('Omnivore')),
            DropdownMenuItem(value: 'vegetarian',    child: Text('Vegetarian')),
            DropdownMenuItem(value: 'vegan',         child: Text('Vegan')),
            DropdownMenuItem(value: 'pescatarian',   child: Text('Pescatarian')),
            DropdownMenuItem(value: 'keto',          child: Text('Ketogenic')),
            DropdownMenuItem(value: 'mediterranean', child: Text('Mediterranean')),
            DropdownMenuItem(value: 'halal',         child: Text('Halal')),
            DropdownMenuItem(value: 'kosher',        child: Text('Kosher')),
          ],
        ),
        const SizedBox(height: 16),
        LabelledDropdown<String>(
          label: 'Cooking Skill',
          value: _p.cookingSkill,
          onChanged: (v) => setState(() => _p = _p.copyWith(cookingSkill: v)),
          items: const [
            DropdownMenuItem(value: 'none',         child: Text("I don't cook")),
            DropdownMenuItem(value: 'beginner',     child: Text('Beginner')),
            DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
            DropdownMenuItem(value: 'advanced',     child: Text('Advanced')),
          ],
        ),
        const SizedBox(height: 16),
        NumberStepper(
          label: 'Meals per Day', value: _p.mealsPerDay, min: 2, max: 6,
          onChanged: (v) => setState(() => _p = _p.copyWith(mealsPerDay: v.toInt())),
        ),
        const SizedBox(height: 16),
        NumberStepper(
          label: 'Daily Water', value: _p.waterLitres, min: 0.5, max: 5, step: 0.25, unit: 'L',
          onChanged: (v) => setState(() => _p = _p.copyWith(waterLitres: v.toDouble())),
        ),
      ]);

  // ─ Step 3: Fitness ──────────────────────────────────────────────────────────
  Widget _fitness() => Column(children: [
        LabelledDropdown<String>(
          label: 'Equipment Access',
          value: _p.equipmentAccess,
          onChanged: (v) => setState(() => _p = _p.copyWith(equipmentAccess: v)),
          items: const [
            DropdownMenuItem(value: 'none',     child: Text('No equipment')),
            DropdownMenuItem(value: 'home',     child: Text('Home gym')),
            DropdownMenuItem(value: 'full_gym', child: Text('Full gym')),
            DropdownMenuItem(value: 'outdoor',  child: Text('Outdoor only')),
          ],
        ),
        const SizedBox(height: 16),
        LabelledDropdown<String>(
          label: 'Exercise Experience',
          value: _p.exerciseHistory,
          onChanged: (v) => setState(() => _p = _p.copyWith(exerciseHistory: v)),
          items: const [
            DropdownMenuItem(value: 'none',         child: Text('Never trained')),
            DropdownMenuItem(value: 'beginner',     child: Text('Beginner')),
            DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
            DropdownMenuItem(value: 'advanced',     child: Text('Advanced')),
          ],
        ),
        const SizedBox(height: 16),
        LabelledDropdown<String>(
          label: 'Session Duration',
          value: _p.sessionDuration,
          onChanged: (v) => setState(() => _p = _p.copyWith(sessionDuration: v)),
          items: const [
            DropdownMenuItem(value: 'short',    child: Text('< 20 min')),
            DropdownMenuItem(value: 'medium',   child: Text('20–45 min')),
            DropdownMenuItem(value: 'long',     child: Text('45–75 min')),
            DropdownMenuItem(value: 'extended', child: Text('75+ min')),
          ],
        ),
        const SizedBox(height: 16),
        NumberStepper(
          label: 'Training Days / Week', value: _p.trainingDays, min: 1, max: 7,
          onChanged: (v) => setState(() => _p = _p.copyWith(trainingDays: v.toInt())),
        ),
      ]);

  // ─ Step 4: Health ───────────────────────────────────────────────────────────
  Widget _health() {
    final hc = _p.healthConditions;
    final conditions = [
      ('Diabetes',         hc.diabetes,         (bool v) => _p.copyWith(healthConditions: hc.copyWith(diabetes: v))),
      ('Hypertension',     hc.hypertension,     (bool v) => _p.copyWith(healthConditions: hc.copyWith(hypertension: v))),
      ('Kidney Disease',   hc.ckd,              (bool v) => _p.copyWith(healthConditions: hc.copyWith(ckd: v))),
      ('Celiac / GF',      hc.celiac,           (bool v) => _p.copyWith(healthConditions: hc.copyWith(celiac: v))),
      ('IBS',              hc.ibs,              (bool v) => _p.copyWith(healthConditions: hc.copyWith(ibs: v))),
      ('PCOS',             hc.pcos,             (bool v) => _p.copyWith(healthConditions: hc.copyWith(pcos: v))),
      ('Heart Condition',  hc.cardiacHistory,   (bool v) => _p.copyWith(healthConditions: hc.copyWith(cardiacHistory: v))),
      ('Osteoporosis',     hc.osteoporosis,     (bool v) => _p.copyWith(healthConditions: hc.copyWith(osteoporosis: v))),
      ('ED Recovery',      hc.eatingDisorderRecovery, (bool v) => _p.copyWith(healthConditions: hc.copyWith(eatingDisorderRecovery: v))),
      ('Thyroid',          hc.thyroidCondition, (bool v) => _p.copyWith(healthConditions: hc.copyWith(thyroidCondition: v))),
      ('High Cholesterol', hc.highCholesterol,  (bool v) => _p.copyWith(healthConditions: hc.copyWith(highCholesterol: v))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SikanuaTheme.amberLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SikanuaTheme.amber.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: SikanuaTheme.amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Select any conditions — your plan will automatically apply clinical guidelines for each.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.brown[700],
                        height: 1.4,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: conditions.map((c) {
            return ConditionChip(
              label: c.$1,
              selected: c.$2,
              onTap: () => setState(() => _p = c.$3(!c.$2)),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─ Navigation ───────────────────────────────────────────────────────────────
  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      final provider = context.read<AppProvider>();
      provider.updateProfile(_p);
      provider.submitProfile();
      provider.setStep(AppStep.chat);
    }
  }

  void _back() {
    if (_step == 0) {
      context.read<AppProvider>().setStep(AppStep.welcome);
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SikanuaTheme.forest,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _back,
        ),
        title: Text(
          _steps[_step],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_step + 1) / _totalSteps,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(SikanuaTheme.amber),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step labels
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: List.generate(_totalSteps, (i) {
                final done = i < _step;
                final active = i == _step;
                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? SikanuaTheme.forest
                              : active
                                  ? SikanuaTheme.amber
                                  : SikanuaTheme.border,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? SikanuaTheme.ink
                                        : Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      if (i < _totalSteps - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i < _step
                                ? SikanuaTheme.forest
                                : SikanuaTheme.border,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Form content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: SingleChildScrollView(
                key: ValueKey(_step),
                padding: const EdgeInsets.all(20),
                child: _buildStep(),
              ),
            ),
          ),

          // Next / Generate button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: isLast ? '✨ Generate My Plan' : 'Next',
                icon: isLast
                    ? null
                    : const Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Colors.white),
                color: isLast ? SikanuaTheme.amber : SikanuaTheme.forest,
                onPressed: _next,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
