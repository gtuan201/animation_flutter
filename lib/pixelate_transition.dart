import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PIXELATE DISSOLVE TRANSITION - Phân rã Voxel (Shatter Dissolve)
// Màn hình vỡ thành lưới voxel, mỗi ô bay xoáy - drift ra ngoài - thu nhỏ dần
// theo sóng lan tỏa mượt từ điểm chạm. Trước khi tan, ô lóe sáng (edge glow)
// tạo hiệu ứng "cháy rìa" rất độc đáo.
// ─────────────────────────────────────────────────────────────────────────────

/// PageRoute với hiệu ứng Pixelate Dissolve
class PixelatePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset? center;
  final int gridSize;

  PixelatePageRoute({
    required this.page,
    this.center,
    this.gridSize = 14,
  }) : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 1250),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final size = MediaQuery.of(context).size;
            final c = center ?? size.center(Offset.zero);
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
                        painter: _VoxelDissolvePainter(
                          progress: animation.value,
                          center: c,
                          gridSize: gridSize,
                          fromColors: const [Color(0xFF34D399), Color(0xFF059669)],
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

/// Painter phân rã voxel dùng chung cho route + demo
class _VoxelDissolvePainter extends CustomPainter {
  final double progress;
  final Offset center;
  final int gridSize;
  final List<Color> fromColors;

  _VoxelDissolvePainter({
    required this.progress,
    required this.center,
    required this.gridSize,
    required this.fromColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cols = gridSize;
    final rows = (gridSize * (size.height / size.width)).round().clamp(4, 64);
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // Khoảng cách xa nhất từ tâm tới 4 góc (để chuẩn hóa)
    final corners = [
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    double maxDist = 0;
    for (final corner in corners) {
      maxDist = math.max(maxDist, (corner - center).distance);
    }

    final rng = math.Random(1234);

    for (int r = 0; r < rows; r++) {
      for (int col = 0; col < cols; col++) {
        final cellCenter = Offset((col + 0.5) * cellW, (r + 0.5) * cellH);
        final dist = (cellCenter - center).distance / maxDist; // 0..1

        // Sóng lan tỏa: ô gần tâm tan trước. Thêm noise nhẹ cho tự nhiên.
        final noise = rng.nextDouble() * 0.12;
        final start = (dist * 0.6 + noise).clamp(0.0, 0.85);
        const window = 0.4; // độ dài mỗi ô tan
        final local = ((progress - start) / window).clamp(0.0, 1.0);

        if (local <= 0.0) {
          // Chưa tan: vẽ ô đầy đủ
          _drawCell(canvas, cellCenter, cellW, cellH, dist, 1.0, 0.0, 0.0, glow: 0);
          continue;
        }
        if (local >= 1.0) continue; // đã tan hoàn toàn

        final eased = Curves.easeInCubic.transform(local);

        // Glow lóe sáng ở đầu quá trình tan (0 → 0.35)
        final glow = (1.0 - (local / 0.35)).clamp(0.0, 1.0);

        // Drift ra ngoài theo hướng từ tâm + chút ngẫu nhiên
        final dir = (cellCenter - center);
        final dirN = dir.distance == 0 ? const Offset(0, -1) : dir / dir.distance;
        final jitterAngle = rng.nextDouble() * math.pi * 2;
        final jitter = Offset(math.cos(jitterAngle), math.sin(jitterAngle)) * 18 * eased;
        final drift = dirN * (55 * eased) + jitter;

        final rot = eased * (rng.nextDouble() - 0.5) * 2.2;
        final alpha = (1.0 - eased).clamp(0.0, 1.0);

        _drawCell(
          canvas,
          cellCenter + drift,
          cellW,
          cellH,
          dist,
          alpha,
          eased,
          rot,
          glow: glow,
        );
      }
    }
  }

  void _drawCell(
    Canvas canvas,
    Offset pos,
    double cellW,
    double cellH,
    double dist,
    double alpha,
    double eased,
    double rot, {
    required double glow,
  }) {
    if (alpha <= 0.01) return;

    final scale = (1.0 - eased * 0.85).clamp(0.05, 1.0);
    final w = cellW * scale;
    final h = cellH * scale;

    // Màu gradient theo khoảng cách: xanh emerald → teal
    final t = dist.clamp(0.0, 1.0);
    final base = Color.lerp(fromColors[0], fromColors[1], t)!;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (rot != 0) canvas.rotate(rot);

    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cellW * 0.18));

    // Glow lóe sáng
    if (glow > 0.01) {
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: glow * 0.9)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + glow * 10);
      canvas.drawRRect(rrect, glowPaint);
    }

    // Thân ô với gradient dọc tạo khối
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(base, Colors.white, 0.25 + glow * 0.5)!.withValues(alpha: alpha),
          base.withValues(alpha: alpha),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, fill);

    // Highlight rìa trên-trái
    if (alpha > 0.3) {
      final edge = Paint()
        ..color = Colors.white.withValues(alpha: alpha * (0.18 + glow * 0.6))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawRRect(rrect, edge);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_VoxelDissolvePainter old) =>
      old.progress != progress || old.center != center || old.gridSize != gridSize;
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PixelateTransitionDemo extends StatefulWidget {
  const PixelateTransitionDemo({super.key});

  @override
  State<PixelateTransitionDemo> createState() => _PixelateTransitionDemoState();
}

class _PixelateTransitionDemoState extends State<PixelateTransitionDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  bool _isAnimating = false;
  Offset _tapPoint = const Offset(200, 300);
  int _gridSize = 14;

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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

  void _playDemo(TapDownDetails details) {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
      _tapPoint = details.localPosition;
    });
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
        title: const Text('Pixelate Dissolve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTapDown: _playDemo,
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
                            painter: _VoxelDissolvePainter(
                              progress: p,
                              center: _tapPoint,
                              gridSize: _gridSize,
                              fromColors: const [Color(0xFF34D399), Color(0xFF0EA5E9)],
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
                  children: [
                    const Icon(Icons.grid_on_rounded, color: Color(0xFF34D399), size: 20),
                    const SizedBox(width: 12),
                    const Text('Grid:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    ...([10, 14, 18, 24, 32]).map((count) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _pill('$count', _gridSize == count, () => setState(() => _gridSize = count)),
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Chạm vào khung để phân rã từ điểm chạm',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 12),
                Builder(builder: (ctx) {
                  return GestureDetector(
                    onTapDown: (details) {
                      Navigator.push(
                        ctx,
                        PixelatePageRoute(page: const _PixelateDetailPage(), center: details.globalPosition, gridSize: _gridSize),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF0EA5E9)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF34D399).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Mở trang mới (Pixelate Route)',
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF34D399).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF34D399) : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? const Color(0xFF34D399) : Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 11)),
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
            Icon(Icons.auto_awesome_rounded, size: 64, color: Color(0xFFF59E0B)),
            SizedBox(height: 16),
            Text('REVEALED', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
          ],
        ),
      ),
    );
  }
}

class _PixelateDetailPage extends StatelessWidget {
  const _PixelateDetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('PIXELATE DETAIL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF0EA5E9)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF34D399).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.grid_view_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('Pixelate Dissolve', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Voxel bay xoáy - lóe sáng - drift ra\nlan tỏa mượt từ điểm chạm',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34D399),
                foregroundColor: Colors.black87,
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
