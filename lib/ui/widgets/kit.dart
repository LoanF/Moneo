import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/theme.dart';

/// Kit de composants Moneo. Tout ce que l'app affiche de reconnaissable est dessiné ici :
/// aucun de ces éléments n'est un contrôle Material ou Cupertino par défaut.

// ── Appui ────────────────────────────────────────────────────────────────────

/// Rend n'importe quel contenu pressable : léger enfoncement, retour haptique, sémantique de bouton.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.label,
    this.selected,
    this.scale = 0.96,
    this.haptic = true,
  });
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Nom lu par les lecteurs d'écran quand le contenu n'a pas de texte.
  final String? label;
  final bool? selected;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap != null && _down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: enabled
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: context.reduceMotion ? Duration.zero : Motion.fast,
          curve: Motion.curve,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.45,
            duration: Motion.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ── Surfaces ─────────────────────────────────────────────────────────────────

/// Carte Moneo : grande surface arrondie, avec un fin liseré lumineux en haut.
class MCard extends StatelessWidget {
  const MCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.radius = Radii.card,
    this.color,
    this.gradient,
    this.glow = false,
    this.margin,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;

  /// Halo rouge sous la carte (éléments mis en avant).
  final bool glow;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: gradient == null
              ? c.line
              : Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: c.glow,
              blurRadius: 36,
              offset: const Offset(0, 16),
              spreadRadius: -10,
            ),
          if (!context.isDark && !glow)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -8,
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Halos de couleur flous derrière un en-tête, pour donner de la profondeur au fond.
class GlowBackdrop extends StatelessWidget {
  const GlowBackdrop({super.key, this.height = 360});
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final strength = context.isDark ? 1.0 : 0.55;
    Widget blob(Alignment at, double size, Color color) => Align(
      alignment: at,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              blob(
                const Alignment(-1.3, -1.2),
                380,
                c.brand.withValues(alpha: 0.34 * strength),
              ),
              blob(
                const Alignment(1.4, -0.6),
                300,
                c.brandBright.withValues(alpha: 0.18 * strength),
              ),
              blob(
                const Alignment(0.2, 1.4),
                260,
                const Color(0xFF7C3AED).withValues(alpha: 0.10 * strength),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Boutons ──────────────────────────────────────────────────────────────────

/// Bouton principal : dégradé rouge, halo, reflet qui le traverse de temps en temps.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
    this.height = 56,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;
  final double height;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.reduceMotion ? _sheen.stop() : _sheen.repeat();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final enabled = widget.onPressed != null && !widget.busy;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.busy)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: Colors.white,
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 22, color: Colors.white),
            const SizedBox(width: Gap.sm),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelLarge?.copyWith(
                color: Colors.white,
                fontSize: 16.5,
              ),
            ),
          ),
        ],
      ],
    );

    return Pressable(
      onTap: enabled ? widget.onPressed : null,
      scale: 0.97,
      child: Container(
        height: widget.height,
        width: widget.expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
        decoration: BoxDecoration(
          gradient: c.brandGradient,
          borderRadius: BorderRadius.circular(widget.height / 2.8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: c.glow,
              blurRadius: 28,
              offset: const Offset(0, 12),
              spreadRadius: -8,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Reflet en diagonale, inspiré du « shiny button » de Magic UI.
            Positioned.fill(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _sheen,
                  builder: (_, _) {
                    final t = Curves.easeInOut.transform(
                      (_sheen.value * 2.4).clamp(0, 1),
                    );
                    return FractionalTranslation(
                      translation: Offset(-1.2 + t * 2.4, 0),
                      child: Transform.rotate(
                        angle: -0.35,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

/// Bouton secondaire, discret.
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.danger = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final color = danger ? context.scheme.error : c.ink;
    return Pressable(
      onTap: onPressed,
      scale: 0.97,
      child: Container(
        height: 52,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: Gap.sm),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton rond d'icône, sur fond de verre.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
    this.size = 44,
    this.filled = true,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int badge;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Pressable(
        onTap: onTap,
        label: badge > 0 ? '$tooltip, $badge' : tooltip,
        scale: 0.9,
        // La zone tactile reste d'au moins 48 px même si le rond est plus petit.
        child: SizedBox(
          width: math.max(size, 48),
          height: math.max(size, 48),
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? (context.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05))
                        : Colors.transparent,
                    border: filled
                        ? Border.all(color: c.ink.withValues(alpha: 0.08))
                        : null,
                  ),
                  child: Icon(icon, size: size * 0.5, color: c.ink),
                ),
                if (badge > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.brand,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: c.ground, width: 2),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sélecteurs ───────────────────────────────────────────────────────────────

/// Sélecteur à pastille coulissante.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.accent = false,
  });
  final List<({T value, String label})> items;
  final T value;
  final ValueChanged<T> onChanged;

  /// Pastille rouge au lieu de la pastille neutre.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final index = math.max(0, items.indexWhere((i) => i.value == value));
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: context.reduceMotion ? Duration.zero : Motion.base,
                curve: Motion.curve,
                left: width * index,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent
                        ? null
                        : (context.isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : c.card),
                    gradient: accent ? c.brandGradient : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (accent
                            ? c.glow
                            : Colors.black.withValues(alpha: 0.14)),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final item in items)
                    Expanded(
                      child: Pressable(
                        onTap: () => onChanged(item.value),
                        selected: item.value == value,
                        scale: 0.97,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: Motion.fast,
                            style: context.text.labelLarge!.copyWith(
                              fontSize: 14.5,
                              color: item.value == value
                                  ? (accent ? Colors.white : c.ink)
                                  : c.inkSoft,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Puce de choix (compte, moyen de paiement, filtre).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final foreground = selected ? Colors.white : c.ink;
    return Pressable(
      onTap: onTap,
      selected: selected,
      scale: 0.95,
      child: AnimatedContainer(
        duration: context.reduceMotion ? Duration.zero : Motion.fast,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? c.brand : c.raised,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Colors.white.withValues(alpha: 0.18) : c.line,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: c.glow,
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -6,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: selected ? Colors.white : c.inkSoft),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium?.copyWith(
                  fontSize: 14,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chiffres et animations ───────────────────────────────────────────────────

/// Compteur animé : le nombre défile jusqu'à sa nouvelle valeur (« number ticker » de Magic UI).
class NumberTicker extends StatelessWidget {
  const NumberTicker({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.semanticsLabel,
  });
  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value),
    duration: context.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 900),
    curve: Curves.easeOutExpo,
    builder: (context, shown, _) => Text(
      format(shown),
      maxLines: 1,
      softWrap: false,
      semanticsLabel: semanticsLabel ?? format(value),
      style: (style ?? DefaultTextStyle.of(context).style).copyWith(
        fontFeatures: tabular,
      ),
    ),
  );
}

/// Apparition en fondu avec un léger glissement, décalée selon `index` (« blur fade » de Magic UI).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 14,
  });
  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    // Au-delà de quelques éléments, le décalage ne grandit plus : rien n'attend pour apparaître.
    final delay = Duration(milliseconds: 45 * math.min(widget.index, 8));
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    final curve = CurvedAnimation(parent: _controller, curve: Motion.curve);
    return AnimatedBuilder(
      animation: curve,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curve.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

/// Faisceau lumineux qui parcourt le contour d'une carte (« border beam » de Magic UI).
class BorderBeam extends StatefulWidget {
  const BorderBeam({
    super.key,
    required this.child,
    this.radius = Radii.card,
    this.active = true,
    this.color = Colors.white,
  });
  final Widget child;
  final double radius;
  final bool active;
  final Color color;

  @override
  State<BorderBeam> createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  void _sync() => widget.active && !context.reduceMotion
      ? _controller.repeat()
      : _controller.stop();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BorderBeam old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return CustomPaint(
      foregroundPainter: _BeamPainter(_controller, widget.radius, widget.color),
      child: widget.child,
    );
  }
}

class _BeamPainter extends CustomPainter {
  _BeamPainter(this.progress, this.radius, this.color)
    : super(repaint: progress);
  final Animation<double> progress;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.75);
    final shader = SweepGradient(
      transform: GradientRotation(progress.value * 2 * math.pi),
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: 0),
        color.withValues(alpha: 0.95),
        color.withValues(alpha: 0),
      ],
      stops: const [0, 0.72, 0.92, 1],
    ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_BeamPainter old) =>
      old.radius != radius || old.color != color;
}

/// Anneau de progression animé, avec son contenu au centre.
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.value,
    required this.color,
    this.size = 56,
    this.stroke = 6,
    this.child,
  });

  /// De 0 à 1 (au-delà, l'anneau reste plein).
  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0, 1)),
    duration: context.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder: (context, shown, _) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(shown, color, context.moneo.raised, stroke),
        child: Center(child: child),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.stroke);
  final double value;
  final Color color, track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Barre de progression arrondie et animée.
