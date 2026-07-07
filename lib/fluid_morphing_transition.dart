import 'dart:math' as math;
import 'package:flutter/material.dart';

// =========================================================================
// FLUID MORPHING COMPONENTS (HIỆU ỨNG RƠI NẨY SPLASH CHẤT LỎNG - FLUID MORPH)
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
    this.duration = const Duration(milliseconds: 1000), // Thời gian dài hơn một chút để thấy rõ 3 pha
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
            final double val = animation.value;
            // Ở pha 1 và pha 2 (giọt nước đang rơi và vỡ bắn tóe), ta chỉ vẽ khối màu đồng màu 
            // với background trang mới để tránh việc nội dung chữ/nút của trang mới bị nhấp nháy lộ ra trong giọt nước.
            if (val < 0.55) {
              return ClipPath(
                clipper: LiquidMorphClipper(
                  progress: val,
                  center: center ?? Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
                ),
                child: Container(
                  color: const Color(0xFF0F172A), // Màu nền của DetailScreen
                ),
              );
            } else {
              // Pha 3: vũng nước loang rộng mở ra để lộ nội dung trang mới một cách mượt mà
              return ClipPath(
                clipper: LiquidMorphClipper(
                  progress: val,
                  center: center ?? Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
                ),
                child: child,
              );
            }
          },
        );
}

/// Clipper mô phỏng giọt nước rơi, va chạm và nẩy vỡ (Splash/Fluid Morphing Animation):
/// - PHA 1 (0.0 -> 0.35): Giọt nước hình giọt lệ (teardrop) rơi tự do tăng tốc từ điểm click xuống sát đáy màn hình.
/// - PHA 2 (0.35 -> 0.55): Giọt nước va chạm mặt đất, bẹt ra thành vũng nước và bắn ra 8 hạt nước li ti hình parabol (splash particles).
/// - PHA 3 (0.55 -> 1.0): Vũng nước từ đáy màn hình nở bung mạnh mẽ (giữ nguyên tỷ lệ dẹt 3.5:1) dâng lên chiếm trọn màn hình.
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

    if (progress <= 0.005) {
      return path; // Trả về path rỗng hoàn toàn để tránh vẽ hình elip/tròn bán kính 0px (Degenerate Path)
    }
    // Phủ hoàn toàn màn hình sớm hơn (từ 0.95) để tránh giật nháy hình ở frame cuối cùng khi tắt ClipPath
    if (progress >= 0.95) {
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

      // Giọt nước phình to dần từ 0 lên 18.0 ở đầu pha rơi (0% -> 20%) để tránh nhấp nháy đột ngột lúc mới click
      final double scaleProgress = (t / 0.20).clamp(0.0, 1.0);
      final double radius = 18.0 * scaleProgress;

      // Co rút đuôi nhọn lùi lại thành hình tròn hoàn hảo ở cuối pha rơi (80% -> 100% của pha 1)
      // Giúp chuyển tiếp trơn tru không giật hình khi chuyển sang Pha 2 (hình tròn bắt đầu bẹt đất)
      final double tailProgress = ((t - 0.80) / 0.20).clamp(0.0, 1.0);
      final double tailFactor = 2.2 - 1.2 * tailProgress; // Co từ 2.2 về 1.0
      final double sideFactor = 1.3 - 0.3 * tailProgress; // Thu gọn sườn ngang từ 1.3 về 1.0
      final double bottomFactor = 0.8 + 0.2 * tailProgress; // Tròn đáy từ 0.8 về 1.0

      // Vẽ hình giọt nước động co giãn
      final Offset bulbCenter = Offset(groundX, currentY);
      path.moveTo(bulbCenter.dx, bulbCenter.dy - radius * tailFactor); // Đuôi nhọn co giãn
      
      // Sườn trái
      path.cubicTo(
        bulbCenter.dx - radius * sideFactor, bulbCenter.dy - radius * (tailFactor * 0.45),
        bulbCenter.dx - radius * sideFactor, bulbCenter.dy + radius * bottomFactor,
        bulbCenter.dx, bulbCenter.dy + radius * bottomFactor,
      );
      // Sườn phải
      path.cubicTo(
        bulbCenter.dx + radius * sideFactor, bulbCenter.dy + radius * bottomFactor,
        bulbCenter.dx + radius * sideFactor, bulbCenter.dy - radius * (tailFactor * 0.45),
        bulbCenter.dx, bulbCenter.dy - radius * tailFactor,
      );
      path.close();
    } 
    else if (progress < phase2End) {
      // ---------------------------------------------------------------------
      // PHA 2: Chạm đất, bẹt ra & Bắn tóe nước (Splash Impact)
      // ---------------------------------------------------------------------
      final double t = (progress - phase1End) / (phase2End - phase1End); // Chuẩn hóa từ 0.0 -> 1.0

      // 1. Vẽ vũng nước bẹt ra trên mặt đất (giảm từ tròn xuống tỉ lệ dẹt 3.5:1)
      final double puddleWidth = 18.0 + 80.0 * t;
      final double puddleHeight = 18.0 + (28.0 - 18.0) * t; // Cuối pha 2: bán kính ngang 98, bán kính đứng 28
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
      final double t = (progress - phase2End) / (1.0 - phase2End); // Chuẩn hóa từ 0.0 -> 1.0 (chạy tuyến tính mượt mà)

      // Kích thước vũng nước ở cuối Pha 2 (rộng 196, cao 56, tỉ lệ dẹt 3.5:1)
      final double wStart = 98.0 * 2;
      final double hStart = 28.0 * 2;

      // Tăng tỉ lệ hEnd từ 2.2 lên 3.5 để bầu elip phình to phủ hoàn toàn 4 góc màn hình sớm hơn (từ progress ~0.8)
      // Giúp triệt tiêu hiện tượng nhấp nháy góc màn hình ở frame cuối khi xóa Overlay khỏi Widget Tree.
      final double hEnd = groundY * 3.5; 
      final double wEnd = hEnd * 3.5; 

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

    // Tránh tính toán lỗ trống và Path.combine khi hoạt ảnh chưa bắt đầu hoặc quá nhỏ
    if (progress <= 0.01) {
      return path;
    }

    final holeClipper = LiquidMorphClipper(progress: progress, center: center);
    final holePath = holeClipper.getClip(size);

    try {
      return Path.combine(PathOperation.difference, path, holePath);
    } catch (e) {
      // Fallback an toàn nếu Path.combine vẫn ném lỗi trên một số thiết bị/Impeller
      return path;
    }
  }

  @override
  bool shouldReclip(covariant LiquidHoleClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.center != center;
  }
}
