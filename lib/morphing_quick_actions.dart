import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:untitled/fluid_toast.dart';

// =========================================================================
// MORPHING QUICK ACTIONS (STICKY GRID TO HORIZONTAL TABS TRANSITION)
// =========================================================================

/// Widget quản lý hiệu ứng biến đổi (Morphing) của phần "Tính năng nhanh"
/// - Khi ở dưới: Là Grid 2x2 gồm 4 thẻ dịch vụ đầy đủ thông tin (Icon to, Title, Description).
/// - Khi cuộn lên sát mép trên: Tự động co giãn biến hình thành thanh Tab bar nằm ngang 
///   gọn gàng, bám dính (sticky) ở đỉnh màn hình để người dùng tiện tương tác mọi lúc.
class MorphingQuickActions extends StatelessWidget {
  final double scrollOffset;
  final double parentWidth;

  const MorphingQuickActions({
    super.key,
    required this.scrollOffset,
    required this.parentWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Các mốc cuộn kích hoạt hiệu ứng Morphing (tính bằng px)
    // Grid bắt đầu tự chuyển dạng từ cuộn 240px đến 380px thì thành Tab bám dính hoàn toàn
    final double startMorph = 230.0;
    final double endMorph = 370.0;
    final double t = ((scrollOffset - startMorph) / (endMorph - startMorph)).clamp(0.0, 1.0);

    // Kích thước chiều rộng vùng vẽ nội dung (trừ padding lề 2 bên)
    final double paddingMargin = 20.0;
    final double w = parentWidth - (paddingMargin * 2);

    // 1. THÔNG SỐ KHI LÀM GRID 2X2 (t = 0.0)
    final double gridCardH = 110.0;
    final double gridSpacing = 16.0;
    final double gridCardW = (w - gridSpacing) / 2;
    
    final List<Offset> gridPositions = [
      const Offset(0, 0),                                 // Card 0
      Offset(gridCardW + gridSpacing, 0),                 // Card 1
      Offset(0, gridCardH + gridSpacing),                 // Card 2
      Offset(gridCardW + gridSpacing, gridCardH + gridSpacing), // Card 3
    ];
    final double gridTotalH = gridCardH * 2 + gridSpacing;

    // 2. THÔNG SỐ KHI LÀM HORIZONTAL STICKY TABS (t = 1.0)
    final double tabH = 46.0;
    final double tabW = 125.0;
    final double tabSpacing = 8.0;
    
    final List<Offset> tabPositions = [
      const Offset(0, 0),
      Offset(tabW + tabSpacing, 0),
      Offset((tabW + tabSpacing) * 2, 0),
      Offset((tabW + tabSpacing) * 3, 0),
    ];
    final double tabsTotalW = tabW * 4 + tabSpacing * 3;

    // 3. TÍNH TOÁN KÍCH THƯỚC NỘI SUY (LỜI THEO TIẾN TRÌNH t)
    final double containerH = _lerp(gridTotalH, tabH, t);
    final double cardW = _lerp(gridCardW, tabW, t);
    final double cardH = _lerp(gridCardH, tabH, t);

    // Dữ liệu 4 nút tính năng nhanh
    final List<_QuickActionData> items = [
      _QuickActionData(
        icon: Icons.swap_horiz_rounded,
        title: 'Chuyển tiền',
        desc: 'Chuyển nhanh 24/7',
        color: const Color(0xFF8B5CF6),
        toastMsg: 'Giao dịch chuyển khoản \$2,500.00 thành công!',
        isSuccess: true,
      ),
      _QuickActionData(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Quét mã QR',
        desc: 'Thanh toán tiện lợi',
        color: const Color(0xFF10B981),
        toastMsg: 'Đã quét và tải thành công hóa đơn QR!',
        isSuccess: true,
      ),
      _QuickActionData(
        icon: Icons.receipt_long_rounded,
        title: 'Hóa đơn',
        desc: 'Điện, nước, internet',
        color: const Color(0xFFF59E0B),
        toastMsg: 'Lỗi kết nối máy chủ hóa đơn. Vui lòng thử lại!',
        isSuccess: false,
      ),
      _QuickActionData(
        icon: Icons.trending_up_rounded,
        title: 'Đầu tư',
        desc: 'Quản lý danh mục',
        color: const Color(0xFFEC4899),
        toastMsg: 'Đã cập nhật danh mục đầu tư Apple (AAPL) thành công!',
        isSuccess: true,
      ),
    ];

    return Container(
      width: parentWidth,
      height: containerH + _lerp(0.0, 16.0, t), // Thêm padding khi làm Tab dính
      padding: EdgeInsets.symmetric(
        horizontal: paddingMargin,
        vertical: _lerp(0.0, 8.0, t),
      ),
      decoration: BoxDecoration(
        // Khi biến thành Sticky Tab, đổi sang nền tối đặc để che nội dung cuộn bên dưới
        color: Color.lerp(Colors.transparent, const Color(0xFF0F172A), t),
        border: Border(
          bottom: BorderSide(
            color: Color.lerp(Colors.transparent, Colors.white12, t)!,
            width: t,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Chỉ cho phép cuộn ngang khi đã thu gọn hoàn toàn thành Tab bar (t = 1.0)
        physics: t >= 0.99 ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
        child: SizedBox(
          // Chiều rộng nội dung mở rộng ra khi thành Tab ngang để hỗ trợ cuộn
          width: _lerp(w, tabsTotalW, t),
          height: containerH,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(4, (index) {
              final item = items[index];
              final gridPos = gridPositions[index];
              final tabPos = tabPositions[index];

              // Nội suy tọa độ vị trí của thẻ thứ i
              final double x = _lerp(gridPos.dx, tabPos.dx, t);
              final double y = _lerp(gridPos.dy, tabPos.dy, t);

              return Positioned(
                left: x,
                top: y,
                width: cardW,
                height: cardH,
                child: _buildMorphingCard(context, item, cardW, cardH, t),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Dựng và nội suy các widget con bên trong thẻ (Icon, Text)
  Widget _buildMorphingCard(
    BuildContext context,
    _QuickActionData item,
    double width,
    double height,
    double t,
  ) {
    // 1. Kích thước và vị trí của Container Icon
    final double gridIconBoxSize = 44.0;
    final double tabIconBoxSize = 30.0;
    final double iconBoxSize = _lerp(gridIconBoxSize, tabIconBoxSize, t);
    final double iconGraphicSize = _lerp(24.0, 16.0, t);

    final double iconLeft = _lerp(16.0, 8.0, t);
    // Khi thành Tab, căn giữa dọc icon
    final double iconTop = _lerp(12.0, (height - iconBoxSize) / 2, t);

    // 2. Nội suy vị trí và kích cỡ chữ Title
    final double titleFontSize = _lerp(15.0, 12.0, t);
    final double titleLeft = _lerp(16.0, 8.0 + iconBoxSize + 8.0, t);
    final double titleTop = _lerp(12.0 + gridIconBoxSize + 8.0, (height - titleFontSize - 4.0) / 2, t);

    // 3. Độ mờ Description (Mờ và biến mất hẳn khi t -> 1.0)
    final double descOpacity = (1.0 - t * 2.5).clamp(0.0, 1.0); // Ẩn nhanh hơn để tránh tràn chữ
    final double descLeft = 16.0;
    final double descTop = 12.0 + gridIconBoxSize + 8.0 + 20.0;

    return GestureDetector(
      onTapDown: (details) {
        // Tắt bàn phím hoặc Toast cũ trước
        FluidToastManager.show(
          context,
          message: item.toastMsg,
          tapPosition: details.globalPosition,
          isSuccess: item.isSuccess,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(_lerp(20.0, 12.0, t)), // Bo góc nhọn hơn khi làm tab
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Stack(
          children: [
            // A. Widget Icon Container
            Positioned(
              left: iconLeft,
              top: iconTop,
              width: iconBoxSize,
              height: iconBoxSize,
              child: Container(
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(_lerp(12.0, 8.0, t)),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: iconGraphicSize,
                ),
              ),
            ),
            
            // B. Widget Title Text
            Positioned(
              left: titleLeft,
              top: titleTop,
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                  color: Colors.white,
                ),
              ),
            ),

            // C. Widget Description Text (Fade out)
            if (descOpacity > 0.01)
              Positioned(
                left: descLeft,
                top: descTop,
                child: Opacity(
                  opacity: descOpacity,
                  child: Text(
                    item.desc,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Hàm nội suy tuyến tính (Linear Interpolation)
  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }
}

// Model Action Card Data
class _QuickActionData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final String toastMsg;
  final bool isSuccess;

  _QuickActionData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.toastMsg,
    required this.isSuccess,
  });
}
