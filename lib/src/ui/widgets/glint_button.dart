import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GlintStyle { filled, tonal, outline }

/// Button with a light sweep ("glint") on hover/press, a small press-scale
/// and a keyboard focus ring.
class GlintButton extends StatefulWidget {
  const GlintButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = GlintStyle.filled,
    this.busy = false,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlintStyle style;

  /// Shows a spinner and ignores presses.
  final bool busy;

  /// Fill the available width.
  final bool expand;
  final bool compact;

  @override
  State<GlintButton> createState() => _GlintButtonState();
}

class _GlintButtonState extends State<GlintButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glint = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 750));
  bool _hover = false;
  bool _focus = false;
  bool _down = false;

  bool get _enabled => widget.onPressed != null && !widget.busy;

  @override
  void dispose() {
    _glint.dispose();
    super.dispose();
  }

  void _shine() {
    if (_enabled && !MediaQuery.disableAnimationsOf(context)) {
      _glint.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    switch (widget.style) {
      case GlintStyle.filled:
        bg = cs.primary;
        fg = cs.onPrimary;
      case GlintStyle.tonal:
        bg = cs.primaryContainer;
        fg = cs.onSurface;
      case GlintStyle.outline:
        bg = Colors.transparent;
        fg = cs.onSurface;
    }
    final Color glint = widget.style == GlintStyle.filled
        ? (bg.computeLuminance() > 0.7
            ? Colors.black.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.55))
        : cs.primary.withValues(alpha: 0.30);

    final radius = BorderRadius.circular(widget.compact ? 12 : 14);
    final borderColor = _focus
        ? cs.primary
        : (widget.style == GlintStyle.outline
            ? (_hover ? cs.primary : cs.outlineVariant)
            : Colors.transparent);

    final padding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 22, vertical: 15);
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );

    final leading = widget.busy
        ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : (widget.icon == null ? null : Icon(widget.icon, size: 18, color: fg));

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 8)],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.label, style: textStyle, maxLines: 1),
          ),
        ),
      ],
    );

    return FocusableActionDetector(
      enabled: _enabled,
      mouseCursor:
          _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) {
        setState(() => _hover = v);
        if (v) _shine();
      },
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          _shine();
          widget.onPressed?.call();
          return null;
        }),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: widget.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (!_enabled) return;
            setState(() => _down = true);
            _shine();
          },
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _down ? 0.96 : (_hover ? 1.012 : 1),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: (_enabled || widget.busy) ? 1 : 0.45,
              duration: const Duration(milliseconds: 160),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: radius,
                  border: Border.all(
                      color: borderColor, width: _focus ? 2 : 1),
                  boxShadow: widget.style == GlintStyle.filled && _hover
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: -2,
                          ),
                        ]
                      : const [],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: CustomPaint(
                    foregroundPainter: _GlintPainter(_glint, glint),
                    child: Padding(padding: padding, child: content),
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

/// Paints a slanted soft band sweeping left to right as [animation] runs 0..1.
class _GlintPainter extends CustomPainter {
  _GlintPainter(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0 || t >= 1) return;
    final band = size.width * 0.45;
    final slant = size.height * 0.6;
    final x = -band - slant +
        (size.width + band * 2 + slant * 2) * Curves.easeInOut.transform(t);
    final path = Path()
      ..moveTo(x + slant, 0)
      ..lineTo(x + slant + band, 0)
      ..lineTo(x + band, size.height)
      ..lineTo(x, size.height)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(x, 0, band + slant, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlintPainter old) =>
      old.color != color || old.animation != animation;
}
