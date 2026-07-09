import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AIRDROP WAVE TRANSITION - Sóng cuộn phát sáng (AirDrop / NameDrop ripple)
// Các vòng sóng đồng tâm phát ra từ điểm chạm kiểu sonar, mép sóng uốn lượn
// (ripple) phát sáng xanh dương-cyan. Sóng cuộn lan tới đâu để lộ trang mới
// tới đó, kèm những vòng "echo pulse" liên tục toả ra như hiệu ứng dò tìm.
// ─────────────────────────────────────────────────────────────────────────────

const List<Color> _kAirdropColors = [Color(0xFF0EA5E9), Color(0xFF22D3EE), Color(0xFF6366F1)];

/// PageRoute với hiệu ứng AirDrop Wave
class AirdropWavePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset? origin;

  AirdropWavePageRoute({
    required this.page,
    this.origin,
  }) : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 1300),
          reverseTransitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final size = MediaQuery.of(context).size;
            final o = origin ?? Offset(size.width / 2, size.height - 80);
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final p = animation.value;
                if (p >= 0.999) return child;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Trang mới lộ ra trong vùng sóng đã cuộn qua
                    ClipPath(
                      clipper: _WaveRevealClipper(progress: p, origin: o, screen: size),
                      child: child,
                    ),
                    // Vòng sóng phát sáng vẽ đè lên
                    IgnorePointer(
                      child: CustomPaint(
                        size: size,
                        painter: AirdropWavePainter(progress: p, origin: o, colors: _kAirdropColors),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
}

double _maxRadius(Offset o, Size s) {
  final corners = [
    Offset.zero,
    Offset(s.width, 0),
    Offset(0, s.height),
    Offset(s.width, s.height),
  ];
  double m = 0;
  for (final c in corners) {
    m = math.max(m, (c - o).distance);
  }
  return m;
}

/// Clip path hình tròn có mép uốn lượn (ripple) đang nở ra
class _WaveRevealClipper extends CustomClipper<Path> {
  final double progress;
  final Offset origin;
  final Size screen;

  _WaveRevealClipper({required this.progress, required this.origin, required this.screen});

  @override
  Path getClip(Size size) {
    final maxR = _maxRadius(origin, screen) * 1.06;
    final baseR = Curves.easeInOutCubic.transform(progress) * maxR;
    if (baseR <= 0) return Path();

    // Biên độ gợn giảm dần khi sóng lớn/gần xong
    final amp = (1.0 - progress) * 20.0 * math.sin(progress * math.pi).clamp(0.2, 1.0);
    const waves = 7;

    final path = Path();
    const steps = 120;
    for (int i = 0; i <= steps; i++) {
      final a = (i / steps) * math.pi * 2;
      final r = baseR + amp * math.sin(a * waves + progress * math.pi * 4);
      final pt = origin + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveRevealClipper old) => old.progress != progress || old.origin != origin;
}

/// Painter vẽ các vòng sóng phát sáng + echo pulse
class AirdropWavePainter extends CustomPainter {
  final double progress;
  final Offset origin;
  final List<Color> colors;

  AirdropWavePainter({required this.progress, required this.origin, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final maxR = _maxRadius(origin, size) * 1.06;
    final baseR = Curves.easeInOutCubic.transform(progress) * maxR;
    final fade = math.sin(progress * math.pi).clamp(0.0, 1.0); // sáng nhất ở giữa

    // 1. Dải sáng glow ở mép sóng dẫn đầu (leading edge)
    if (baseR > 2) {
      final edgeGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[1].withValues(alpha: 0.0),
            colors[1].withValues(alpha: 0.55 * fade),
            Colors.white.withValues(alpha: 0.7 * fade),
            colors[0].withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.82, 0.93, 1.0],
        ).createShader(Rect.fromCircle(center: origin, radius: baseR))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(origin, baseR, edgeGlow);

      // Vạch sáng mảnh sắc nét ngay mép
      final crisp = Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawCircle(origin, baseR, crisp);
    }

    // 2. Các vòng echo pulse liên tục toả ra (kiểu sonar dò tìm)
    const pulseCount = 4;
    for (int i = 0; i < pulseCount; i++) {
      final phase = (progress * 2.0 + i / pulseCount) % 1.0;
      final r = phase * maxR * 0.9;
      final alpha = (1.0 - phase) * 0.35 * fade;
      if (alpha <= 0.01 || r <= 0) continue;
      final ring = Paint()
        ..color = colors[2].withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + (1 - phase) * 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(origin, r, ring);
    }

    // 3. Vài vòng trailing phía sau mép chính tạo chiều sâu sóng
    for (int i = 1; i <= 3; i++) {
      final r = baseR - i * 22.0;
      if (r <= 0) continue;
      final ring = Paint()
        ..color = colors[1].withValues(alpha: (0.28 / i) * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(origin, r, ring);
    }

    // 4. Quầng sáng mềm ở tâm phát sóng (chỉ mạnh lúc đầu)
    final coreGlow = (1.0 - progress * 1.6).clamp(0.0, 1.0);
    if (coreGlow > 0.02) {
      final core = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.6 * coreGlow),
            colors[1].withValues(alpha: 0.3 * coreGlow),
            colors[0].withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: origin, radius: 90));
      canvas.drawCircle(origin, 90, core);
    }
  }

  @override
  bool shouldRepaint(AirdropWavePainter old) => old.progress != progress || old.origin != origin;
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AirdropWaveTransitionDemo extends StatefulWidget {
  const AirdropWaveTransitionDemo({super.key});

  @override
  State<AirdropWaveTransitionDemo> createState() => _AirdropWaveTransitionDemoState();
}

class _AirdropWaveTransitionDemoState extends State<AirdropWaveTransitionDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  bool _isAnimating = false;
  Offset _origin = const Offset(200, 400);

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

  void _play(TapDownDetails d) {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
      _origin = d.localPosition;
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
        title: const Text('AirDrop Wave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final localSize = Size(constraints.maxWidth, constraints.maxHeight);
                    return AnimatedBuilder(
                      animation: _demoController,
                      builder: (context, _) {
                        final p = _demoController.value;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildSourcePage(),
                            if (p > 0.001)
                              ClipPath(
                                clipper: _WaveRevealClipper(progress: p, origin: _origin, screen: localSize),
                                child: _buildTargetPage(),
                              ),
                            if (p > 0.001 && p < 0.999)
                              CustomPaint(
                                painter: AirdropWavePainter(progress: p, origin: _origin, colors: _kAirdropColors),
                              ),
                          ],
                        );
                      },
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
                    Icon(Icons.wifi_tethering_rounded, color: Color(0xFF22D3EE), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Chạm vào khung để phát sóng từ điểm chạm',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(builder: (ctx) {
                  return GestureDetector(
                    onTapDown: (d) => Navigator.push(
                      ctx,
                      AirdropWavePageRoute(page: const _AirdropDetailPage(), origin: d.globalPosition),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Mở trang mới (AirDrop Route)',
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

  Widget _buildSourcePage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_tethering_rounded, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text('AIRDROP', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
            SizedBox(height: 8),
            Text('Chạm để phát sóng cuộn', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
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
            Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF22D3EE)),
            SizedBox(height: 16),
            Text('ĐÃ NHẬN', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
          ],
        ),
      ),
    );
  }
}

class _AirdropDetailPage extends StatelessWidget {
  const _AirdropDetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AIRDROP DETAIL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.wifi_tethering_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('AirDrop Wave', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Sóng cuộn phát sáng lan tỏa\nkiểu AirDrop / NameDrop của iPhone',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
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
