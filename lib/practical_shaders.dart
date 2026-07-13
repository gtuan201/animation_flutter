import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRACTICAL SHADERS — 3 shader thực tế cho app production
//
// 1. ShimmerBox     — skeleton loading placeholder
// 2. HoloCard       — thẻ holographic đổi màu theo nghiêng
// 3. AuroraBackground — nền aurora bắc cực động cho splash/hero
// ─────────────────────────────────────────────────────────────────────────────

// ── Helper load + cache shader ──
class _ShaderCache {
  _ShaderCache._();
  static final Map<String, ui.FragmentProgram> _cache = {};

  static Future<ui.FragmentProgram?> load(String path) async {
    if (_cache.containsKey(path)) return _cache[path];
    try {
      final p = await ui.FragmentProgram.fromAsset(path);
      _cache[path] = p;
      return p;
    } catch (_) {
      return null;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. SHIMMER BOX — Skeleton loading placeholder với shader
// ═════════════════════════════════════════════════════════════════════════════

/// Wrapper bao quanh bất kỳ widget nào, phủ shimmer khi [loading] = true.
/// Khi [loading] = false: hiện content bình thường.
class ShimmerBox extends StatefulWidget {
  final Widget child;
  final bool loading;
  final BorderRadius? borderRadius;
  final Color baseColor;
  final Color shimmerColor;
  final double speed;

  const ShimmerBox({
    super.key,
    required this.child,
    this.loading = true,
    this.borderRadius,
    this.baseColor = const Color(0xFF1E293B),
    this.shimmerColor = const Color(0xFF334155),
    this.speed = 1.0,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _prog;
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (widget.loading) setState(() => _time = elapsed.inMicroseconds / 1e6);
    })..start();
    _ShaderCache.load('shaders/shimmer.frag').then((p) {
      if (mounted) setState(() => _prog = p);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loading) return widget.child;
    if (_prog == null) {
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: ColoredBox(color: widget.baseColor, child: widget.child),
      );
    }
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            painter: _ShimmerPainter(
              program: _prog!,
              time: _time,
              speed: widget.speed,
              baseColor: widget.baseColor,
              shimColor: widget.shimmerColor,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final double speed;
  final Color baseColor;
  final Color shimColor;

  _ShimmerPainter({
    required this.program,
    required this.time,
    required this.speed,
    required this.baseColor,
    required this.shimColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, speed);
    // uBaseColor RGBA
    shader.setFloat(4, baseColor.r);
    shader.setFloat(5, baseColor.g);
    shader.setFloat(6, baseColor.b);
    shader.setFloat(7, baseColor.a);
    // uShimColor RGBA
    shader.setFloat(8, shimColor.r);
    shader.setFloat(9, shimColor.g);
    shader.setFloat(10, shimColor.b);
    shader.setFloat(11, shimColor.a);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.time != time;
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. HOLOGRAPHIC CARD — thẻ hologram đổi màu theo nghiêng chuột / gyroscope
// ═════════════════════════════════════════════════════════════════════════════

/// Card holographic dùng shader. Truyền vào [child] là nội dung thẻ,
/// shader sẽ vẽ lớp holographic phía trên với blend mode Screen.
class HoloCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const HoloCard({
    super.key,
    required this.child,
    this.width = 340,
    this.height = 210,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<HoloCard> createState() => _HoloCardState();
}

class _HoloCardState extends State<HoloCard>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _prog;
  late final Ticker _ticker;
  double _time = 0;
  Offset _tilt = Offset.zero;     // -1..1
  double _glare = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMicroseconds / 1e6;
        // Tilt trở về 0 nếu không tương tác
        _tilt = _tilt * 0.93;
        _glare *= 0.92;
      });
    })..start();
    _ShaderCache.load('shaders/holographic.frag').then((p) {
      if (mounted) setState(() => _prog = p);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onHover(Offset local) {
    final x = (local.dx / widget.width - 0.5) * 2;
    final y = (local.dy / widget.height - 0.5) * 2;
    _tilt = Offset(x, y);
    _glare = 1.0 - (x * x + y * y).clamp(0.0, 1.0) * 0.6;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => _onHover(e.localPosition),
      child: GestureDetector(
        onPanUpdate: (d) => _onHover(d.localPosition),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-_tilt.dy * 0.3)
            ..rotateY(_tilt.dx * 0.3),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Content layer
                  widget.child,
                  // Holographic overlay
                  if (_prog != null)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _HoloPainter(
                          program: _prog!,
                          time: _time,
                          tilt: _tilt,
                          glare: _glare,
                        ),
                        child: const SizedBox.expand(),
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

class _HoloPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final Offset tilt;
  final double glare;

  _HoloPainter({
    required this.program,
    required this.time,
    required this.tilt,
    required this.glare,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, tilt.dx);
    shader.setFloat(4, tilt.dy);
    shader.setFloat(5, glare);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.screen,
    );
  }

  @override
  bool shouldRepaint(_HoloPainter old) => old.time != time || old.tilt != tilt;
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. AURORA BACKGROUND — nền cực quang động dùng cho splash / profile header
// ═════════════════════════════════════════════════════════════════════════════

/// Nền aurora bán trong suốt, vẽ bên dưới content.
/// [colors] nhận 3 màu cho 3 dải aurora.
class AuroraBackground extends StatefulWidget {
  final Widget? child;
  final List<Color> colors;
  final Color bgColor;

  const AuroraBackground({
    super.key,
    this.child,
    this.colors = const [
      Color(0xFF00FF88),  // xanh lá
      Color(0xFF0088FF),  // xanh dương
      Color(0xFFAA00FF),  // tím
    ],
    this.bgColor = const Color(0xFF060B14),
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _prog;
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMicroseconds / 1e6);
    })..start();
    _ShaderCache.load('shaders/aurora.frag').then((p) {
      if (mounted) setState(() => _prog = p);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.bgColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_prog != null)
            CustomPaint(
              painter: _AuroraPainter(
                program: _prog!,
                time: _time,
                c1: widget.colors[0],
                c2: widget.colors[1],
                c3: widget.colors.length > 2 ? widget.colors[2] : widget.colors[0],
              ),
            ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final Color c1, c2, c3;

  _AuroraPainter({
    required this.program,
    required this.time,
    required this.c1,
    required this.c2,
    required this.c3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    // uColor1
    shader.setFloat(3, c1.r);
    shader.setFloat(4, c1.g);
    shader.setFloat(5, c1.b);
    shader.setFloat(6, 0.85);
    // uColor2
    shader.setFloat(7, c2.r);
    shader.setFloat(8, c2.g);
    shader.setFloat(9, c2.b);
    shader.setFloat(10, 0.75);
    // uColor3
    shader.setFloat(11, c3.r);
    shader.setFloat(12, c3.g);
    shader.setFloat(13, c3.b);
    shader.setFloat(14, 0.65);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.time != time;
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN — Giới thiệu cả 3 shader trong ngữ cảnh thực tế
// ─────────────────────────────────────────────────────────────────────────────

class PracticalShadersDemo extends StatefulWidget {
  const PracticalShadersDemo({super.key});

  @override
  State<PracticalShadersDemo> createState() => _PracticalShadersDemoState();
}

class _PracticalShadersDemoState extends State<PracticalShadersDemo> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: AuroraBackground(
        colors: const [Color(0xFF00FF88), Color(0xFF0055FF), Color(0xFF8800FF)],
        child: CustomScrollView(
          slivers: [
            // ── Profile hero header với aurora ──
            SliverAppBar(
              expandedHeight: 240,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Practical Shaders',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient phủ để text đọc được
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC060B14)],
                        ),
                      ),
                    ),
                    // Avatar giả
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Color(0xFF1E293B),
                            child: Icon(Icons.person_rounded, size: 40, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── 1. Shimmer Loading ──
                  _SectionTitle('① Shimmer Loading Skeleton'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Giả lập loading:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      const Spacer(),
                      Switch(
                        value: _loading,
                        onChanged: (v) => setState(() => _loading = v),
                        activeThumbColor: const Color(0xFF00FF88),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Shimmer card
                  ShimmerBox(
                    loading: _loading,
                    borderRadius: BorderRadius.circular(16),
                    baseColor: const Color(0xFF1E293B),
                    shimmerColor: const Color(0xFF2D4A6B),
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _loading
                          ? const SizedBox.shrink()
                          : const Row(
                              children: [
                                CircleAvatar(backgroundColor: Color(0xFF334155), radius: 28),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Tuan Nguyen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                      SizedBox(height: 4),
                                      Text('Flutter Developer', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Shimmer rows
                  ...List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ShimmerBox(
                      loading: _loading,
                      borderRadius: BorderRadius.circular(10),
                      baseColor: const Color(0xFF1E293B),
                      shimmerColor: const Color(0xFF2D4A6B),
                      child: Container(
                        height: 14,
                        width: double.infinity,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  )),

                  const SizedBox(height: 32),

                  // ── 2. Holographic Card ──
                  _SectionTitle('② Holographic Card'),
                  const SizedBox(height: 4),
                  const Text('Di chuột / kéo để thấy vân hologram',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 16),
                  Center(
                    child: HoloCard(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('PREMIUM', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Text('4532 •••• •••• 7891',
                                style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CARD HOLDER', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                                    SizedBox(height: 2),
                                    Text('TUAN NGUYEN', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                                  ],
                                ),
                                const Spacer(),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('EXPIRES', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                                    SizedBox(height: 2),
                                    Text('12/27', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── 3. Aurora Background usage note ──
                  _SectionTitle('③ Aurora Background'),
                  const SizedBox(height: 4),
                  const Text('Nền cực quang đang chạy phía sau toàn màn hình này',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 16),
                  // Mini demo box
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 140,
                      child: AuroraBackground(
                        colors: const [Color(0xFFFF00AA), Color(0xFF00DDFF), Color(0xFF7700FF)],
                        child: const Center(
                          child: Text('Swipe trong app Login / Splash',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Usage code hint
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cách dùng:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Text(
                          'ShimmerBox(loading: true, child: ...)\n'
                          'HoloCard(child: CardContent())\n'
                          'AuroraBackground(colors: [...], child: ...)',
                          style: TextStyle(color: Color(0xFF00FF88), fontSize: 12, fontFamily: 'monospace', height: 1.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15));
  }
}
