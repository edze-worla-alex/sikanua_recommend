import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();

    // Kick off backend health check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().checkBackend();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const SikanuaLogo(size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'SIKANUA',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          letterSpacing: -1,
                          color: SikanuaTheme.ink,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nutrition & Fitness Intelligence',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: SikanuaTheme.sage,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your personalised 7-day diet and fitness plan,\npowered by PyTorch — reviewed every week.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SikanuaTheme.ink.withOpacity(0.55),
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 36),

                  // Feature cards
                  _featureRow(context),
                  const SizedBox(height: 40),

                  // Backend status
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: provider.backendOnline
                          ? SikanuaTheme.forestLight
                          : const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.backendOnline
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 10,
                          color: provider.backendOnline
                              ? SikanuaTheme.forest
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.backendOnline
                              ? 'AI backend online'
                              : 'Backend offline — start the FastAPI server',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: provider.backendOnline
                                        ? SikanuaTheme.forest
                                        : Colors.orange[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Build My Plan',
                      icon: const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                      onPressed: () =>
                          provider.setStep(AppStep.profile),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Free · No account required · Powered by PyTorch',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SikanuaTheme.ink.withOpacity(0.35),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureRow(BuildContext context) {
    final features = [
      (Icons.restaurant_menu_rounded, 'Nutrition',
          'Plans built around your body, goals & food culture.'),
      (Icons.fitness_center_rounded, 'Fitness',
          'Workouts matched to your schedule and equipment.'),
      (Icons.health_and_safety_rounded, 'Health-Aware',
          'Active conditions shape every recommendation.'),
    ];

    return Column(
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: SikanuaTheme.forestLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(f.$1, color: SikanuaTheme.forest, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$2,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(f.$3,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
