import 'dart:math' as math;
import 'package:flutter/material.dart';

// =========================================================================
// 1. CIRCULAR REVEAL COMPONENTS (VÒNG TRÒN CƠ BẢN)
// =========================================================================

/// Widget hiển thị màn đè, khi kích hoạt sẽ đục lỗ tròn để lộ màn chính bên dưới.
class CircularRevealOverlay extends StatefulWidget {
  final Widget child;
  final Widget overlay;
  final bool showOverlay;
  final Offset? tapPosition;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onRevealComplete;

  const CircularRevealOverlay({
    super.key,
    required this.child,
    required this.overlay,
    required this.showOverlay,
    this.tapPosition,
    this.duration = const Duration(milliseconds: 850),
    this.curve = Curves.easeInOutCubic,
    this.onRevealComplete,
  });

  @override
  State<CircularRevealOverlay> createState() => _CircularRevealOverlayState();
}

class _CircularRevealOverlayState extends State<CircularRevealOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOverlayRendered = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isOverlayRendered = false;
        });
        if (widget.onRevealComplete != null) {
          widget.onRevealComplete!();
        }
      }
    });

    if (!widget.showOverlay) {
      _controller.value = 1.0;
      _isOverlayRendered = false;
    }
  }

  @override
  void didUpdateWidget(covariant CircularRevealOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showOverlay != oldWidget.showOverlay) {
      if (widget.showOverlay) {
        setState(() {
          _isOverlayRendered = true;
        });
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOverlayRendered)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipPath(
                clipper: CircularHoleClipper(
                  revealPercent: CurvedAnimation(
                    parent: _controller,
                    curve: widget.curve,
                  ).value,
                  center: widget.tapPosition,
                ),
                child: widget.overlay,
              );
            },
          ),
      ],
    );
  }
}

/// PageRouteBuilder chuyển trang bằng vòng tròn lan tỏa.
class CircularRevealPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset? center;
  final Duration duration;

  CircularRevealPageRoute({
    required this.page,
    this.center,
    this.duration = const Duration(milliseconds: 750),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ClipPath(
              clipper: CircularRevealClipper(
                revealPercent: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ).value,
                center: center,
              ),
              child: child,
            );
          },
        );
}

/// Clipper đục lỗ tròn trên màn đè.
class CircularHoleClipper extends CustomClipper<Path> {
  final double revealPercent;
  final Offset? center;

  CircularHoleClipper({
    required this.revealPercent,
    this.center,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final centerOffset = center ?? Offset(size.width / 2, size.height / 2);
    final double maxRadius = _calculateMaxRadius(size, centerOffset);
    final double radius = maxRadius * revealPercent;

    final holePath = Path()
      ..addOval(Rect.fromCircle(center: centerOffset, radius: radius));

    return Path.combine(PathOperation.difference, path, holePath);
  }

  double _calculateMaxRadius(Size size, Offset center) {
    final double w = size.width;
    final double h = size.height;

    final d1 = math.sqrt(center.dx * center.dx + center.dy * center.dy);
    final d2 = math.sqrt((w - center.dx) * (w - center.dx) + center.dy * center.dy);
    final d3 = math.sqrt(center.dx * center.dx + (h - center.dy) * (h - center.dy));
    final d4 = math.sqrt((w - center.dx) * (w - center.dx) + (h - center.dy) * (h - center.dy));

    return [d1, d2, d3, d4].reduce(math.max);
  }

  @override
  bool shouldReclip(covariant CircularHoleClipper oldClipper) {
    return oldClipper.revealPercent != revealPercent || oldClipper.center != center;
  }
}

/// Clipper giữ lại màn hình bên trong vòng tròn.
class CircularRevealClipper extends CustomClipper<Path> {
  final double revealPercent;
  final Offset? center;

  CircularRevealClipper({
    required this.revealPercent,
    this.center,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerOffset = center ?? Offset(size.width / 2, size.height / 2);
    final double maxRadius = _calculateMaxRadius(size, centerOffset);
    final double radius = maxRadius * revealPercent;

    path.addOval(Rect.fromCircle(center: centerOffset, radius: radius));
    return path;
  }

  double _calculateMaxRadius(Size size, Offset center) {
    final double w = size.width;
    final double h = size.height;

    final d1 = math.sqrt(center.dx * center.dx + center.dy * center.dy);
    final d2 = math.sqrt((w - center.dx) * (w - center.dx) + center.dy * center.dy);
    final d3 = math.sqrt(center.dx * center.dx + (h - center.dy) * (h - center.dy));
    final d4 = math.sqrt((w - center.dx) * (w - center.dx) + (h - center.dy) * (h - center.dy));

    return [d1, d2, d3, d4].reduce(math.max);
  }

  @override
  bool shouldReclip(covariant CircularRevealClipper oldClipper) {
    return oldClipper.revealPercent != revealPercent || oldClipper.center != center;
  }
}

// =========================================================================
// 2. FLUID MORPHING COMPONENTS (HIỆU ỨNG RƠI NẨY SPLASH CHẤT LỎNG - FLUID MORPH)
// =========================================================================

/// Widget hiển thị màn đè, khi kích hoạt sẽ tạo hiệu ứng giọt nước rơi từ điểm chạm xuống đất,
/// vỡ ra bắn tóe và nở bung lên mở dần màn hình dưới.
class LiquidMorphOverlay extends StatefulWidget {
  final Widget child;
  final Widget overlay;
  final bool showOverlay;
  final Offset? tapPosition;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onRevealComplete;

