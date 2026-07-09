import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHUTTER TRANSITION - Rèm cửa 3D (Venetian Blinds)
// Màn hình chia thành các nan rèm, mỗi nan XOAY 3D quanh trục ngang với phối
// cảnh thật. Nan xoay từ cạnh-bên (mỏng, mở) → mặt-phẳng (dày, đóng), có
// dải sáng kim loại chạy theo góc xoay + chuyển động sóng lệch pha từ trên xuống.
// ─────────────────────────────────────────────────────────────────────────────

const List<Color> _kShutterGradient = [Color(0xFF22D3EE), Color(0xFF3B82F6)];

/// PageRoute với hiệu ứng Shutter 3D
class ShutterPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final int sliceCount;

  ShutterPageRoute({
    required this.page,
    this.sliceCount = 10,
  }) : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 1150),
          reverseTransitionDuration: const Duration(milliseconds: 850),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _ShutterTransition(
              animation: animation,
              sliceCount: sliceCount,
              child: child,
            );
          },
        );
}

class _ShutterTransition extends StatelessWidget {
  final Animation<double> animation;
  final int sliceCount;
  final Widget child;

  const _ShutterTransition({
    required this.animation,
    required this.sliceCount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final p = animation.value;
        if (p >= 0.999) return child;

        // Phase 1 (0 → 0.5): rèm đóng lại che trang cũ
        // Phase 2 (0.5 → 1): rèm mở ra để lộ trang mới
        final isOpening = p >= 0.5;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Trang mới nằm dưới, chỉ hiện khi bắt đầu mở
            if (isOpening) child,
            IgnorePointer(
              child: _ShutterBlinds(
                progress: isOpening ? (p - 0.5) * 2 : p * 2,
                sliceCount: sliceCount,
                isOpening: isOpening,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget vẽ các nan rèm 3D bằng Transform + phối cảnh
class _ShutterBlinds extends StatelessWidget {
  final double progress; // 0→1 trong mỗi phase
  final int sliceCount;
  final bool isOpening;

  const _ShutterBlinds({
    required this.progress,
    required this.sliceCount,
    required this.isOpening,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final sliceH = h / sliceCount;

        return Stack(
          children: List.generate(sliceCount, (i) {
            // Sóng lệch pha: nan trên đóng trước, nan dưới đóng sau
            final delay = (i / sliceCount) * 0.45;
            final raw = ((progress - delay) / (1.0 - 0.45)).clamp(0.0, 1.0);

            // closeAmount: 1 = đóng kín (mặt phẳng), 0 = mở (cạnh bên mỏng)
            final double closeAmount;
            if (isOpening) {
              closeAmount = 1.0 - Curves.easeInOutCubic.transform(raw);
            } else {
              closeAmount = Curves.easeInOutCubic.transform(raw);
            }

            // Góc xoay: 0 = đối diện (đóng), ±π/2 = edge-on (mở/vô hình)
            final angle = (1.0 - closeAmount) * (math.pi / 2);

            // Ánh sáng kim loại: nan nghiêng nhiều thì tối hơn ở một cạnh
            final shade = 0.35 + 0.65 * closeAmount;
            final highlight = math.sin(angle).abs(); // sáng nhất khi nghiêng

            return Positioned(
              top: i * sliceH,
              left: 0,
              right: 0,
              height: sliceH + 0.5, // +0.5 tránh khe hở giữa các nan
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015) // phối cảnh
                  ..rotateX(angle),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(const Color(0xFF0B1220), _kShutterGradient[0], shade * 0.9)!,
                        Color.lerp(const Color(0xFF0B1220), _kShutterGradient[1], shade)!,
                        Color.lerp(const Color(0xFF0B1220), _kShutterGradient[0], shade * 0.7)!,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Dải sáng kim loại chạy ngang giữa nan
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: FractionallySizedBox(
                            heightFactor: 0.35,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.35 * highlight),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bóng đổ ở mép trên nan (tạo chiều sâu 3D)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: sliceH * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.28 * (1 - highlight)),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ShutterTransitionDemo extends StatefulWidget {
  const ShutterTransitionDemo({super.key});

  @override
  State<ShutterTransitionDemo> createState() => _ShutterTransitionDemoState();
}

class _ShutterTransitionDemoState extends State<ShutterTransitionDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  int _sliceCount = 10;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
        title: const Text(
          'Shutter Transition',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
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
                    final isOpening = p >= 0.5;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildSourcePage(),
                        if (isOpening) _buildTargetPage(),
                        if (p > 0.001 && p < 0.999)
                          _ShutterBlinds(
                            progress: isOpening ? (p - 0.5) * 2 : p * 2,
                            sliceCount: _sliceCount,
                            isOpening: isOpening,
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
                    const Icon(Icons.view_week_rounded, color: Color(0xFF22D3EE), size: 20),
                    const SizedBox(width: 12),
                    const Text('Số nan:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    ...([8, 10, 14, 18]).map((count) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _pill('$count', _sliceCount == count,
                              () => setState(() => _sliceCount = count)),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(builder: (ctx) {
                  return _navButton(
                    label: 'Mở trang mới (Shutter Route)',
                    onTap: () => Navigator.push(
                      ctx,
                      ShutterPageRoute(page: const _ShutterDetailPage(), sliceCount: _sliceCount),
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

  Widget _navButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: _kShutterGradient),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: _kShutterGradient[0].withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcePage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _kShutterGradient),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.blinds_rounded, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text('SHUTTER', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
            SizedBox(height: 8),
            Text('Chạm để xem rèm 3D đóng mở', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetPage() {
    return Container(
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF10B981)),
            SizedBox(height: 16),
            Text('ĐÃ MỞ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
          ],
        ),
      ),
    );
  }
}

class _ShutterDetailPage extends StatelessWidget {
  const _ShutterDetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SHUTTER DETAIL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _kShutterGradient),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _kShutterGradient[0].withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.blinds_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('Shutter Transition', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Rèm cửa 3D xoay quanh trục\ncó ánh sáng kim loại phản chiếu',
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
