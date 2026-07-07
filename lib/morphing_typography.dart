import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// 1. Demo Screen
// ─────────────────────────────────────────────
class MorphingTypographyDemo extends StatefulWidget {
  const MorphingTypographyDemo({super.key});

  @override
  State<MorphingTypographyDemo> createState() => _MorphingTypographyDemoState();
}

class _MorphingTypographyDemoState extends State<MorphingTypographyDemo> {
  final List<_TextPreset> _presets = const [
    _TextPreset('HELLO',   'WORLD',   Color(0xFF6366F1), Color(0xFFEC4899)),
    _TextPreset('FLUTTER', 'AMAZING', Color(0xFF06B6D4), Color(0xFF10B981)),
    _TextPreset('DESIGN',  'MOTION',  Color(0xFFF59E0B), Color(0xFFEF4444)),
    _TextPreset('CREATE',  'INSPIRE', Color(0xFF8B5CF6), Color(0xFFF97316)),
  ];

  int _presetIndex = 0;
  int _morphStyle  = 0;
  final List<String> _styleNames = ['Blur Morph', 'Scatter', 'Wave'];

  @override
  Widget build(BuildContext context) {
    final preset = _presets[_presetIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Morphing Typography',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Display area ──
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    preset.fromColor.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: MorphingText(
                  key: ValueKey('$_presetIndex-$_morphStyle'),
                  fromText: preset.from,
                  toText:   preset.to,
                  fromColor: preset.fromColor,
                  toColor:   preset.toColor,
                  style:     _morphStyle,
                  autoRepeat: true,
                ),
              ),
            ),
          ),

          // ── Style selector ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(_styleNames.length, (i) {
                final selected = i == _morphStyle;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _morphStyle = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? preset.fromColor.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? preset.fromColor : Colors.white12,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _styleNames[i],
                        style: TextStyle(
                          color: selected ? preset.fromColor : Colors.white38,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // ── Preset selector ──
          SizedBox(
            height: 80,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = _presets[i];
                final selected = i == _presetIndex;
                return GestureDetector(
                  onTap: () => setState(() => _presetIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(colors: [p.fromColor, p.toColor])
                          : null,
                      color: selected ? null : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? Colors.transparent : Colors.white12,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: p.fromColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.from, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Icon(Icons.arrow_downward_rounded, size: 10, color: selected ? Colors.white70 : Colors.white24),
                        const SizedBox(height: 2),
                        Text(p.to, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. MorphingText controller
// ─────────────────────────────────────────────
class MorphingText extends StatefulWidget {
  final String fromText;
  final String toText;
  final Color fromColor;
  final Color toColor;
  final int style;
  final bool autoRepeat;

  const MorphingText({
    super.key,
    required this.fromText,
    required this.toText,
    required this.fromColor,
    required this.toColor,
    this.style = 0,
    this.autoRepeat = false,
  });

  @override
  State<MorphingText> createState() => _MorphingTextState();
}

class _MorphingTextState extends State<MorphingText> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.autoRepeat) _startLoop();
  }

  Future<void> _startLoop() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    await _runOnce();
  }

  Future<void> _runOnce() async {
    await _controller.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted && widget.autoRepeat) _runOnce();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return switch (widget.style) {
          1 => _MorphPainterWidget(
              fromText: widget.fromText, toText: widget.toText,
              fromColor: widget.fromColor, toColor: widget.toColor,
              progress: t, mode: _MorphMode.scatter,
            ),
          2 => _MorphPainterWidget(
              fromText: widget.fromText, toText: widget.toText,
              fromColor: widget.fromColor, toColor: widget.toColor,
              progress: t, mode: _MorphMode.wave,
            ),
          _ => _MorphPainterWidget(
              fromText: widget.fromText, toText: widget.toText,
              fromColor: widget.fromColor, toColor: widget.toColor,
              progress: t, mode: _MorphMode.blur,
            ),
        };
      },
    );
  }
}

// ─────────────────────────────────────────────
// 3. Unified CustomPainter approach
//    – đo width thật của từng ký tự bằng TextPainter
//    – căn giữa toàn bộ chuỗi trên canvas
// ─────────────────────────────────────────────
enum _MorphMode { blur, scatter, wave }

class _MorphPainterWidget extends StatelessWidget {
  final String fromText;
  final String toText;
  final Color fromColor;
  final Color toColor;
  final double progress;
  final _MorphMode mode;

  const _MorphPainterWidget({
    super.key,
    required this.fromText,
    required this.toText,
    required this.fromColor,
    required this.toColor,
    required this.progress,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return CustomPaint(
      size: Size(screenW, 160),
      painter: _MorphPainter(
        fromText: fromText,
        toText: toText,
        fromColor: fromColor,
        toColor: toColor,
        progress: progress,
        mode: mode,
      ),
    );
  }
}

class _MorphPainter extends CustomPainter {
  final String fromText;
  final String toText;
  final Color fromColor;
  final Color toColor;
  final double progress;
  final _MorphMode mode;