  const LiquidMorphOverlay({
    super.key,
    required this.child,
    required this.overlay,
    required this.showOverlay,
    this.tapPosition,
    this.duration = const Duration(milliseconds: 1600), // Thời gian dài hơn một chút để thấy rõ 3 pha
    this.curve = Curves.linear, // Chạy tuyến tính vì các pha đã có ease nội bộ
    this.onRevealComplete,
  });

  @override
  State<LiquidMorphOverlay> createState() => _LiquidMorphOverlayState();
}

class _LiquidMorphOverlayState extends State<LiquidMorphOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOverlayRendered = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isOverlayRendered = false;
        });
        if (widget.onRevealComplete != null) {
          widget.onRevealComplete!();
        }
      }
    });

    if (!widget.showOverlay) {
      _controller.value = 1.0;
      _isOverlayRendered = false;
    }
  }

  @override
  void didUpdateWidget(covariant LiquidMorphOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showOverlay != oldWidget.showOverlay) {
      if (widget.showOverlay) {
        setState(() {
          _isOverlayRendered = true;
        });
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOverlayRendered)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipPath(
                clipper: LiquidHoleClipper(
                  progress: _controller.value,
                  center: widget.tapPosition ?? Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
                ),
                child: widget.overlay,
              );
            },
          ),
      ],
    );
  }
}

/// PageRouteBuilder chuyển trang bằng hiệu ứng Fluid Morphing rơi nẩy vỡ ra.
class LiquidMorphPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset? center;
  final Duration duration;

  LiquidMorphPageRoute({
    required this.page,
    this.center,
    this.duration = const Duration(milliseconds: 1400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ClipPath(
              clipper: LiquidMorphClipper(
                progress: animation.value,
                center: center ?? Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
              ),
              child: child,
            );
          },
        );
}

/// Clipper mô phỏng giọt nước rơi, va chạm và nẩy vỡ (Splash/Fluid Morphing Animation):
/// - PHA 1 (0.0 -> 0.35): Giọt nước hình giọt lệ (teardrop) rơi tự do tăng tốc từ điểm click xuống sát đáy màn hình.
/// - PHA 2 (0.35 -> 0.55): Giọt nước va chạm mặt đất, bẹt ra thành vũng nước và bắn ra 8 hạt nước li ti hình parabol (splash particles).
/// - PHA 3 (0.55 -> 1.0): Vũng nước từ đáy màn hình nở bung mạnh mẽ với viền sóng nước xoáy tròn dâng lên chiếm trọn màn hình.
class LiquidMorphClipper extends CustomClipper<Path> {
  final double progress;
  final Offset center;

