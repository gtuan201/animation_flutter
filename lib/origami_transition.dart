import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ORIGAMI FOLD TRANSITION - Gấp giấy 3D (Accordion Paper Fold)
// Trang cũ gấp lại thành các nếp accordion 3D thật với phối cảnh, mỗi nếp có
// đổ bóng ở khớp gấp + gradient ánh sáng theo góc nghiêng để tạo cảm giác
// tờ giấy thật đang được gấp gọn rồi bung mở ra trang mới.
// ─────────────────────────────────────────────────────────────────────────────

enum OrigamiFoldDirection { horizontal, vertical }

/// PageRoute với hiệu ứng Origami Fold 3D
class OrigamiPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final int foldCount;
  final OrigamiFoldDirection direction;

  OrigamiPageRoute({
    required this.page,
    this.foldCount = 4,
    this.direction = OrigamiFoldDirection.horizontal,
  }) : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 1050),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _OrigamiTransition(
              animation: animation,
              foldCount: foldCount,
              direction: direction,
              child: child,
            );
          },
        );
}

class _OrigamiTransition extends StatelessWidget {
  final Animation<double> animation;
  final int foldCount;
  final OrigamiFoldDirection direction;
  final Widget child;

  const _OrigamiTransition({
    required this.animation,
    required this.foldCount,
    required this.direction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final p = animation.value;
        if (p >= 0.999) return child;

        // Phase 1 (0→0.5): trang phủ màu gấp lại
        // Phase 2 (0.5→1): các nếp bung mở lộ trang mới
        final isOpening = p >= 0.5;
        // foldAmount: 1 = gấp kín, 0 = phẳng hoàn toàn
        final double foldAmount = isOpening
            ? 1.0 - Curves.easeInOutCubic.transform((p - 0.5) * 2)
            : Curves.easeInOutCubic.transform(p * 2);

        return Stack(
          fit: StackFit.expand,
          children: [
            if (isOpening) child,
            IgnorePointer(
              child: OrigamiPaper(
                foldAmount: foldAmount,
                foldCount: foldCount,
                direction: direction,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget vẽ tờ giấy gấp accordion 3D
class OrigamiPaper extends StatelessWidget {
  final double foldAmount; // 1 = gấp kín, 0 = phẳng
  final int foldCount;
  final OrigamiFoldDirection direction;

  const OrigamiPaper({
    super.key,
    required this.foldAmount,
    required this.foldCount,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final isH = direction == OrigamiFoldDirection.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final total = isH ? constraints.maxWidth : constraints.maxHeight;
        // Chiều dài mỗi nếp co lại khi gấp (accordion khép lại)
        final panelFull = total / foldCount;
        // Khi gấp kín, mỗi panel "co" theo cos(góc) → tổng bề rộng giảm
        final angle = foldAmount * (math.pi / 2) * 0.92; // tối đa ~83°
        final projected = panelFull * math.cos(angle);

        // Căn giữa khối accordion đã co lại
        final usedLength = projected * foldCount;
        final startOffset = (total - usedLength) / 2;

        final panels = <Widget>[];
        for (int i = 0; i < foldCount; i++) {
          final isRidge = i.isEven; // nếp lồi / lõm xen kẽ
          // Nếp lồi nghiêng về trước (sáng), nếp lõm nghiêng về sau (tối)
          final tilt = angle * (isRidge ? 1 : -1);

          // Ánh sáng: nếp hướng ra ánh sáng thì sáng, hướng đi thì tối
          final lightFactor = isRidge
              ? (1.0 - foldAmount * 0.15)
              : (1.0 - foldAmount * 0.65);

          final baseColor = _panelColor(i);
          final shaded = Color.lerp(Colors.black, baseColor, lightFactor.clamp(0.0, 1.0))!;

          final pos = startOffset + i * projected;

          panels.add(Positioned(
            left: isH ? pos : 0,
            top: isH ? 0 : pos,
            width: isH ? projected + 0.5 : constraints.maxWidth,
            height: isH ? constraints.maxHeight : projected + 0.5,
            child: Transform(
              alignment: isH
                  ? (isRidge ? Alignment.centerLeft : Alignment.centerRight)
                  : (isRidge ? Alignment.topCenter : Alignment.bottomCenter),
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(isH ? tilt : 0)
                ..rotateX(isH ? 0 : -tilt),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: isH ? Alignment.centerLeft : Alignment.topCenter,
                    end: isH ? Alignment.centerRight : Alignment.bottomCenter,
                    colors: isRidge
                        ? [shaded, Color.lerp(shaded, Colors.white, 0.12)!, shaded]
                        : [Color.lerp(shaded, Colors.black, 0.25)!, shaded],
                    stops: isRidge ? const [0.0, 0.5, 1.0] : const [0.0, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Bóng đổ ở khớp gấp (mép panel)
                    Positioned(
                      left: 0,
                      top: 0,
                      right: isH ? null : 0,
                      bottom: isH ? 0 : null,
                      width: isH ? projected * 0.28 : null,
                      height: isH ? null : projected * 0.28,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: isH ? Alignment.centerLeft : Alignment.topCenter,
                            end: isH ? Alignment.centerRight : Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4 * foldAmount),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Icon mờ chính giữa
                    Center(
                      child: Opacity(
                        opacity: (1 - foldAmount * 1.2).clamp(0.0, 1.0),
                        child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.white38, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ));
        }

        return Stack(children: panels);
      },
    );
  }

  Color _panelColor(int index) {
    const colors = [
      Color(0xFF818CF8),
      Color(0xFFA78BFA),
      Color(0xFFC084FC),
      Color(0xFF8B5CF6),
      Color(0xFF7C3AED),
      Color(0xFF6366F1),
    ];
    return colors[index % colors.length];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class OrigamiTransitionDemo extends StatefulWidget {
  const OrigamiTransitionDemo({super.key});

  @override
  State<OrigamiTransitionDemo> createState() => _OrigamiTransitionDemoState();
}

class _OrigamiTransitionDemoState extends State<OrigamiTransitionDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  bool _isAnimating = false;
  int _foldCount = 4;
  OrigamiFoldDirection _direction = OrigamiFoldDirection.horizontal;

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
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
        title: const Text('Origami Fold', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
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
                    final foldAmount = isOpening
                        ? 1.0 - Curves.easeInOutCubic.transform((p - 0.5) * 2)
                        : Curves.easeInOutCubic.transform(p * 2);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildSourcePage(),
                        if (isOpening) _buildTargetPage(),
                        if (p > 0.001 && p < 0.999)
                          OrigamiPaper(
                            foldAmount: foldAmount,
                            foldCount: _foldCount,
                            direction: _direction,
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
                    const Icon(Icons.swap_horiz_rounded, color: Color(0xFFA78BFA), size: 20),
                    const SizedBox(width: 12),
                    const Text('Hướng gập:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    _pill('Ngang', _direction == OrigamiFoldDirection.horizontal,
                        () => setState(() => _direction = OrigamiFoldDirection.horizontal)),
                    const SizedBox(width: 8),
                    _pill('Dọc', _direction == OrigamiFoldDirection.vertical,
                        () => setState(() => _direction = OrigamiFoldDirection.vertical)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.format_list_numbered_rounded, color: Color(0xFFA78BFA), size: 20),
                    const SizedBox(width: 12),
                    const Text('Số nếp:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    ...([3, 4, 6, 8]).map((count) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _pill('$count', _foldCount == count, () => setState(() => _foldCount = count)),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(builder: (ctx) {
                  return _navButton(
                    label: 'Mở trang mới (Origami Route)',
                    onTap: () => Navigator.push(
                      ctx,
                      OrigamiPageRoute(page: const _OrigamiDetailPage(), foldCount: _foldCount, direction: _direction),
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
          color: selected ? const Color(0xFFA78BFA).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFFA78BFA) : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? const Color(0xFFA78BFA) : Colors.white54,
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
          gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: const Color(0xFFA78BFA).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_mosaic_rounded, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text('ORIGAMI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
            SizedBox(height: 8),
            Text('Chạm để gấp giấy 3D', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
            Text('MỞ RA', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
          ],
        ),
      ),
    );
  }
}

class _OrigamiDetailPage extends StatelessWidget {
  const _OrigamiDetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ORIGAMI DETAIL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFA78BFA).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.auto_awesome_mosaic_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('Origami Fold', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Gấp giấy 3D accordion có đổ bóng\nnếp gấp và ánh sáng theo góc',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA78BFA),
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
