import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:untitled/circular_reveal_transition.dart';
import 'package:untitled/fluid_morphing_transition.dart';
import 'package:untitled/fluid_toast.dart';
import 'package:untitled/morphing_typography.dart';
import 'package:untitled/morphing_quick_actions.dart';

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

class _CircularRevealDemoState extends State<CircularRevealDemo> {
  Offset _tapPosition = Offset.zero;
  bool _showOverlay = true;
  bool _useLiquidMorph = true; // Mặc định dùng Liquid Morph mới

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _useLiquidMorph
          ? LiquidMorphOverlay(
              showOverlay: _showOverlay,
              tapPosition: _tapPosition == Offset.zero ? null : _tapPosition,
              overlay: GestureDetector(
                onTapDown: _handleTap,
                child: const OverlayScreen(effectName: 'LIQUID MORPH'),
              ),
              child: BaseDashboardScreen(
                onReset: _reset,
                useLiquidMorph: _useLiquidMorph,
                onToggleEffect: (val) {
                  setState(() {
                    _useLiquidMorph = val;
                  });
                },
              ),
            )
          : CircularRevealOverlay(
              showOverlay: _showOverlay,
              tapPosition: _tapPosition == Offset.zero ? null : _tapPosition,
              overlay: GestureDetector(
                onTapDown: _handleTap,
                child: const OverlayScreen(effectName: 'CIRCULAR REVEAL'),
              ),
              child: BaseDashboardScreen(
                onReset: _reset,
                useLiquidMorph: _useLiquidMorph,
                onToggleEffect: (val) {
                  setState(() {
                    _useLiquidMorph = val;
                  });
                },
              ),
            ),
    );
  }
}

/// MÀN HÌNH BÊN DƯỚI (Base Screen / Dashboard)
class BaseDashboardScreen extends StatefulWidget {
  final VoidCallback onReset;
  final bool useLiquidMorph;
  final ValueChanged<bool> onToggleEffect;

  const BaseDashboardScreen({
    super.key,
    required this.onReset,
    required this.useLiquidMorph,
    required this.onToggleEffect,
  });

  @override
  State<BaseDashboardScreen> createState() => _BaseDashboardScreenState();
}

class _BaseDashboardScreenState extends State<BaseDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isSnapping = false; // Cờ theo dõi trạng thái Snap để tránh lặp hoạt ảnh vô tận

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'DASHBOARD',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
                    const Text(
                      'Chào buổi sáng,',
                      style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                    ),
                    const Text(
                      'Tuan Nguyen 👋',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    
                    // Selector kiểu hiệu ứng
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    const Text(
                      'Tính năng nhanh',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    // Khoảng trống Placeholder để Grid bám dính bám vào mà không làm nhảy layout dưới
                    const SizedBox(height: 236.0),

                    const SizedBox(height: 32),
                    const Text(
                      'Hiệu ứng nâng cao',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFF334155), Color(0xFF1E293B)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Morphing Typography',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Text biến đổi thành text khác với 3 kiểu hiệu ứng',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Thêm danh sách giao dịch gần đây để màn hình có thể cuộn sâu hơn
                    const SizedBox(height: 32),
                    const Text(
                      'Giao dịch gần đây',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSelectorBtn(String label, bool isSelected, VoidCallback onTap) {
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
            color: isSelected ? Colors.white : Colors.white60,
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
  Widget _buildTransactionItem(String name, String detail, String amount, Color amountColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.1),
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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