  LiquidMorphClipper({
    required this.progress,
    required this.center,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;

    // Tọa độ điểm click xuất phát
    final double startX = center.dx;
    final double startY = center.dy;

    // Điểm tiếp đất (đáy màn hình cách mép dưới 60px)
    final double groundX = startX;
    final double groundY = h - 60;

    // Các cột mốc phân kỳ pha
    const double phase1End = 0.35; // Kết thúc rơi
    const double phase2End = 0.55; // Kết thúc bắn tóe

    if (progress <= 0.0) {
      path.addOval(Rect.fromCircle(center: center, radius: 0));
      return path;
    }
    if (progress >= 1.0) {
      path.addRect(Rect.fromLTWH(0, 0, w, h));
      return path;
    }

    if (progress < phase1End) {
      // ---------------------------------------------------------------------
      // PHA 1: Giọt nước rơi tự do (Falling teardrop)
      // ---------------------------------------------------------------------
      final double t = progress / phase1End; // Chuẩn hóa từ 0.0 -> 1.0
      
      // Sử dụng hàm mũ mô phỏng gia tốc rơi tự do nhanh dần đều
      final double easedT = math.pow(t, 1.8).toDouble();
      final double currentY = startY + (groundY - startY) * easedT;

      // Kích thước bầu giọt nước
      const double radius = 18.0;

      // Vẽ hình giọt nước hướng đuôi nhọn lên trên (theo quán tính rơi xuống)
      final Offset bulbCenter = Offset(groundX, currentY);
      path.moveTo(bulbCenter.dx, bulbCenter.dy - radius * 2.2); // đuôi nhọn
      
      // Sườn trái
      path.cubicTo(
        bulbCenter.dx - radius * 1.3, bulbCenter.dy - radius * 1.0,
        bulbCenter.dx - radius * 1.3, bulbCenter.dy + radius * 0.8,
        bulbCenter.dx, bulbCenter.dy + radius, // Đáy tròn
      );
      // Sườn phải
      path.cubicTo(
        bulbCenter.dx + radius * 1.3, bulbCenter.dy + radius * 0.8,
        bulbCenter.dx + radius * 1.3, bulbCenter.dy - radius * 1.0,
        bulbCenter.dx, bulbCenter.dy - radius * 2.2, // về đuôi nhọn
      );
      path.close();
    } 
    else if (progress < phase2End) {
      // ---------------------------------------------------------------------
      // PHA 2: Chạm đất, bẹt ra & Bắn tóe nước (Splash Impact)
      // ---------------------------------------------------------------------
      final double t = (progress - phase1End) / (phase2End - phase1End); // Chuẩn hóa từ 0.0 -> 1.0

      // 1. Vẽ vũng nước bẹt ra trên mặt đất
      final double puddleWidth = 18.0 + 80.0 * t;
      final double puddleHeight = 18.0 * (1.0 - t * 0.82); // Dẹt mỏng lại còn ~3px
      path.addOval(Rect.fromCenter(
        center: Offset(groundX, groundY),
        width: puddleWidth * 2,
        height: puddleHeight * 2,
      ));

      // 2. Vẽ 8 giọt nước bắn tung tóe theo cung Parabol
      // Các góc bắn hướng lên trên và chếch ra 2 bên sườn
      final List<double> angles = [
        -0.80 * math.pi, -0.65 * math.pi, -0.50 * math.pi, -0.35 * math.pi, // Bắn bên trái
        -0.30 * math.pi, -0.15 * math.pi, -1.85 * math.pi, -1.70 * math.pi, // Bắn bên phải
      ];
      final List<double> speeds = [
        1.2, 1.5, 0.9, 1.6,
        1.4, 1.1, 1.7, 0.8,
      ];

      for (int i = 0; i < angles.length; i++) {
        final double angle = angles[i];
        final double speed = speeds[i];

        // Quỹ đạo Parabol: di chuyển xiên kết hợp với trọng lực kéo xuống (t^2)
        final double px = groundX + math.cos(angle) * speed * t * 150.0;
        final double py = groundY + math.sin(angle) * speed * t * 110.0 + 90.0 * t * t;

        // Bán kính hạt nước nhỏ dần rồi biến mất
        final double pRadius = math.max(0.0, 5.0 * (1.0 - t));
        if (pRadius > 0.5) {
          final pPath = Path()..addOval(Rect.fromCircle(center: Offset(px, py), radius: pRadius));
          path.addPath(pPath, Offset.zero);
        }
      }
    } 
    else {
      // ---------------------------------------------------------------------
      // PHA 3: Vũng nước dẹt mở rộng dần (giữ nguyên tỷ lệ dẹt ban đầu)
      // ---------------------------------------------------------------------
      final double t = (progress - phase2End) / (1.0 - phase2End); // Chuẩn hóa từ 0.0 -> 1.0

      // Kích thước vũng nước ở cuối Pha 2 (rộng 196, cao 6.48)
      final double wStart = 98.0 * 2;
      final double hStart = 18.0 * 0.18 * 2;

      // Kích thước cuối để phủ hết màn hình (giữ nguyên tỉ lệ dẹt)
      final double hEnd = groundY * 2.5; // Đảm bảo phủ hết chiều cao từ đáy lên đỉnh
      final double wEnd = hEnd * (wStart / hStart); // Khoảng rộng khổng lồ theo tỷ lệ dẹt ~30 lần h

      // Kích thước hiện tại theo tiến trình tuyến tính
      final double wCurrent = wStart + (wEnd - wStart) * t;
      final double hCurrent = hStart + (hEnd - hStart) * t;

      path.addOval(Rect.fromCenter(
        center: Offset(groundX, groundY),
        width: wCurrent,
        height: hCurrent,
      ));
    }

    return path;
  }

  @override
  bool shouldReclip(covariant LiquidMorphClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.center != center;
  }
}

/// Clipper đục một lỗ trống dạng Fluid Morph rơi vỡ để lộ màn hình dưới.
class LiquidHoleClipper extends CustomClipper<Path> {
  final double progress;
  final Offset center;

  LiquidHoleClipper({
    required this.progress,
    required this.center,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holeClipper = LiquidMorphClipper(progress: progress, center: center);
    final holePath = holeClipper.getClip(size);

    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(covariant LiquidHoleClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.center != center;
  }
}
