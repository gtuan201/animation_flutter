import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME SWITCH — Day / Night Toggle
// Port chính xác từ CSS (Uiverse.io by Galahhad):
//   • Nền xanh dương (ngày) ↔ tím đêm với transition
//   • Mặt trời vàng ↔ mặt trăng xám trượt vào từ phải
//   • Circle container bouncy slide trái ↔ phải
//   • Mây trắng trượt lên khi ngày, tụt xuống khi đêm
//   • Ngôi sao SVG ẩn khi ngày, hiện giữa khi đêm
// ─────────────────────────────────────────────────────────────────────────────

// ── Màu sắc theo CSS gốc ──
const _kDayBg    = Color(0xFF3D7EAE);
const _kNightBg  = Color(0xFF1D1F2C);
const _kSunColor = Color(0xFFECCA2F);
const _kMoonColor = Color(0xFFC4C9D1);
const _kSpotColor = Color(0xFF959DB1);
const _kCloudFront = Color(0xFFF3FDFF);
const _kCloudBack  = Color(0xFFAACCDF);
const _kStarColor  = Colors.white;

// ── Bounce cubic-bezier: css "cubic-bezier(0, -0.02, 0.4, 1.25)" ──
class _BounceCurve extends Curve {
  const _BounceCurve();
  @override
  double transformInternal(double t) => _cb(t, 0.0, -0.02, 0.4, 1.25);
  static double _cb(double t, double x1, double y1, double x2, double y2) {
    double s = t;
    for (int i = 0; i < 10; i++) {
      final x = 3*(1-s)*(1-s)*s*x1 + 3*(1-s)*s*s*x2 + s*s*s - t;
      final dx = 3*(1-s)*(1-s)*x1 + 6*(1-s)*s*(x2-x1) + 3*s*s*(1-x2);
      if (dx.abs() < 1e-6) break;
      s -= x / dx;
    }
    return (3*(1-s)*(1-s)*s*y1 + 3*(1-s)*s*s*y2 + s*s*s).clamp(0.0, 1.3);
  }
}

// ── Circle bounce: css "cubic-bezier(0, -0.02, 0.35, 1.17)" ──
class _CircleCurve extends Curve {
  const _CircleCurve();
  @override
  double transformInternal(double t) => _BounceCurve._cb(t, 0.0, -0.02, 0.35, 1.17);
}

