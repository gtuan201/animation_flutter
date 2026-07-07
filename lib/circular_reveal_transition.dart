import 'dart:math' as math;
import 'package:flutter/material.dart';

// =========================================================================
// CIRCULAR REVEAL COMPONENTS (VÒNG TRÒN CƠ BẢN)
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
