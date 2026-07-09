import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GLITCH / DATAMOSH TRANSITION - Nhiễu số cyberpunk
// Màn hình hiện tại "nhiễu" theo phong cách datamosh: tách kênh RGB lệch nhau,
// các dải ngang dịch ngẫu nhiên (slice displacement), khối nhiễu số nhấp nháy,
// scanline chạy, rồi cắt phăng sang trang mới. Nhanh, giật, rất "digital".
// ─────────────────────────────────────────────────────────────────────────────

const List<Color> _kGlitchGradient = [Color(0xFF22D3EE), Color(0xFFE879F9)];

/// PageRoute với hiệu ứng Glitch
class GlitchPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final int bands;

  GlitchPageRoute({
    required this.page,
    this.bands = 26,
  }) : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 950),
          reverseTransitionDuration: const Duration(milliseconds: 600),
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
                        painter: GlitchPainter(
                          progress: animation.value,
                          bands: bands,
                          colors: _kGlitchGradient,
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

/// Painter nhiễu glitch. Tick theo tiến trình để tạo nhiễu thay đổi liên tục.
class GlitchPainter extends CustomPainter {
  final double progress;
  final int bands;
  final List<Color> colors;

  GlitchPainter({
    required this.progress,
    required this.bands,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    // Seed thay đổi theo frame để nhiễu "rung" liên tục
    final tick = (progress * 26).floor();
    final rng = math.Random(tick * 131 + 7);
    // Cường độ glitch: tăng nhanh rồi cắt (hình chuông lệch)
    final intensity = math.sin(progress * math.pi).clamp(0.0, 1.0);

    final bandH = size.height / bands;

    for (int i = 0; i < bands; i++) {
      final y = i * bandH;
      final bandCenterY = y + bandH / 2;

      // Ngưỡng reveal: dải "biến mất" dần để lộ trang mới, thứ tự ngẫu nhiên
      final bandSeed = math.Random(i * 977 + 3);
      final revealAt = 0.35 + bandSeed.nextDouble() * 0.6;
      if (progress >= revealAt) {
        // Đã lộ trang mới: thỉnh thoảng nháy 1 lằn nhiễu mỏng
        if (rng.nextDouble() < 0.06 * intensity) {
          final flick = Paint()..color = Colors.white.withValues(alpha: 0.15);
          canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), flick);
        }
        continue;
      }

      // Dịch ngang ngẫu nhiên (slice displacement)
      final shift = (rng.nextDouble() - 0.5) * 2 * (60 * intensity) * (rng.nextDouble() < 0.4 ? 1 : 0.2);

      final tint = bandCenterY / size.height;
      final base = Color.lerp(colors[0], colors[1], tint)!;

      final rect = Rect.fromLTWH(shift, y, size.width, bandH + 0.6);

      // RGB split: vẽ ghost cyan & magenta lệch nhau
      final split = 8 * intensity + rng.nextDouble() * 6 * intensity;
      final cyan = Paint()
        ..color = const Color(0xFF22D3EE).withValues(alpha: 0.55)
        ..blendMode = BlendMode.screen;
      final magenta = Paint()
        ..color = const Color(0xFFE879F9).withValues(alpha: 0.55)
        ..blendMode = BlendMode.screen;

      canvas.drawRect(rect.shift(Offset(-split, 0)), cyan);
      canvas.drawRect(rect.shift(Offset(split, 0)), magenta);

      // Thân dải màu chính
      canvas.drawRect(rect, Paint()..color = base.withValues(alpha: 0.92));

      // Khối nhiễu số (data blocks) rải trên dải
      final blockCount = (rng.nextDouble() * 4 * intensity).round();
      for (int b = 0; b < blockCount; b++) {
        final bx = rng.nextDouble() * size.width;
        final bw = 20 + rng.nextDouble() * 90;
        final noiseCol = rng.nextBool() ? Colors.white : Colors.black;
        canvas.drawRect(
          Rect.fromLTWH(bx, y + rng.nextDouble() * bandH * 0.5, bw, bandH * (0.3 + rng.nextDouble() * 0.5)),
          Paint()..color = noiseCol.withValues(alpha: 0.15 + rng.nextDouble() * 0.25),
        );
      }
    }

    // Scanline ngang chạy dọc màn hình
    final scanY = (progress * 2.2 % 1.0) * size.height;
    final scan = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.12 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 40, size.width, 80));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 40, size.width, 80), scan);
  }

  @override
  bool shouldRepaint(GlitchPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class GlitchTransitionDemo extends StatefulWidget {
  const GlitchTransitionDemo({super.key});

  @override
  State<GlitchTransitionDemo> createState() => _GlitchTransitionDemoState();
}

class _GlitchTransitionDemoState extends State<GlitchTransitionDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  bool _isAnimating = false;
  int _bands = 26;

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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

  void _play() {
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
        title: const Text('Glitch / Datamosh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _play,
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
                            painter: GlitchPainter(progress: p, bands: _bands, colors: _kGlitchGradient),
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
                    const Icon(Icons.blur_linear_rounded, color: Color(0xFF22D3EE), size: 20),
                    const SizedBox(width: 12),
                    const Text('Số dải:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    ...([18, 26, 36, 48]).map((n) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _pill('$n', _bands == n, () => setState(() => _bands = n)),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(builder: (ctx) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      ctx,
                      GlitchPageRoute(page: const _GlitchDetailPage(), bands: _bands),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: _kGlitchGradient),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF22D3EE).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Mở trang mới (Glitch Route)',
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
          color: selected ? const Color(0xFF22D3EE).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF22D3EE) : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? const Color(0xFF22D3EE) : Colors.white54,
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
          Icon(Icons.sensors_rounded, size: 64, color: Colors.white),
          SizedBox(height: 16),
          Text('GLITCH', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
          SizedBox(height: 8),
          Text('Chạm để nhiễu số', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTargetPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF111827)]),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF22D3EE)),
            SizedBox(height: 16),
            Text('SIGNAL OK', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
          ],
        ),
      ),
    );
  }
}

class _GlitchDetailPage extends StatelessWidget {
  const _GlitchDetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('GLITCH DETAIL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _kGlitchGradient),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF22D3EE).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.sensors_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('Glitch / Datamosh', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Nhiễu số tách kênh RGB, dịch dải\nngang rồi cắt sang trang mới',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22D3EE),
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