const _kBounce = _BounceCurve();
const _kCircle = _CircleCurve();

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class ThemeSwitch extends StatefulWidget {
  /// Kích thước cơ sở (= --toggle-size: 30px trong CSS)
  final double toggleSize;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ThemeSwitch({
    super.key,
    this.toggleSize = 10,
    this.value = false,
    this.onChanged,
  });

  @override
  State<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late bool _isNight;

  @override
  void initState() {
    super.initState();
    _isNight = widget.value;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: widget.value ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(ThemeSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _isNight = widget.value;
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isNight = !_isNight);
    _isNight ? _ctrl.forward() : _ctrl.reverse();
    widget.onChanged?.call(_isNight);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.toggleSize; // 1em
    // CSS vars scaled by s:
    final cw  = s * 5.625; // container-width
    final ch  = s * 2.5;   // container-height
    final ccd = s * 3.375; // circle-container-diameter
    final smd = s * 2.125; // sun-moon-diameter
    final off = (ccd - ch) / 2; // circle-container-offset (positive = overlap out)

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t    = _ctrl.value; // 0=day, 1=night
          final tBounce = _kBounce.transform(t.clamp(0.0, 1.0));
          final tCircle = _kCircle.transform(t.clamp(0.0, 1.0));

          // Nền container
          final bg = Color.lerp(_kDayBg, _kNightBg, tBounce.clamp(0.0, 1.0))!;

          // Circle container position: left: -off (ngày) → cw-ccd+off (đêm)
          final circleLeft = lerpDouble(-off, cw - ccd + off, tCircle.clamp(0.0, 1.0));

          // Mây: bottom -0.625em (ngày) → -4.062em (đêm)
          final cloudBottom = lerpDouble(-s * 0.625, -s * 4.062, tBounce.clamp(0.0, 1.0));

          // Ngôi sao: top -100% (ngày, ẩn) → 50% translated -50% (đêm, hiện)
          // Dùng opacity + translateY để đơn giản
          final starOpacity = tBounce.clamp(0.0, 1.0);
          final starOffsetY = lerpDouble(-ch, 0.0, tBounce.clamp(0.0, 1.0));

          // Mặt trăng trượt vào từ phải: translateX(100%) → translateX(0)
          final moonSlide = lerpDouble(smd, 0.0, tBounce.clamp(0.0, 1.0));

          return SizedBox(
            width: cw,
            height: ch,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Container nền ──
                Container(
                  width: cw,
                  height: ch,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(ch),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, -1), blurRadius: 1),
                      BoxShadow(color: Colors.white.withValues(alpha: 0.94), offset: const Offset(0, 1), blurRadius: 2),
                    ],
                  ),
                  // Inner shadow simulation
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ch),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 3, offset: const Offset(0, 1.5), spreadRadius: -1),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Mây (overflow bên dưới container)
                        Positioned(
                          left: s * 0.312,
                          bottom: cloudBottom,
                          child: _Clouds(size: s),
                        ),
                        // Ngôi sao
                        Positioned(
                          left: s * 0.312,
                          top: ch / 2 - s * 55 / 144 / 2 * (s * 2.75 / (s * 144 / 144)) + starOffsetY,
                          child: Opacity(
                            opacity: starOpacity,
                            child: SizedBox(
                              width: s * 2.75,
                              child: _StarsSvg(color: _kStarColor, size: s),
                            ),
                          ),
                        ),
                        // ── Circle container (trượt trái ↔ phải) ──
                        // Nằm TRONG vùng clip nên quầng sáng bị cắt gọn trong pill
                        Positioned(
                          left: circleLeft,
                          top: -off,
                          child: Container(
                            width: ccd,
                            height: ccd,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(ccd),
                              boxShadow: [
                                BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 0, spreadRadius: s * 0.625),
                                BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 0, spreadRadius: s * 1.25),
                              ],
                            ),
                            alignment: Alignment.center,
                            // ── Sun/Moon ball ──
                            child: Container(
                              width: smd,
                              height: smd,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(smd),
                                // Bevel mặt trời: sáng góc trên-trái, tối cạnh dưới
                                // (mô phỏng 2 inset shadow của CSS bằng gradient)
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFDF3B8), // highlight trên-trái
                                    _kSunColor,
                                    Color(0xFFC9A417), // #a1872a tối cạnh dưới
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                                // filter: drop-shadow của CSS
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: Offset(s * 0.062, s * 0.125), blurRadius: s * 0.125),
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: Offset(0, s * 0.062), blurRadius: s * 0.125),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  // Moon slides in from right
                                  Positioned(
                                    left: moonSlide,
                                    top: 0,
                                    width: smd,
                                    height: smd,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(smd),
                                        // Bevel mặt trăng: sáng trên-trái, tối cạnh dưới
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFE4E7EC), // highlight
                                            _kMoonColor,
                                            Color(0xFF969696), // tối cạnh dưới
                                          ],
                                          stops: [0.0, 0.55, 1.0],
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(top: s * 0.75, left: s * 0.312, child: _Spot(size: s * 0.75)),
                                          Positioned(top: s * 0.937, left: s * 1.375, child: _Spot(size: s * 0.375)),
                                          Positioned(top: s * 0.312, left: s * 0.812, child: _Spot(size: s * 0.25)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

// ─────────────────────────────────────────────────────────────────────────────
// CLOUD — Mô phỏng box-shadow cascade của CSS bằng cách vẽ nhiều hình tròn
// ─────────────────────────────────────────────────────────────────────────────

class _Clouds extends StatelessWidget {
  final double size; // 1em

  const _Clouds({required this.size});

  @override
  Widget build(BuildContext context) {
    final s = size;
    final d = s * 1.25; // đường kính puff cơ sở (width/height 1.25em)
    final sp = s * 0.437; // spread của 2 puff đặc biệt

    // box-shadow syntax: offsetX offsetY [blur] [spread] color
    // Tất cả blur=0. Đường kính = base + 2*spread. Chỉ 2 puff cuối có spread.
    // (dx, dy, extraDiameter, color)  — dx,dy tính bằng em (nhân s)
    final dots = <_CloudDot>[
      _CloudDot(0,        0,        0,    _kCloudFront), // base (element gốc)
      _CloudDot(s*0.937,  s*0.312,  0,    _kCloudFront),
      _CloudDot(-s*0.312, -s*0.312, 0,    _kCloudBack),
      _CloudDot(s*1.437,  s*0.375,  0,    _kCloudFront),
      _CloudDot(s*0.5,    -s*0.125, 0,    _kCloudBack),
      _CloudDot(s*2.187,  0,        0,    _kCloudFront),
      _CloudDot(s*1.25,   -s*0.062, 0,    _kCloudBack),
      _CloudDot(s*2.937,  s*0.312,  0,    _kCloudFront),
      _CloudDot(s*2.0,    -s*0.312, 0,    _kCloudBack),
      _CloudDot(s*3.625,  -s*0.062, 0,    _kCloudFront),
      _CloudDot(s*2.625,  0,        0,    _kCloudBack),
      _CloudDot(s*4.5,    -s*0.312, 0,    _kCloudFront),
      _CloudDot(s*3.375,  -s*0.437, 0,    _kCloudBack),
      _CloudDot(s*4.625,  -s*1.75,  sp*2, _kCloudFront), // spread 0.437em
      _CloudDot(s*4.0,    -s*0.625, 0,    _kCloudBack),
      _CloudDot(s*4.125,  -s*2.125, sp*2, _kCloudBack),  // spread 0.437em
    ];

    // Canvas đủ lớn; base puff đặt ở đáy-trái, các puff khác toả lên/sang phải.
    // Phần tràn ra ngoài sẽ bị container (overflow hidden) cắt — giống CSS.
    return CustomPaint(
      size: Size(s * 7, s * 5),
      painter: _CloudsPainter(baseD: d, dots: dots),
    );
  }
}

class _CloudDot {
  final double dx, dy, extraDiameter;
  final Color color;
  const _CloudDot(this.dx, this.dy, this.extraDiameter, this.color);
}

class _CloudsPainter extends CustomPainter {
  final double baseD;
  final List<_CloudDot> dots;
  const _CloudsPainter({required this.baseD, required this.dots});

  @override
  void paint(Canvas canvas, Size size) {
    // Base puff nằm ở đáy-trái canvas; puff có dy âm sẽ toả lên trên.
    // Tâm base = (baseD/2, size.height - baseD/2)
    final baseCx = baseD / 2;
    final baseCy = size.height - baseD / 2;

    // CSS: box-shadow đầu danh sách vẽ TRÊN. Nên vẽ ngược (cuối → đầu),
    // riêng base (index 0) vẽ sau cùng để nằm trên tất cả.
    for (int i = dots.length - 1; i >= 1; i--) {
      _draw(canvas, baseCx, baseCy, dots[i]);
    }
    _draw(canvas, baseCx, baseCy, dots[0]);
  }

  void _draw(Canvas canvas, double baseCx, double baseCy, _CloudDot dot) {
    final r = (baseD + dot.extraDiameter) / 2;
    canvas.drawCircle(
      Offset(baseCx + dot.dx, baseCy + dot.dy),
      r,
      Paint()..color = dot.color,
    );
  }

  @override
  bool shouldRepaint(_CloudsPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// MOON SPOT
// ─────────────────────────────────────────────────────────────────────────────

class _Spot extends StatelessWidget {
  final double size;
  const _Spot({required this.size});

  @override
  Widget build(BuildContext context) {
    // CSS: box-shadow 0 0.0312em 0.062em rgba(0,0,0,0.25) inset
    // = crater lõm: tối ở phần trên trong lòng, chuyển sang màu spot bên dưới
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7E8698), // tối ở đỉnh (bóng inset)
            _kSpotColor,
          ],
          stops: [0.0, 0.6],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STARS SVG — Port path từ SVG gốc
// viewBox="0 0 144 55" — vẽ bằng CustomPainter để scale theo em
// ─────────────────────────────────────────────────────────────────────────────

class _StarsSvg extends StatelessWidget {
  final Color color;
  final double size;
  const _StarsSvg({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    // width=2.75em trong CSS, viewBox=144x55
    final w = size * 2.75;
    final h = w * 55 / 144;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: _StarsPainter(color: color),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final Color color;
  const _StarsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 144;
    final sy = size.height / 55;
    canvas.save();
    canvas.scale(sx, sy);

    final path = Path();
    // Star-like paths từ SVG (fill-rule: evenodd)
    // Mỗi "ngôi sao nhỏ" = 4 cánh hình thoi giao nhau
    _addStar(path, 136.996, 4.35447, 4.0);   // rightmost top
    _addStar(path, 34.9956, 23.3545, 4.0);   // left
    _addStar(path, 3.99559, 36.3545, 4.0);   // far left
    _addStar(path, 57.9956, 25.3545, 4.0);   // center-left
    _addStar(path, 84.9956, 25.3545, 4.0);   // center
    _addStar(path, 139.996, 36.3545, 4.0);   // far right
    _addStar(path, 102.996, 50.3545, 4.0);   // bottom

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.restore();
  }

  /// Vẽ ngôi sao nhỏ 4 cánh (giống SVG path: 2 trục giao nhau)
  void _addStar(Path p, double cx, double cy, double r) {
    // Trục dọc
    p.moveTo(cx, cy - r);
    p.cubicTo(cx - r*0.18, cy - r*0.35, cx - r*0.35, cy - r*0.18, cx - r*0.5, cy);
    p.cubicTo(cx - r*0.35, cy + r*0.18, cx - r*0.18, cy + r*0.35, cx, cy + r);
    p.cubicTo(cx + r*0.18, cy + r*0.35, cx + r*0.35, cy + r*0.18, cx + r*0.5, cy);
    p.cubicTo(cx + r*0.35, cy - r*0.18, cx + r*0.18, cy - r*0.35, cx, cy - r);
    p.close();
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ThemeSwitchDemo extends StatefulWidget {
  const ThemeSwitchDemo({super.key});

  @override
  State<ThemeSwitchDemo> createState() => _ThemeSwitchDemoState();
}

class _ThemeSwitchDemoState extends State<ThemeSwitchDemo> {
  bool _isNight = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = Color.lerp(const Color(0xFFF0F9FF), const Color(0xFF111827), _isNight ? 1.0 : 0.0)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: _isNight ? Colors.white : const Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Theme Switch',
            style: TextStyle(
              color: _isNight ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: TextStyle(
                  color: _isNight
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                child: Text(_isNight ? '🌙 Night mode' : '☀️  Day mode'),
              ),
              const SizedBox(height: 32),

              // Switch size mặc định (30px)
              ThemeSwitch(
                value: _isNight,
                onChanged: (v) => setState(() => _isNight = v),
              ),

              const SizedBox(height: 48),

              // Switch size nhỏ hơn (20px)
              ThemeSwitch(
                toggleSize: 20,
                value: _isNight,
                onChanged: (v) => setState(() => _isNight = v),
              ),

              const SizedBox(height: 24),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: TextStyle(
                  color: _isNight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontSize: 11,
                ),
                child: const Text('Size 20px'),
              ),

              const SizedBox(height: 48),

              // Switch size lớn hơn (40px)
              ThemeSwitch(
                toggleSize: 40,
                value: _isNight,
                onChanged: (v) => setState(() => _isNight = v),
              ),
              const SizedBox(height: 12),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: TextStyle(
                  color: _isNight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontSize: 11,
                ),
                child: const Text('Size 40px'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
