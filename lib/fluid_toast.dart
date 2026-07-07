import 'dart:math' as math;
import 'package:flutter/material.dart';

// =========================================================================
// FLUID TOAST MANAGER & SERVICE
// =========================================================================

/// Lớp điều phối hiển thị Toast hiệu ứng chất lỏng bắn tóe từ điểm click.
class FluidToastManager {
  static OverlayEntry? _currentEntry;

  /// Hiển thị một Toast bóng bong chất lỏng.
  /// - [context]: BuildContext để lấy Overlay.
  /// - [message]: Nội dung thông báo hiển thị trên Toast.
  /// - [tapPosition]: Vị trí chạm chuột/ngón tay để bắn giọt nước từ đó ra.
  /// - [isSuccess]: Trạng thái success (xanh lá) hoặc error (đỏ).
  static void show(
    BuildContext context, {
    required String message,
    required Offset tapPosition,
    bool isSuccess = true,
  }) {
    // Nếu có Toast đang hiển thị, xóa nó đi trước
    dismiss();

    final overlayState = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _FluidToastWidget(
        message: message,
        tapPosition: tapPosition,
        isSuccess: isSuccess,
        onDismiss: () => dismiss(),
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Tắt Toast hiện tại ngay lập tức.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

// =========================================================================
// WIDGET HIỂN THỊ TOAST HOẠT ẢNH CHẤT LỎNG
// =========================================================================

class _FluidToastWidget extends StatefulWidget {
  final String message;
  final Offset tapPosition;
  final bool isSuccess;
  final VoidCallback onDismiss;

  const _FluidToastWidget({
    required this.message,
    required this.tapPosition,
    required this.isSuccess,
    required this.onDismiss,
  });

  @override
  State<_FluidToastWidget> createState() => _FluidToastWidgetState();
}

class _FluidToastWidgetState extends State<_FluidToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Cấu hình mốc thời gian của các Pha để hoạt ảnh diễn ra nhanh hơn và dứt khoát hơn
  final double phase1End = 0.10; // Pha 1: Giọt nước rơi tự do (0.0 -> 0.10)
  final double phase2End = 0.18; // Pha 2: Chạm đất bắn tóe hạt nước (0.10 -> 0.18)
  final double phase3End = 0.90; // Pha 3: Nở xòe bong bóng Toast & hiển thị (0.18 -> 0.90)
  // Lớn hơn 0.90: Pha 5: Co nhỏ thu mình biến mất cực nhanh (0.90 -> 1.0)

  // Vị trí mục tiêu Toast xuất hiện (Phía dưới màn hình)
  late Offset targetPosition;

  // Các hạt nước bắn tóe lúc va chạm
  final List<_SplashParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600), // Rút ngắn tổng thời gian để chạy nhanh hơn hẳn
    );