  // Font config – một chỗ duy nhất
  static const double _fontSize    = 62.0;
  static const double _letterSpace = 14.0; // khoảng cách giữa các ký tự (px)

  _MorphPainter({
    required this.fromText,
    required this.toText,
    required this.fromColor,
    required this.toColor,
    required this.progress,
    required this.mode,
  });

  // ── Đo width thật của 1 ký tự ──
  double _charWidth(String ch, {double scale = 1.0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          fontSize: _fontSize * scale,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  // ── Tính danh sách vị trí x căn giữa cho một chuỗi ──
  // Trả về list offset x của tâm từng ký tự
  List<double> _centerPositions(String text, double canvasWidth, {double scale = 1.0}) {
    if (text.isEmpty) return [];
    final widths = [for (final ch in text.split('')) _charWidth(ch, scale: scale)];
    final totalW = widths.fold(0.0, (a, b) => a + b) + _letterSpace * (text.length - 1);
    double startX = (canvasWidth - totalW) / 2;
    final positions = <double>[];
    for (final w in widths) {
      positions.add(startX + w / 2);
      startX += w + _letterSpace;
    }
    return positions;
  }

  // ── Vẽ 1 ký tự căn giữa tại (cx, cy) với scale & color ──
  void _drawChar(
    Canvas canvas,
    String ch,
    double cx,
    double cy,
    Color color, {
    double scale = 1.0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          fontSize: _fontSize * scale,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final maxLen = math.max(fromText.length, toText.length);

    // Tính vị trí x cho FROM và TO (dùng cùng 1 lưới dựa trên maxLen)
    // Để tránh layout nhảy, ta dùng lưới của chuỗi dài hơn làm gốc,
    // và map từng ký tự của chuỗi ngắn hơn vào đúng slot.
    final longerText = fromText.length >= toText.length ? fromText : toText;
    final basePositions = _centerPositions(longerText, size.width);

    // Nếu chuỗi ngắn hơn, căn giữa trong lưới của chuỗi dài hơn:
    // từ slot (maxLen - shorter.length)/2
    final fromOffset = (maxLen - fromText.length) ~/ 2;
    final toOffset   = (maxLen - toText.length)   ~/ 2;

    switch (mode) {
      case _MorphMode.blur:
        _paintBlur(canvas, size, cy, basePositions, fromOffset, toOffset, maxLen);
      case _MorphMode.scatter:
        _paintScatter(canvas, size, cy, basePositions, fromOffset, toOffset, maxLen);
      case _MorphMode.wave:
        _paintWave(canvas, size, cy, basePositions, fromOffset, toOffset, maxLen);
    }
  }

  // ────────── BLUR MORPH ──────────
  void _paintBlur(Canvas canvas, Size size, double cy,
      List<double> basePos, int fromOff, int toOff, int maxLen) {
    for (int i = 0; i < maxLen; i++) {
      final fromIdx = i - fromOff;
      final toIdx   = i - toOff;
      final fromChar = (fromIdx >= 0 && fromIdx < fromText.length) ? fromText[fromIdx] : null;
      final toChar   = (toIdx   >= 0 && toIdx   < toText.length)   ? toText[toIdx]     : null;
      final cx = basePos[i];

      // Stagger: ký tự bên trái biến đổi trước
      final stagger  = i / maxLen;
      final outT     = ((progress / (0.35 + stagger * 0.35)).clamp(0.0, 1.0));
      final inT      = (((progress - 0.3 - stagger * 0.25) / 0.55).clamp(0.0, 1.0));

      final outAlpha = (1.0 - Curves.easeIn.transform(outT)).clamp(0.0, 1.0);
      final inAlpha  = Curves.easeOut.transform(inT).clamp(0.0, 1.0);
      final outBlur  = Curves.easeIn.transform(outT) * 14.0;
      final inBlur   = (1.0 - Curves.easeOut.transform(inT)) * 14.0;

      // FROM – blur out
      if (fromChar != null && outAlpha > 0.01) {
        canvas.saveLayer(
          Rect.fromCenter(center: Offset(cx, cy), width: _fontSize * 2, height: _fontSize * 2),
          Paint(),
        );
        if (outBlur > 0.1) {
          canvas.saveLayer(null, Paint()..imageFilter = ImageFilter.blur(sigmaX: outBlur, sigmaY: outBlur));
        }
        _drawChar(canvas, fromChar, cx, cy, fromColor.withValues(alpha: outAlpha));
        if (outBlur > 0.1) canvas.restore();
        canvas.restore();
      }

      // TO – blur in
      if (toChar != null && inAlpha > 0.01) {
        canvas.saveLayer(
          Rect.fromCenter(center: Offset(cx, cy), width: _fontSize * 2, height: _fontSize * 2),
          Paint(),
        );
        if (inBlur > 0.1) {
          canvas.saveLayer(null, Paint()..imageFilter = ImageFilter.blur(sigmaX: inBlur, sigmaY: inBlur));
        }
        _drawChar(canvas, toChar, cx, cy, toColor.withValues(alpha: inAlpha));
        if (inBlur > 0.1) canvas.restore();
        canvas.restore();
      }
    }
  }

  // ────────── SCATTER MORPH ──────────
  void _paintScatter(Canvas canvas, Size size, double cy,
      List<double> basePos, int fromOff, int toOff, int maxLen) {
    final rng = math.Random(42);
    for (int i = 0; i < maxLen; i++) {
      final fromIdx = i - fromOff;
      final toIdx   = i - toOff;
      final fromChar = (fromIdx >= 0 && fromIdx < fromText.length) ? fromText[fromIdx] : null;
      final toChar   = (toIdx   >= 0 && toIdx   < toText.length)   ? toText[toIdx]     : null;
      final cx = basePos[i];

      final stagger = i / maxLen;
      final outT    = ((progress - stagger * 0.2) / 0.55).clamp(0.0, 1.0);
      final inT     = ((progress - 0.35 - stagger * 0.2) / 0.55).clamp(0.0, 1.0);

      // FROM – scatter out
      if (fromChar != null) {
        final scatter = Curves.easeIn.transform(outT);
        final angle   = rng.nextDouble() * math.pi * 2;
        final dist    = scatter * 70;
        final dx      = cx + math.cos(angle) * dist;
        final dy      = cy + math.sin(angle) * dist;
        final alpha   = (1.0 - scatter).clamp(0.0, 1.0);
        final scale   = 1.0 - scatter * 0.6;
        if (alpha > 0.01) {
          _drawChar(canvas, fromChar, dx, dy, fromColor.withValues(alpha: alpha), scale: scale);
        }
      }

      // TO – gather in
      if (toChar != null) {
        final gather = Curves.easeOut.transform(inT);
        final angle  = rng.nextDouble() * math.pi * 2 + math.pi;
        final dist   = (1.0 - gather) * 70;
        final dx     = cx + math.cos(angle) * dist;
        final dy     = cy + math.sin(angle) * dist;
        final alpha  = gather.clamp(0.0, 1.0);
        final scale  = 0.3 + gather * 0.7;
        if (alpha > 0.01) {
          _drawChar(canvas, toChar, dx, dy, toColor.withValues(alpha: alpha), scale: scale);
        }
      }
    }
  }

  // ────────── WAVE MORPH ──────────
  void _paintWave(Canvas canvas, Size size, double cy,
      List<double> basePos, int fromOff, int toOff, int maxLen) {
    for (int i = 0; i < maxLen; i++) {
      final fromIdx = i - fromOff;
      final toIdx   = i - toOff;
      final fromChar = (fromIdx >= 0 && fromIdx < fromText.length) ? fromText[fromIdx] : null;
      final toChar   = (toIdx   >= 0 && toIdx   < toText.length)   ? toText[toIdx]     : null;
      final cx = basePos[i];

      final stagger  = i / maxLen;
      final wave     = ((progress - stagger * 0.35) / 0.65).clamp(0.0, 1.0);
      final outPhase = (wave * 2).clamp(0.0, 1.0);
      final inPhase  = ((wave - 0.5) * 2).clamp(0.0, 1.0);

      final outY     = -Curves.easeIn.transform(outPhase) * 80.0;
      final inY      = (1.0 - Curves.easeOut.transform(inPhase)) * 80.0;
      final outAlpha = (1.0 - Curves.easeIn.transform(outPhase)).clamp(0.0, 1.0);
      final inAlpha  = Curves.easeOut.transform(inPhase).clamp(0.0, 1.0);

      // FROM – flies up
      if (fromChar != null && outAlpha > 0.01) {
        _drawChar(canvas, fromChar, cx, cy + outY, fromColor.withValues(alpha: outAlpha));
      }
      // TO – drops in
      if (toChar != null && inAlpha > 0.01) {
        _drawChar(canvas, toChar, cx, cy - inY, toColor.withValues(alpha: inAlpha));
      }
    }
  }

  @override
  bool shouldRepaint(_MorphPainter old) =>
      old.progress != progress ||
      old.fromText != fromText ||
      old.toText != toText ||
      old.mode != mode;
}

// ─────────────────────────────────────────────
// 4. Data model
// ─────────────────────────────────────────────
class _TextPreset {
  final String from;
  final String to;
  final Color fromColor;
  final Color toColor;

  const _TextPreset(this.from, this.to, this.fromColor, this.toColor);
}
