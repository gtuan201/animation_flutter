import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTIVE SHADER — Fragment shader GLSL phản ứng chạm/di chuột + thời gian
// Dùng FragmentProgram (Flutter) load shaders/interactive.frag. Trường plasma
// fractal xoay theo thời gian, bị kéo về phía con trỏ và sáng lên nơi chạm.
// ─────────────────────────────────────────────────────────────────────────────

/// Widget vẽ shader tương tác. Tự load chương trình shader và cấp uniform.
class InteractiveShaderView extends StatefulWidget {
  const InteractiveShaderView({super.key});

  @override
  State<InteractiveShaderView> createState() => _InteractiveShaderViewState();
}

class _InteractiveShaderViewState extends State<InteractiveShaderView>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late final Ticker _ticker;
  double _time = 0;
  Offset _pointer = const Offset(0.5, 0.5); // normalized 0..1
  double _active = 0;
  Size _size = Size.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMicroseconds / 1e6;
        // Nhả tay thì active giảm dần
        _active *= 0.92;
      });
    })..start();
  }

  Future<void> _load() async {
    try {
      final prog = await ui.FragmentProgram.fromAsset('shaders/interactive.frag');
      if (mounted) setState(() => _program = prog);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _updatePointer(Offset local, Size size) {
    if (size.width == 0) return;
    _pointer = Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Không load được shader:\n$_error',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ),
      );
    }
    if (_program == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white24));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          onHover: (e) => _updatePointer(e.localPosition, _size),
          child: GestureDetector(
            onPanStart: (d) {
              _active = 1.0;
              _updatePointer(d.localPosition, _size);
            },
            onPanUpdate: (d) {
              _active = 1.0;
              _updatePointer(d.localPosition, _size);
            },
            onTapDown: (d) {
              _active = 1.0;
              _updatePointer(d.localPosition, _size);
            },
            child: CustomPaint(
              size: _size,
              painter: _ShaderPainter(
                program: _program!,
                time: _time,
                pointer: _pointer,
                active: _active,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final Offset pointer; // normalized 0..1
  final double active;

  _ShaderPainter({
    required this.program,
    required this.time,
    required this.pointer,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    // Thứ tự uniform PHẢI khớp với khai báo trong .frag:
    // uResolution(vec2)=0,1  uTime(float)=2  uPointer(vec2)=3,4  uActive(float)=5
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, pointer.dx * size.width);
    shader.setFloat(4, pointer.dy * size.height);
    shader.setFloat(5, active.clamp(0.0, 1.0));

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class InteractiveShaderDemo extends StatelessWidget {
  const InteractiveShaderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          const Positioned.fill(child: InteractiveShaderView()),
          // AppBar trong suốt đè lên
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Interactive Shader',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),
          // Hướng dẫn
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Chạm & kéo để tương tác với shader',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
