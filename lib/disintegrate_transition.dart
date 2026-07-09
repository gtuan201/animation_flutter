import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DISINTEGRATE TRANSITION - Tan biến thành tro bụi (Ash Dissolve / Thanos Snap)
// Màn hình hiện tại vỡ thành hàng nghìn hạt bụi li ti, bị "gió" cuốn bay lên
// xoáy theo turbulence rồi mờ dần, quét từ một phía sang phía kia để lộ màn
// hình kế tiếp bên dưới. Có hạt lóe sáng như tàn lửa tạo cảm giác sống động.
// ─────────────────────────────────────────────────────────────────────────────

enum DisintegrateDirection { leftToRight, rightToLeft, bottomToTop, radial }

/// PageRoute với hiệu ứng Disintegrate
class DisintegratePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final DisintegrateDirection direction;
  final int density; // số cột hạt (càng cao càng mịn)

  DisintegratePageRoute({
    required this.page,
    this.direction = DisintegrateDirection.leftToRight,
    this.density = 34,
  }) : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 1400),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final size = MediaQuery.of(context).size;
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
                        painter: AshDissolvePainter(
                          progress: animation.value,
                          direction: direction,
                          density: density,
                          colors: const [Color(0xFFFB7185), Color(0xFFF59E0B), Color(0xFFEF4444)],
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

/// Painter vẽ trường hạt tro bụi tan biến
class AshDissolvePainter extends CustomPainter {
  final double progress;
  final DisintegrateDirection direction;
  final int density;
  final List<Color> colors;

  AshDissolvePainter({
    required this.progress,
    required this.direction,
    required this.density,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cols = density;
    final rows = (density * (size.height / size.width)).round().clamp(6, 90);
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final rng = math.Random(7);

    // Hướng gió cuốn hạt bay đi
    final windAngle = switch (direction) {
      DisintegrateDirection.leftToRight => -0.35 * math.pi, // lên & sang phải
      DisintegrateDirection.rightToLeft => -0.65 * math.pi, // lên & sang trái
      DisintegrateDirection.bottomToTop => -0.5 * math.pi, // thẳng lên
      DisintegrateDirection.radial => 0, // toả ra (tính riêng)
    };
    final wind = Offset(math.cos(windAngle), math.sin(windAngle));
    final center = size.center(Offset.zero);
    final maxDiag = math.sqrt(size.width * size.width + size.height * size.height);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final base = Offset((c + 0.5) * cellW, (r + 0.5) * cellH);

        // Ngưỡng bắt đầu tan theo hướng quét (sweep)
        final double sweep = switch (direction) {
          DisintegrateDirection.leftToRight => base.dx / size.width,
          DisintegrateDirection.rightToLeft => 1.0 - base.dx / size.width,
          DisintegrateDirection.bottomToTop => 1.0 - base.dy / size.height,
          DisintegrateDirection.radial => (base - center).distance / maxDiag,
        };

        final noise = rng.nextDouble() * 0.18;
        final start = (sweep * 0.62 + noise).clamp(0.0, 0.88);
        const window = 0.34; // độ dài mỗi hạt tan
        final local = ((progress - start) / window).clamp(0.0, 1.0);

        if (local <= 0.0) {
          // Chưa tan: vẽ khối đặc phủ kín (ẩn màn hình dưới)
          _drawSolid(canvas, base, cellW, cellH, base, size, center);
          continue;
        }
        if (local >= 1.0) continue;

        // Hạt nhỏ tách ra và bay
        final eased = Curves.easeIn.transform(local);

        // Hướng bay riêng của mỗi hạt (gió + toả + xoáy)
        Offset dir;
        if (direction == DisintegrateDirection.radial) {
          final d = base - center;
          dir = d.distance == 0 ? const Offset(0, -1) : d / d.distance;
        } else {
          dir = wind;
        }
        final swirl = rng.nextDouble() * math.pi * 2;
        final swirlAmp = 26 * eased;
        final travel = 120.0 * eased * (0.6 + rng.nextDouble() * 0.8);
        final pos = base +
            dir * travel +
            Offset(math.cos(swirl), math.sin(swirl)) * swirlAmp;

        final alpha = (1.0 - eased).clamp(0.0, 1.0);
        final pSize = (cellW * (0.55 + rng.nextDouble() * 0.5)) * (1.0 - eased * 0.7);
        if (pSize < 0.4 || alpha < 0.02) continue;

        // Màu theo vị trí + hạt tàn lửa lóe sáng ở đầu
        final tint = ((base.dx / size.width) + (base.dy / size.height)) / 2;
        final baseColor = Color.lerp(colors[0], colors[1], tint)!;
        final ember = local < 0.3 && rng.nextDouble() < 0.5;

        final paint = Paint()
          ..color = (ember ? Colors.white : baseColor).withValues(alpha: alpha)
          ..maskFilter = ember ? const MaskFilter.blur(BlurStyle.normal, 1.5) : null;

        canvas.drawCircle(pos, pSize / 2, paint);
      }
    }
  }

  // Vẽ ô đặc chưa tan (dùng gradient theo vị trí để giống "màn hình")
  void _drawSolid(Canvas canvas, Offset pos, double w, double h, Offset base, Size size, Offset center) {
    final tint = ((base.dx / size.width) + (base.dy / size.height)) / 2;
    final col = Color.lerp(colors[0], colors[2], tint)!;
    final rect = Rect.fromCenter(center: pos, width: w + 0.8, height: h + 0.8);
    canvas.drawRect(rect, Paint()..color = col);
  }

  @override
  bool shouldRepaint(AshDissolvePainter old) =>
      old.progress != progress || old.direction != direction || old.density != density;
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DisintegrateTransitionDemo extends StatefulWidget {
  const DisintegrateTransitionDemo({super.key});

  @override
  State<DisintegrateTransitionDemo> createState() => _DisintegrateTransitionDemoState();
}

class _DisintegrateTransitionDemoState extends State<DisintegrateTransitionDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  bool _isAnimating = false;
  DisintegrateDirection _direction = DisintegrateDirection.leftToRight;
  int _density = 30;

  final _dirLabels = const {
    DisintegrateDirection.leftToRight: 'Trái→Phải',
    DisintegrateDirection.rightToLeft: 'Phải→Trái',
    DisintegrateDirection.bottomToTop: 'Dưới→Trên',
    DisintegrateDirection.radial: 'Toả ra',
  };

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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

  void _playDemo() {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);
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
        title: const Text('Disintegrate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _playDemo,
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
                        if (p > 0.001 && p < 0.999)
                          CustomPaint(
                            painter: AshDissolvePainter(
                              progress: p,
                              direction: _direction,
                              density: _density,
                              colors: const [Color(0xFFFB7185), Color(0xFFF59E0B), Color(0xFFEF4444)],
                            ),
                          ),
                        // Nội dung "màn hình nguồn" chỉ hiện khi chưa tan nhiều
                        if (p < 0.02)
                          _buildSourceLabel(),
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
                // Hướng tan
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DisintegrateDirection.values.map((d) {
                    return _pill(_dirLabels[d]!, _direction == d, () => setState(() => _direction = d));
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.grain_rounded, color: Color(0xFFFB7185), size: 20),
                    const SizedBox(width: 12),
                    const Text('Mật độ hạt:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    ...([22, 30, 40, 50]).map((n) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _pill('$n', _density == n, () => setState(() => _density = n)),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(builder: (ctx) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      ctx,
                      DisintegratePageRoute(
                        page: const _DisintegrateDetailPage(),
                        direction: _direction,
                        density: _density,
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFF59E0B)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFB7185).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Mở trang mới (Disintegrate Route)',
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

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFB7185).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFFFB7185) : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? const Color(0xFFFB7185) : Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildSourceLabel() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grain_rounded, size: 64, color: Colors.white),
          SizedBox(height: 16),
          Text('DISINTEGRATE', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
          SizedBox(height: 8),
          Text('Chạm để tan biến thành tro bụi', style: TextStyle(color: Colors.white70, fontSize: 13)),
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

class _DisintegrateDetailPage extends StatelessWidget {
  const _DisintegrateDetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('DISINTEGRATE DETAIL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFF59E0B)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFFB7185).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.grain_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('Disintegrate', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Màn hình tan rã thành tro bụi\nbay cuốn theo gió rồi lộ trang mới',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB7185),
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