class BarProgress extends StatelessWidget {
  const BarProgress({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
    this.semanticsLabel,
  });
  final double value;
  final Color color;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    value: '${(value * 100).round()} %',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: context.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, shown, _) => Container(
        height: height,
        decoration: BoxDecoration(
          color: context.moneo.raised,
          borderRadius: BorderRadius.circular(height),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: shown == 0 ? 0.001 : shown,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.lerp(color, Colors.white, 0.22)!, color],
              ),
              borderRadius: BorderRadius.circular(height),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ── Pastilles ────────────────────────────────────────────────────────────────

/// Pastille d'icône teintée (catégorie, réglage, type de notification).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
    this.solid = false,
  });
  final IconData icon;
  final Color color;
  final double size;

  /// Fond plein au lieu du fond teinté.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    // Sur fond teinté, l'icône est éclaircie (ou assombrie) pour garder au moins 3:1.
    final foreground = solid
        ? Colors.white
        : Color.lerp(
            color,
            dark ? Colors.white : Colors.black,
            dark ? 0.35 : 0.25,
          )!;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: solid ? null : color.withValues(alpha: dark ? 0.2 : 0.13),
          gradient: solid
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(color, Colors.white, 0.18)!, color],
                )
              : null,
          borderRadius: BorderRadius.circular(size * 0.34),
          border: Border.all(color: color.withValues(alpha: solid ? 0 : 0.22)),
        ),
        child: Icon(icon, size: size * 0.5, color: foreground),
      ),
    );
  }
}

