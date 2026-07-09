import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHATTER GLASS TRANSITION - Vỡ kính (Glass Shatter)
// Màn hình nứt vỡ như tấm kính bị đập từ điểm chạm: sinh ra hàng chục mảnh
// tam giác toả tròn, mỗi mảnh rơi - xoay theo trọng lực - mờ dần, cạnh vỡ
// lóe sáng như phản quang. Mảnh gần điểm va vỡ trước, lan dần ra ngoài.
// ─────────────────────────────────────────────────────────────────────────────

const List<Color> _kGlassGradient = [Color(0xFF60A5FA), Color(0xFF818CF8), Color(0xFFA78BFA)];

/// PageRoute với hiệu ứng Shatter Glass
class ShatterGlassPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset? impact;

  ShatterGlassPageRoute({
    required this.page,
    this.impact,
  }) : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 1500),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final size = MediaQuery.of(context).size;
            final p = impact ?? size.center(Offset.zero);
            return Stack(
              fit: StackFit.expand,
              children: [
                child,
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      if (animation.value >= 0.999) return const SizedBox.shrink();
                      return CustomPaint(
                        size: size,
                        painter: GlassShatterPainter(
                          progress: animation.value,
                          impact: p,
                          colors: _kGlassGradient,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
}

/// Một mảnh kính tam giác
class _Shard {
  final List<Offset> pts;
  final Offset centroid;
  final double delay; // theo khoảng cách tới điểm va
  final double rotDir;
  final double spin;
  final double driftAngle;

  _Shard(this.pts, this.centroid, this.delay, this.rotDir, this.spin, this.driftAngle);
}

/// Painter vỡ kính. Sinh mảnh 1 lần rồi cache theo size + impact.
class GlassShatterPainter extends CustomPainter {
  final double progress;
  final Offset impact;
  final List<Color> colors;

  GlassShatterPainter({
    required this.progress,
    required this.impact,
    required this.colors,
  });

  static List<_Shard>? _cache;
  static Size? _cacheSize;
  static Offset? _cacheImpact;

  List<_Shard> _buildShards(Size size) {
    if (_cache != null && _cacheSize == size && _cacheImpact == impact) {
      return _cache!;
    }
    final rng = math.Random(99);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height) * 0.85;

    const rays = 18;
    final ringFactors = [0.0, 0.16, 0.36, 0.62, 1.0, 1.5];

    // Lưới điểm cực (polar) quanh điểm va + jitter cho tự nhiên
    final grid = <List<Offset>>[];
    for (int j = 0; j < ringFactors.length; j++) {
      final ring = <Offset>[];
      for (int i = 0; i < rays; i++) {
        if (j == 0) {
          ring.add(impact);
          continue;
        }
        final angle = (i / rays) * math.pi * 2 + rng.nextDouble() * 0.12;
        final rad = maxR * ringFactors[j] * (0.85 + rng.nextDouble() * 0.3);
        ring.add(impact + Offset(math.cos(angle) * rad, math.sin(angle) * rad));
      }
      grid.add(ring);
    }

    final shards = <_Shard>[];
    void addShard(List<Offset> pts) {
      final cx = (pts[0].dx + pts[1].dx + pts[2].dx) / 3;
      final cy = (pts[0].dy + pts[1].dy + pts[2].dy) / 3;
      final centroid = Offset(cx, cy);
      final d = (centroid - impact).distance / maxR;
      final drift = math.atan2(cy - impact.dy, cx - impact.dx);
      shards.add(_Shard(
        pts,
        centroid,
        d.clamp(0.0, 1.0),
        rng.nextBool() ? 1 : -1,
        0.6 + rng.nextDouble() * 2.2,
        drift + (rng.nextDouble() - 0.5) * 0.6,
      ));
    }

    // Fan tam giác trong cùng (quanh điểm va)
    for (int i = 0; i < rays; i++) {
      final ni = (i + 1) % rays;
      addShard([impact, grid[1][i], grid[1][ni]]);
    }
    // Các vành ngoài: mỗi quad tách 2 tam giác
    for (int j = 1; j < ringFactors.length - 1; j++) {
      for (int i = 0; i < rays; i++) {
        final ni = (i + 1) % rays;
        final a = grid[j][i];
        final b = grid[j][ni];
        final c = grid[j + 1][ni];
        final d = grid[j + 1][i];
        addShard([a, b, c]);
        addShard([a, c, d]);
      }
    }

    _cache = shards;
    _cacheSize = size;
    _cacheImpact = impact;
    return shards;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final shards = _buildShards(size);

    // Gravity + fall
    for (final s in shards) {
      // Mảnh gần điểm va vỡ trước
      final start = s.delay * 0.45;
      const window = 0.55;
      final local = ((progress - start) / window).clamp(0.0, 1.0);

      if (local <= 0.0) {
        // Chưa vỡ: vẽ tại chỗ (kính nguyên) + đường nứt
        _drawShard(canvas, s, size, Offset.zero, 0.0, 1.0, 1.0, crackGlow: _crackGlow(s.delay));
        continue;
      }
      if (local >= 1.0) continue;

      final eased = Curves.easeIn.transform(local);
      // Rơi: drift ra + trọng lực kéo xuống mạnh dần
      final drift = Offset(math.cos(s.driftAngle), math.sin(s.driftAngle)) * 60 * eased;
      final gravity = Offset(0, 260 * eased * eased);
      final translate = drift + gravity;
      final rotate = s.rotDir * s.spin * eased;
      final scale = 1.0 - eased * 0.25;
      final alpha = (1.0 - eased).clamp(0.0, 1.0);

      _drawShard(canvas, s, size, translate, rotate, scale, alpha,
          crackGlow: (1.0 - local / 0.25).clamp(0.0, 1.0));
    }
  }

  double _crackGlow(double delay) {
    // Đường nứt lóe sáng ngay khi sóng vỡ chạm tới mảnh
    final wave = (progress / 0.45).clamp(0.0, 1.0);
    final d = (wave - delay).abs();
    return (1.0 - d * 6).clamp(0.0, 1.0);
  }

  void _drawShard(Canvas canvas, _Shard s, Size size, Offset translate, double rotate, double scale, double alpha,
      {double crackGlow = 0}) {
    if (alpha <= 0.01) return;

    canvas.save();
    canvas.translate(s.centroid.dx + translate.dx, s.centroid.dy + translate.dy);
    canvas.rotate(rotate);
    canvas.scale(scale);
    canvas.translate(-s.centroid.dx, -s.centroid.dy);

    final path = Path()..moveTo(s.pts[0].dx, s.pts[0].dy);
    path.lineTo(s.pts[1].dx, s.pts[1].dy);
    path.lineTo(s.pts[2].dx, s.pts[2].dy);
    path.close();

    // Màu kính theo vị trí + gradient chéo tạo mặt phản quang
    final tint = ((s.centroid.dx / size.width) + (s.centroid.dy / size.height)) / 2;
    final base = Color.lerp(colors[0], colors[2], tint.clamp(0.0, 1.0))!;

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(base, Colors.white, 0.22)!.withValues(alpha: alpha * 0.92),
          base.withValues(alpha: alpha * 0.82),
          Color.lerp(base, Colors.black, 0.25)!.withValues(alpha: alpha * 0.88),
        ],
      ).createShader(Rect.fromPoints(s.pts[0], s.pts[2]));
    canvas.drawPath(path, fill);

    // Cạnh vỡ sáng
    final edge = Paint()
      ..color = Colors.white.withValues(alpha: alpha * (0.15 + crackGlow * 0.75))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 + crackGlow * 1.5;
    canvas.drawPath(path, edge);

    // Vệt phản quang glow khi mới nứt
    if (crackGlow > 0.05) {
      final glow = Paint()
        ..color = Colors.white.withValues(alpha: crackGlow * 0.4 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, glow..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(GlassShatterPainter old) => old.progress != progress || old.impact != impact;
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ShatterGlassTransitionDemo extends StatefulWidget {
  const ShatterGlassTransitionDemo({super.key});

  @override
  State<ShatterGlassTransitionDemo> createState() => _ShatterGlassTransitionDemoState();
}

class _ShatterGlassTransitionDemoState extends State<ShatterGlassTransitionDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  bool _isAnimating = false;
  Offset _impact = const Offset(200, 300);

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _isAnimating = false);
        }
      });
  }

  @override
  void dispose() {
    _demoController.dispose();
    super.dispose();
  }

  void _play(TapDownDetails d) {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
      _impact = d.localPosition;
    });
    // Reset cache để mảnh sinh theo điểm va mới
    GlassShatterPainter._cache = null;
    _demoController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Shatter Glass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTapDown: _play,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                clipBehavior: Clip.antiAlias,
                child: AnimatedBuilder(
                  animation: _demoController,
                  builder: (context, _) {
                    final p = _demoController.value;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildTargetPage(),
                        if (p < 0.01) _buildSourceLabel(),
                        if (p > 0.001 && p < 0.999)
                          CustomPaint(
                            painter: GlassShatterPainter(
                              progress: p,
                              impact: _impact,
                              colors: _kGlassGradient,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.touch_app_rounded, color: Color(0xFF818CF8), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Chạm vào khung để đập vỡ kính tại điểm chạm',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(builder: (ctx) {
                  return GestureDetector(
                    onTapDown: (d) {
                      GlassShatterPainter._cache = null;
                      Navigator.push(
                        ctx,
                        ShatterGlassPageRoute(page: const _GlassDetailPage(), impact: d.globalPosition),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF818CF8).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Mở trang mới (Shatter Route)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLabel() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, size: 64, color: Colors.white),
          SizedBox(height: 16),
          Text('SHATTER GLASS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
          SizedBox(height: 8),
          Text('Chạm để đập vỡ', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTargetPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)]),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 64, color: Color(0xFF38BDF8)),
            SizedBox(height: 16),
            Text('MÀN HÌNH KẾ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

class _GlassDetailPage extends StatelessWidget {
  const _GlassDetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('GLASS DETAIL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF818CF8).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.broken_image_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('Shatter Glass', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Màn hình nứt vỡ như kính thành\ncác mảnh rơi xoay theo trọng lực',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF818CF8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