    // Đăng ký dọn dẹp khi hoạt ảnh kết thúc
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });

    // Vị trí đích ban đầu (sẽ được cập nhật chính xác theo kích cỡ màn hình thực tế)
    targetPosition = Offset.zero;

    // Sinh các hạt bắn tóe ở Pha 2 (Splash bay ngược lên trên từ điểm va chạm ở đáy)
    final random = math.Random();
    for (int i = 0; i < 6; i++) {
      final double angle = -math.pi / 6 - (i * math.pi / 6); // Bắn góc hướng lên trên
      final double speed = 3.0 + random.nextDouble() * 4.0;
      _particles.add(_SplashParticle(
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
      ));
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // Chiều rộng Toast lớn hơn (trừ đi 32px để padding 2 bên chỉ còn 16px mỗi bên)
    final double targetX = screenSize.width / 2;
    // Toast dời sát xuống dưới hơn (cách đáy chỉ 75px - bottom 1 chút thôi)
    final double targetY = screenSize.height - 75.0;
    targetPosition = Offset(targetX, targetY);

    // Để rơi thẳng đứng hoàn hảo từ trên xuống dưới, điểm bắt đầu rơi (X) trùng khớp với điểm đích (X)
    final Offset startPosition = Offset(targetX, widget.tapPosition.dy);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Lắng nghe chạm để tắt nhanh Toast
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onDismiss,
              child: const SizedBox.expand(),
            ),
          ),
          
          // Vẽ hoạt ảnh giọt nước rơi xuống
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FluidToastPainter(
                      progress: _controller.value,
                      startPosition: startPosition,
                      targetPosition: targetPosition,
                      isSuccess: widget.isSuccess,
                      phase1End: phase1End,
                      phase2End: phase2End,
                      phase3End: phase3End,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),
          ),

          // Hiển thị nội dung chữ/icon của Toast ở đúng vị trí bong bóng nở (phải là con trực tiếp của Stack)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return _buildToastContent(_controller.value, screenSize);
            },
          ),
        ],
      ),
    );
  }

  /// Dựng nội dung chữ và icon ẩn hiện bên trong Toast
  Widget _buildToastContent(double t, Size screenSize) {
    // Chỉ hiển thị chữ/nội dung ở Pha 3 khi Toast đã bắt đầu nở to (t > 0.18) và biến mất trước Pha 5 (t < 0.90)
    if (t < phase2End || t >= phase3End) {
      return const SizedBox.shrink();
    }

    // Tính toán độ mờ nội dung (fade in và fade out)
    double opacity = 0.0;
    if (t >= phase2End && t < phase2End + 0.05) {
      opacity = (t - phase2End) / 0.05; // Fade in nhanh hơn (5% tiến trình)
    } else if (t >= phase2End + 0.05 && t < phase3End - 0.05) {
      opacity = 1.0;
    } else if (t >= phase3End - 0.05 && t < phase3End) {
      opacity = (phase3End - t) / 0.05; // Fade out nhanh
    }

    // Chiều rộng Toast kéo dài hơn, khớp với hình nền vẽ
    final double toastW = screenSize.width - 32.0;
    final double toastH = 64.0;

    return Positioned(
      left: targetPosition.dx - (toastW / 2),
      top: targetPosition.dy - (toastH / 2),
      width: toastW,
      height: toastH,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// CUSTOM PAINTER VẼ HOẠT ẢNH CHẤT LỎNG TOAST
// =========================================================================

class _FluidToastPainter extends CustomPainter {
  final double progress;
  final Offset startPosition;
  final Offset targetPosition;
  final bool isSuccess;
  final double phase1End;
  final double phase2End;
  final double phase3End;
  final List<_SplashParticle> particles;

  _FluidToastPainter({
    required this.progress,
    required this.startPosition,
    required this.targetPosition,
    required this.isSuccess,
    required this.phase1End,
    required this.phase2End,
    required this.phase3End,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    // PHA 1: Giọt nước rơi tự do (t: 0.0 -> phase1End)
    if (progress < phase1End) {
      final double tLocal = progress / phase1End;
      // Đường cong rơi nhanh dần đều
      final double easedT = Curves.easeInQuad.transform(tLocal);
      
      final Offset currentPos = Offset.lerp(startPosition, targetPosition, easedT)!;

      // Độ co giãn giọt nước theo vận tốc rơi
      final double sizeFactor = 16.0;
      final double stretch = 1.0 + tLocal * 1.5; // Kéo dài đuôi
      final double shrink = 1.0 / math.sqrt(stretch);

      final path = Path();
      // Vẽ giọt lệ đuôi nhọn
      path.moveTo(currentPos.dx, currentPos.dy - sizeFactor * stretch); // Đuôi nhọn hướng lên trên
      path.cubicTo(
        currentPos.dx - sizeFactor * shrink * 1.2,
        currentPos.dy + sizeFactor * stretch * 0.2,
        currentPos.dx - sizeFactor * shrink,
        currentPos.dy + sizeFactor * stretch * 1.0,
        currentPos.dx,
        currentPos.dy + sizeFactor * stretch * 1.1, // Đầu tròn hướng xuống
      );
      path.cubicTo(
        currentPos.dx + sizeFactor * shrink,
        currentPos.dy + sizeFactor * stretch * 1.0,
        currentPos.dx + sizeFactor * shrink * 1.2,
        currentPos.dy + sizeFactor * stretch * 0.2,
        currentPos.dx,
        currentPos.dy - sizeFactor * stretch,
      );
      canvas.drawPath(path, paint);
    }
    // PHA 2: Va chạm chạm đất và bắn tóe hạt nước (t: phase1End -> phase2End)
    else if (progress >= phase1End && progress < phase2End) {
      final double tLocal = (progress - phase1End) / (phase2End - phase1End);
      
      // Vẽ hạt nước dẹt xẹp lúc va chạm
      final double radiusX = 18.0 + tLocal * 22.0;
      final double radiusY = 18.0 - tLocal * 14.0;
      canvas.drawOval(
        Rect.fromCenter(center: targetPosition, width: radiusX * 2, height: radiusY * 2),
        paint,
      );

      // Vẽ các hạt nước bắn bắn tóe bay ra (Splash Particles)
      for (final particle in particles) {
        final double gravity = 0.35;
        final Offset displacement = Offset(
          particle.velocity.dx * tLocal * 15.0,
          (particle.velocity.dy * tLocal * 15.0) + (0.5 * gravity * tLocal * tLocal * 80.0),
        );
        final Offset particlePos = targetPosition + displacement;
        final double particleRadius = math.max(1.0, 5.0 * (1.0 - tLocal));
        canvas.drawCircle(particlePos, particleRadius, paint);
      }
    }
    // PHA 3: Nở bung thành hình bong bóng Toast (t: phase2End -> phase3End)
    else if (progress >= phase2End && progress < phase3End) {
      final double tLocal = (progress - phase2End) / (phase3End - phase2End);

      // Nhân tLocal với 5.5 để Toast bung nở nhanh giật (snap open) trong 18% thời gian đầu của Pha 3
      final double scaleT = Curves.easeOutBack.transform(math.min(1.0, tLocal * 5.5));

      final double startRadius = 20.0;
      final double toastW = size.width - 32.0; // Chiều dài toast dài rộng ra
      final double toastH = 64.0;

      // Nội suy kích thước nở rộng
      final double currentW = startRadius * 2 + (toastW - startRadius * 2) * scaleT;
      final double currentH = startRadius * 2 + (toastH - startRadius * 2) * scaleT;
      final double currentRadius = startRadius + (16.0 - startRadius) * scaleT;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: targetPosition, width: currentW, height: currentH),
          Radius.circular(currentRadius),
        ),
        paint,
      );
    }
    // PHA 5: Co nhỏ xẹp bóng và biến mất (t: phase3End -> 1.0)
    else {
      final double tLocal = (progress - phase3End) / (1.0 - phase3End);
      // Co nhỏ giật cực kỳ nhanh
      final double scale = Curves.easeInBack.transform(1.0 - tLocal);
      
      final double toastW = (size.width - 32.0) * scale;
      final double toastH = 64.0 * scale;
      final double currentRadius = 16.0 * scale;

      if (toastW > 1 && toastH > 1) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: targetPosition, width: toastW, height: toastH),
            Radius.circular(currentRadius),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FluidToastPainter oldPainter) {
    return oldPainter.progress != progress;
  }
}

// Model hạt nước bắn tóe
class _SplashParticle {
  final Offset velocity;
  _SplashParticle({required this.velocity});
}