/// Pastille d'une opération : l'icône de sa catégorie, remplacée par une coche verte une fois pointée.
/// Un appui pointe ou dépointe.
class CheckBadge extends StatelessWidget {
  const CheckBadge({
    super.key,
    required this.checked,
    required this.icon,
    required this.color,
    this.onChanged,
  });
  final bool checked;
  final IconData icon;
  final Color color;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    return Semantics(
      checked: checked,
      button: true,
      enabled: onChanged != null,
      label: checked ? 'Pointée' : 'À pointer',
      hint: onChanged == null
          ? null
          : (checked ? 'Appuyer pour dépointer' : 'Appuyer pour pointer'),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onChanged!(!checked);
              },
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: AnimatedSwitcher(
              duration: context.reduceMotion ? Duration.zero : Motion.base,
              switchInCurve: Motion.spring,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: checked
                  ? Container(
                      key: const ValueKey('on'),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.income.withValues(alpha: 0.16),
                        border: Border.all(
                          color: c.income.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: c.income,
                        size: 24,
                      ),
                    )
                  : IconBadge(
                      key: const ValueKey('off'),
                      icon: icon,
                      color: color,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Navigation ───────────────────────────────────────────────────────────────

typedef DockItem = ({IconData icon, IconData activeIcon, String label});

/// Barre de navigation flottante : une capsule de verre, l'onglet actif s'étire et affiche son nom.
class FloatingDock extends StatelessWidget {
  const FloatingDock({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });
  final List<DockItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, math.max(bottom, Gap.md)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDark ? 0.5 : 0.16,
              ),
              blurRadius: 32,
              offset: const Offset(0, 14),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (context.isDark ? const Color(0xFF1B1B1F) : Colors.white)
                    .withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: c.ink.withValues(alpha: 0.09)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      flex: i == index ? 22 : 10,
                      child: Pressable(
                        onTap: () => onTap(i),
                        selected: i == index,
                        label: items[i].label,
                        scale: 0.94,
                        child: AnimatedContainer(
                          duration: context.reduceMotion
                              ? Duration.zero
                              : Motion.base,
                          curve: Motion.curve,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: i == index ? c.brandGradient : null,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              if (i == index)
                                BoxShadow(
                                  color: c.glow,
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                  spreadRadius: -6,
                                ),
                            ],
                          ),
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  i == index
                                      ? items[i].activeIcon
                                      : items[i].icon,
                                  size: 23,
                                  color: i == index ? Colors.white : c.inkSoft,
                                ),
                                if (i == index) ...[
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      items[i].label,
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      style: context.text.labelLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
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
}

// ── Listes groupées ──────────────────────────────────────────────────────────

/// Petit titre de groupe, en capitales espacées.
class GroupLabel extends StatelessWidget {
  const GroupLabel(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      Gap.page + 4,
      Gap.xl,
      Gap.page,
      Gap.sm,
    ),
  });
  final String text;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: context.moneo.inkSoft,
              ),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

