import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:untitled/circular_reveal_transition.dart';
import 'package:untitled/fluid_morphing_transition.dart';
import 'package:untitled/fluid_toast.dart';
import 'package:untitled/morphing_typography.dart';
import 'package:untitled/morphing_quick_actions.dart';
import 'package:untitled/shutter_transition.dart';
import 'package:untitled/origami_transition.dart';
import 'package:untitled/pixelate_transition.dart';
import 'package:untitled/disintegrate_transition.dart';
import 'package:untitled/shatter_glass_transition.dart';
import 'package:untitled/glitch_transition.dart';
import 'package:untitled/airdrop_wave_transition.dart';
import 'package:untitled/theme_switch.dart';
import 'package:untitled/interactive_shader.dart';
import 'package:untitled/practical_shaders.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transition Effects Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const CircularRevealDemo(),
    );
  }
}

class CircularRevealDemo extends StatefulWidget {
  const CircularRevealDemo({super.key});

  @override
  State<CircularRevealDemo> createState() => _CircularRevealDemoState();
}

class _CircularRevealDemoState extends State<CircularRevealDemo>
    with TickerProviderStateMixin {
  Offset _tapPosition = Offset.zero;
  bool _showOverlay = true;
  bool _useLiquidMorph = true; // Mặc định dùng Liquid Morph mới

  // Lưu trữ vị trí cuộn hiện tại của Dashboard để đồng bộ hóa hoàn hảo khi chuyển theme
  double _scrollOffset = 0.0;

  // Các biến phục vụ đổi Theme (Dark/Light mode) lan tỏa vòng tròn
  bool _isDarkMode = true;
  bool _isThemeTransitioning = false;
  bool _oldThemeDarkMode = true;
  Offset _themeToggleCenter = Offset.zero;
  late AnimationController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _themeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isThemeTransitioning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    if (!_showOverlay) return;
    setState(() {
      _tapPosition = details.localPosition;
      _showOverlay = false;
    });
  }

  void _reset() {
    setState(() {
      _showOverlay = true;
      _tapPosition = Offset.zero;
    });
  }

  // Hàm chuyển đổi theme và kích hoạt hoạt ảnh Circular Reveal
  void _toggleTheme(Offset tapPosition) {
    if (_isThemeTransitioning) return;
    setState(() {
      _oldThemeDarkMode = _isDarkMode;
      _isDarkMode = !_isDarkMode;
      _themeToggleCenter = tapPosition;
      _isThemeTransitioning = true;
    });
    _themeController.forward(from: 0.0);
  }

  Widget _buildMainContent({required bool isDarkMode, double initialScrollOffset = 0.0, Key? key}) {
    return _useLiquidMorph
        ? LiquidMorphOverlay(
            key: key,
            showOverlay: _showOverlay,
            tapPosition: _tapPosition == Offset.zero ? null : _tapPosition,
            overlay: GestureDetector(
              onTapDown: _handleTap,
              child: const OverlayScreen(effectName: 'LIQUID MORPH'),
            ),
            child: BaseDashboardScreen(
              key: key != null ? ValueKey('${(key as ValueKey).value}_inner') : null,
              onReset: _reset,
              useLiquidMorph: _useLiquidMorph,
              isDarkMode: isDarkMode,
              onToggleTheme: _toggleTheme,
              initialScrollOffset: initialScrollOffset,
              onScroll: (offset) {
                _scrollOffset = offset;
              },
              onToggleEffect: (val) {
                setState(() {
                  _useLiquidMorph = val;
                });
              },
            ),
          )
        : CircularRevealOverlay(
            key: key,
            showOverlay: _showOverlay,
            tapPosition: _tapPosition == Offset.zero ? null : _tapPosition,
            overlay: GestureDetector(
              onTapDown: _handleTap,
              child: const OverlayScreen(effectName: 'CIRCULAR REVEAL'),
            ),
            child: BaseDashboardScreen(
              key: key != null ? ValueKey('${(key as ValueKey).value}_inner') : null,
              onReset: _reset,
              useLiquidMorph: _useLiquidMorph,
              isDarkMode: isDarkMode,
              onToggleTheme: _toggleTheme,
              initialScrollOffset: initialScrollOffset,
              onScroll: (offset) {
                _scrollOffset = offset;
              },
              onToggleEffect: (val) {
                setState(() {
                  _useLiquidMorph = val;
                });
              },
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Giao diện chính luôn giữ Key cố định để bảo toàn State và vị trí cuộn
          _buildMainContent(
            isDarkMode: _isDarkMode,
            initialScrollOffset: _scrollOffset,
            key: const ValueKey('main_dashboard_root'),
          ),
          // 2. Giao diện theme cũ được đục lỗ tròn to dần ra để lộ theme mới ở dưới
          if (_isThemeTransitioning)
            AnimatedBuilder(
              animation: _themeController,
              builder: (context, child) {
                return ClipPath(
                  clipper: CircularHoleClipper(
                    revealPercent: _themeController.value, // Đục lỗ to dần từ tâm chạm
                    center: _themeToggleCenter,
                  ),
                  child: _buildMainContent(
                    isDarkMode: _oldThemeDarkMode,
                    initialScrollOffset: _scrollOffset,
                    key: const ValueKey('theme_transition_overlay'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// MÀN HÌNH BÊN DƯỚI (Base Screen / Dashboard)
class BaseDashboardScreen extends StatefulWidget {
  final VoidCallback onReset;
  final bool useLiquidMorph;
  final ValueChanged<bool> onToggleEffect;
  final bool isDarkMode;
  final ValueChanged<Offset> onToggleTheme;
  final double initialScrollOffset;
  final ValueChanged<double> onScroll;

  const BaseDashboardScreen({
    super.key,
    required this.onReset,
    required this.useLiquidMorph,
    required this.onToggleEffect,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.initialScrollOffset,
    required this.onScroll,
  });

  @override
  State<BaseDashboardScreen> createState() => _BaseDashboardScreenState();
}

class _BaseDashboardScreenState extends State<BaseDashboardScreen> {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;
  bool _isSnapping = false; // Cờ theo dõi trạng thái Snap để tránh lặp hoạt ảnh vô tận

  @override
  void initState() {
    super.initState();
    _scrollOffset = widget.initialScrollOffset;
    _scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
      widget.onScroll(_scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Xử lý tự động Snap khi người dùng dừng cuộn ở khoảng giữa Morphing
  void _handleScrollNotification(ScrollNotification notification) {
    if (_isSnapping) return;

    if (notification is ScrollEndNotification) {
      final double offset = _scrollController.offset;
      
      // Khoảng diễn ra Morphing là từ 230px đến 370px
      // Ngưỡng quyết định snap là điểm chính giữa 300px
      if (offset > 0.0 && offset < 370.0) {
        double targetOffset = 0.0; // Snap về hiển thị dạng Grid đầy đủ
        if (offset >= 300.0) {
          targetOffset = 370.0; // Snap lên dạng Tab bar bám dính gọn gàng
        }

        _isSnapping = true;
        
        // Thực hiện cuộn snap mượt mà bằng hoạt ảnh easeOutCubic
        Future.microtask(() {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          ).then((_) {
            _isSnapping = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), // Slate 900 / Slate 50
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DASHBOARD',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          // Nút chuyển đổi Dark/Light Mode với hiệu ứng Circular Reveal lan tỏa
          GestureDetector(
            onTapDown: (details) {
              widget.onToggleTheme(details.globalPosition);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? Colors.amberAccent : const Color(0xFF1E293B),
                size: 20,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            tooltip: 'Khóa lại màn hình',
            onPressed: widget.onReset,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Vị trí Y ban đầu của Grid trên screen (phù hợp với khoảng trống placeholder)
          final double gridStartY = 502.0;
          final double pinY = 0.0; // Bám dính ngay dưới AppBar
          final double currentY = math.max(pinY, gridStartY - _scrollOffset);

          return Stack(
            children: [
              // Lớp 1: Nội dung cuộn chính
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _handleScrollNotification(notification);
                  return false; // Cho phép notification lan truyền tiếp tục
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào buổi sáng,',
                      style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    Text(
                      'Tuan Nguyen 👋',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),
                    
                    // Selector kiểu hiệu ứng
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSelectorBtn('Circular', !widget.useLiquidMorph, () => widget.onToggleEffect(false)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSelectorBtn('Liquid Gooey', widget.useLiquidMorph, () => widget.onToggleEffect(true)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tổng số dư tài khoản', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          const Text(
                            '\$124,580.00',
                            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildBalanceDetail('Thu nhập', '+\$12,450', Colors.greenAccent),
                              _buildBalanceDetail('Chi tiêu', '-\$3,210', Colors.redAccent),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Demo Navigation Button
                    Builder(
                      builder: (context) {
                        return GestureDetector(
                          onTapDown: (details) {
                            Navigator.push(
                              context,
                              widget.useLiquidMorph
                                  ? LiquidMorphPageRoute(
                                      page: const DetailScreen(),
                                      center: details.globalPosition,
                                    )
                                  : CircularRevealPageRoute(
                                      page: const DetailScreen(),
                                      center: details.globalPosition,
                                    ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.useLiquidMorph
                                    ? [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]
                                    : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.useLiquidMorph ? const Color(0xFF8B5CF6) : const Color(0xFFD97706)).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.open_in_new_rounded, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  widget.useLiquidMorph
                                      ? 'Mở trang Chi tiết (Liquid Morph)'
                                      : 'Mở trang Chi tiết (Circular Route)',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    ),

                    const SizedBox(height: 32),
                    Text(
                      'Tính năng nhanh',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 16),
                    
                    // Khoảng trống Placeholder để Grid bám dính bám vào mà không làm nhảy layout dưới
                    const SizedBox(height: 236.0),

                    const SizedBox(height: 32),
                    Text(
                      'Hiệu ứng nâng cao',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 16),
                    // Morphing Typography Card
                    Builder(
                      builder: (context) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MorphingTypographyDemo(),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? const LinearGradient(
                                    colors: [Color(0xFF334155), Color(0xFF1E293B)],
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
                                  ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Morphing Typography',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Text biến đổi thành text khác với 3 kiểu hiệu ứng',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Shutter Transition Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'Shutter Transition',
                      subtitle: 'Cửa sập đóng mở - các dải ngang xoay tiết lộ trang mới',
                      icon: Icons.blinds_rounded,
                      gradientColors: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShutterTransitionDemo())),
                    ),

                    const SizedBox(height: 12),

                    // Origami Fold Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'Origami Fold',
                      subtitle: 'Màn hình gấp lại như giấy origami rồi mở ra',
                      icon: Icons.auto_awesome_mosaic_rounded,
                      gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrigamiTransitionDemo())),
                    ),

                    const SizedBox(height: 12),

                    // Pixelate Dissolve Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'Pixelate Dissolve',
                      subtitle: 'Phân rã thành pixel lan tỏa từ điểm chạm',
                      icon: Icons.grid_view_rounded,
                      gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PixelateTransitionDemo())),
                    ),

                    const SizedBox(height: 12),

                    // Disintegrate Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'Disintegrate',
                      subtitle: 'Tan biến thành tro bụi bay theo gió lộ trang kế',
                      icon: Icons.grain_rounded,
                      gradientColors: const [Color(0xFFFB7185), Color(0xFFF59E0B)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisintegrateTransitionDemo())),
                    ),

                    const SizedBox(height: 12),

                    // Shatter Glass Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'Shatter Glass',
                      subtitle: 'Vỡ kính thành mảnh rơi xoay theo trọng lực',
                      icon: Icons.broken_image_rounded,
                      gradientColors: const [Color(0xFF60A5FA), Color(0xFFA78BFA)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShatterGlassTransitionDemo())),
                    ),

                    const SizedBox(height: 12),

                    // Glitch Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'Glitch / Datamosh',
                      subtitle: 'Nhiễu số cyberpunk tách kênh RGB rồi cắt cảnh',
                      icon: Icons.sensors_rounded,
                      gradientColors: const [Color(0xFF22D3EE), Color(0xFFE879F9)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlitchTransitionDemo())),
                    ),

                    const SizedBox(height: 12),

                    // AirDrop Wave Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'AirDrop Wave',
                      subtitle: 'Sóng cuộn phát sáng lan tỏa kiểu AirDrop iPhone',
                      icon: Icons.wifi_tethering_rounded,
                      gradientColors: const [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AirdropWaveTransitionDemo())),
                    ),

                    const SizedBox(height: 12),

                    // Theme Switch Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'Day / Night Switch',
                      subtitle: 'Toggle ngày đêm có mây, mặt trăng, ngôi sao',
                      icon: Icons.wb_twilight_rounded,
                      gradientColors: const [Color(0xFF3D7EAE), Color(0xFF1D1F2C)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSwitchDemo())),
                    ),

                    const SizedBox(height: 12),

                    // Interactive Shader Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'Interactive Shader',
                      subtitle: 'Fragment shader GLSL plasma phản ứng chạm & thời gian',
                      icon: Icons.auto_fix_high_rounded,
                      gradientColors: const [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InteractiveShaderDemo())),
                    ),

                    const SizedBox(height: 12),

                    // Practical Shaders Card
                    _buildEffectCard(
                      context: context,
                      isDark: isDark,
                      title: 'Practical Shaders',
                      subtitle: 'Shimmer skeleton · Holographic card · Aurora nền',
                      icon: Icons.layers_rounded,
                      gradientColors: const [Color(0xFF00C853), Color(0xFF0055FF)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticalShadersDemo())),
                    ),

                    // Thêm danh sách giao dịch gần đây để màn hình có thể cuộn sâu hơn
                    const SizedBox(height: 32),
                    Text(
                      'Giao dịch gần đây',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 16),
                    _buildTransactionItem('Nguyễn Văn A', 'Chuyển tiền mua quà', '-\$120.00', Colors.redAccent),
                    _buildTransactionItem('Salary July', 'Nhận lương tháng 7', '+\$4,500.00', Colors.greenAccent),
                    _buildTransactionItem('Electric Bill', 'Thanh toán tiền điện', '-\$85.50', Colors.redAccent),
                    _buildTransactionItem('Trần Thị B', 'Hoàn trả tiền vay', '+\$300.00', Colors.greenAccent),
                    _buildTransactionItem('Netflix Premium', 'Gia hạn gói dịch vụ', '-\$15.00', Colors.redAccent),
                    const SizedBox(height: 120), // Padding thêm ở dưới cùng để cuộn mượt mà
                  ],
                ),
              ),
            ),

              // Lớp 2: Thanh tính năng nhanh tự biến dạng và bám dính khi cuộn
              Positioned(
                left: 0,
                top: currentY,
                right: 0,
                child: MorphingQuickActions(
                  scrollOffset: _scrollOffset,
                  parentWidth: constraints.maxWidth,
                  isDarkMode: isDark,
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSelectorBtn(String label, bool isSelected, VoidCallback onTap) {
    final bool isDark = widget.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigoAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceDetail(String title, String amount, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Icon(
            amount.startsWith('+') ? Icons.arrow_downward : Icons.arrow_upward,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
  Widget _buildEffectCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)])
                : const LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
            ),
            boxShadow: isDark
                ? null
                : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white60 : const Color(0xFF64748B), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String name, String detail, String amount, Color amountColor) {
    final bool isDark = widget.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              amount.startsWith('+') ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(fontWeight: FontWeight.bold, color: amountColor, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// MÀN HÌNH NẰM ĐÈ (Overlay Screen)
class OverlayScreen extends StatelessWidget {
  final String effectName;

  const OverlayScreen({
    super.key,
    required this.effectName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // Indigo
            Color(0xFFEC4899), // Pink
            Color(0xFFF59E0B), // Amber
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'ĐANG KHÓA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Hiệu ứng: $effectName',
                style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Chạm vào bất kỳ vị trí nào trên màn hình để mở khóa bằng hiệu ứng lỏng / vòng tròn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 48),
            const AnimatedPulseIcon(),
          ],
        ),
      ),
    );
  }
}

/// Icon hiệu ứng nhấp nháy chỉ dẫn chạm
class AnimatedPulseIcon extends StatefulWidget {
  const AnimatedPulseIcon({super.key});

  @override
  State<AnimatedPulseIcon> createState() => _AnimatedPulseIconState();
}

class _AnimatedPulseIconState extends State<AnimatedPulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.touch_app_rounded,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// MÀN HÌNH CHI TIẾT (dùng để demo Circular Navigation)
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CHI TIẾT GIAO DỊCH'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Giao dịch thành công',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mã giao dịch: #TXN88394829',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),
            _buildDetailRow('Số tiền chuyển', '\$2,500.00'),
            _buildDetailRow('Người nhận', 'Nguyen Van A'),
            _buildDetailRow('Ngân hàng', 'Vietcombank'),
            _buildDetailRow('Nội dung', 'Chuyển tiền mua quà tặng sinh nhật'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Quay lại Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
