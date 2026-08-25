import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Logo mark ─────────────────────────────────────────────────────────────────
class SikanuaLogo extends StatelessWidget {
  final double size;
  const SikanuaLogo({super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SikanuaTheme.forest,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: SikanuaTheme.forest.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.spa_rounded, color: Colors.white, size: size * 0.52),
    );
  }
}

// ── Primary button ────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Widget? icon;
  final bool loading;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? SikanuaTheme.forest,
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    icon!,
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const SectionCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SikanuaTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SikanuaTheme.border),
      ),
      child: child,
    );
  }
}

// ── Labelled dropdown ─────────────────────────────────────────────────────────
class LabelledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const LabelledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: SikanuaTheme.ink.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(),
          dropdownColor: SikanuaTheme.surface,
          style: Theme.of(context).textTheme.bodyMedium,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: SikanuaTheme.forest),
        ),
      ],
    );
  }
}

// ── Number stepper ────────────────────────────────────────────────────────────
class NumberStepper extends StatelessWidget {
  final String label;
  final num value;
  final num min;
  final num max;
  final num step;
  final String? unit;
  final ValueChanged<num> onChanged;

  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: SikanuaTheme.ink.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: SikanuaTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SikanuaTheme.border),
          ),
          child: Row(
            children: [
              _btn(Icons.remove_rounded, () {
                final next = value - step;
                if (next >= min) onChanged(next);
              }),
              Expanded(
                child: Text(
                  unit != null ? '$value $unit' : '$value',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _btn(Icons.add_rounded, () {
                final next = value + step;
                if (next <= max) onChanged(next);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Icon(icon, size: 18, color: SikanuaTheme.forest),
        ),
      );
}

// ── Condition toggle chip ─────────────────────────────────────────────────────
class ConditionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ConditionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? SikanuaTheme.forest : SikanuaTheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? SikanuaTheme.forest : SikanuaTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded,
                  size: 13, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : SikanuaTheme.ink.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing indicator dots ─────────────────────────────────────────────────────
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = (_ctrl.value + i * 0.18) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs());
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                color: SikanuaTheme.forest.withOpacity(0.5 + 0.5 * scale - 0.6),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