/// Carte qui regroupe des lignes, séparées par un filet.
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: Gap.lg),
  });
  final List<Widget> children;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => MCard(
    margin: margin,
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(left: 74),
              child: Container(height: 1, color: context.moneo.line),
            ),
          children[i],
        ],
      ],
    ),
  );
}

/// Ligne d'une liste groupée : pastille colorée, titre, détail, action à droite.
class GroupTile extends StatelessWidget {
  const GroupTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.leading,
    this.trailing,
    this.onTap,
    this.danger = false,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 13),
      child: Row(
        children: [
          leading ??
              IconBadge(
                icon: icon ?? Icons.circle_outlined,
                color: danger ? context.scheme.error : (color ?? c.inkSoft),
                size: 42,
              ),
          const SizedBox(width: Gap.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: danger ? context.scheme.error : null,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: c.inkSoft),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Gap.sm),
          trailing ??
              (onTap == null
                  ? const SizedBox.shrink()
                  : Icon(
                      Icons.chevron_right_rounded,
                      color: c.inkSoft,
                      size: 22,
                    )),
        ],
      ),
    );
    if (onTap == null) return row;
    return Pressable(onTap: onTap, scale: 0.985, haptic: false, child: row);
  }
}

/// Interrupteur Moneo : pastille qui glisse, rouge une fois activé.
class MSwitch extends StatelessWidget {
  const MSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    return Semantics(
      toggled: value,
      label: label,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              },
        child: SizedBox(
          width: 56,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: context.reduceMotion ? Duration.zero : Motion.base,
              curve: Motion.curve,
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: value ? c.brandGradient : null,
                color: value ? null : c.raised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: value
                      ? Colors.white.withValues(alpha: 0.18)
                      : c.perforation,
                ),
                boxShadow: [
                  if (value)
                    BoxShadow(
                      color: c.glow,
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: AnimatedAlign(
                duration: context.reduceMotion ? Duration.zero : Motion.base,
                curve: Motion.spring,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? Colors.white : c.inkSoft,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne avec interrupteur : toute la ligne est tactile.
class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.color,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    enabled: onChanged != null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 9),
        child: Row(
          children: [
            if (icon != null) ...[
              IconBadge(
                icon: icon!,
                color: color ?? context.moneo.inkSoft,
                size: 42,
              ),
              const SizedBox(width: Gap.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: context.text.bodySmall?.copyWith(
                        color: context.moneo.inkSoft,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Gap.sm),
            ExcludeSemantics(
              child: IgnorePointer(
                child: MSwitch(value: value, onChanged: onChanged),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Signale aux écrans qu'une barre de navigation flottante occupe le bas de la fenêtre.
class DockInset extends InheritedWidget {
  const DockInset({super.key, required this.height, required super.child});
  final double height;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DockInset>()?.height ?? 0;

  @override
  bool updateShouldNotify(DockInset old) => old.height != height;
}

/// Bouton d'ajout flottant d'un écran de liste, posé au-dessus de la barre de navigation.
class AddButton extends StatelessWidget {
  const AddButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: DockInset.of(context)),
    child: PrimaryButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      expand: false,
      height: 54,
    ),
  );
}
