import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../frontend/theme/app_colors.dart';
import 'notch_painter.dart';

class NotchTabItemData {
  final String keyName;
  final String label;
  final String? assetPath;
  final IconData? icon;

  const NotchTabItemData({
    required this.keyName,
    required this.label,
    this.assetPath,
    this.icon,
  });
}

/// Widget thanh TabBar rãnh lõm di động uốn cong với quả cầu nổi hoạt họa
class NotchTabBar extends StatefulWidget {
  final List<NotchTabItemData> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const NotchTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  State<NotchTabBar> createState() => _NotchTabBarState();
}

class _NotchTabBarState extends State<NotchTabBar> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  double _currentNotchX = 0;
  double _startX = 0;
  double _endX = 0;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.14).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.14, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_scaleController);

    _moveController.addListener(() {
      if (mounted) {
        final progress = _moveController.value;
        final curvedProgress = Curves.easeOutCubic.transform(progress);
        setState(() {
          _currentNotchX = _startX + (_endX - _startX) * curvedProgress;
        });
      }
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NotchTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateToTab(widget.currentIndex);
    }
  }

  void _animateToTab(int targetIndex) {
    if (!mounted) return;
    final width = MediaQuery.of(context).size.width - 32;
    final tabWidth = width / widget.items.length;
    _startX = _currentNotchX > 0 ? _currentNotchX : _getCenterForTab(widget.currentIndex, width);
    _endX = tabWidth * targetIndex + tabWidth / 2;

    _moveController.forward(from: 0.0);
    _scaleController.forward(from: 0.0);
  }

  double _getCenterForTab(int index, double width) {
    final tabWidth = width / widget.items.length;
    return tabWidth * index + tabWidth / 2;
  }

  Widget _buildIconWidget(NotchTabItemData item, {double size = 22, Color? color}) {
    if (item.assetPath != null && item.assetPath!.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          item.assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Icon(
            item.icon ?? Icons.circle,
            size: size,
            color: color ?? AppColors.textSecondary,
          ),
        ),
      );
    }
    return Icon(
      item.icon ?? Icons.circle,
      size: size,
      color: color ?? AppColors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalWidth = constraints.maxWidth;
        final activeX = _getCenterForTab(widget.currentIndex, totalWidth);

        if (_currentNotchX == 0) {
          _currentNotchX = activeX;
          _startX = activeX;
          _endX = activeX;
        }

        final activeItem = widget.items[widget.currentIndex];

        return SizedBox(
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Curved Notched Background Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(totalWidth, 64),
                  painter: NotchPainter(
                    notchCenterX: _currentNotchX,
                    backgroundColor: AppColors.surface,
                    borderColor: AppColors.border,
                  ),
                ),
              ),

              // 2. Animated Floating Sphere
              Positioned(
                left: _currentNotchX - 26,
                top: 0,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.darkBeige,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkBeige.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _buildIconWidget(activeItem, size: 28, color: AppColors.accentBeige),
                    ),
                  ),
                ),
              ),

              // 3. Tab Items Row
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: List.generate(widget.items.length, (index) {
                      final item = widget.items[index];
                      final isSelected = widget.currentIndex == index;

                      return Expanded(
                        child: Semantics(
                          label: item.label,
                          selected: isSelected,
                          child: InkWell(
                            onTap: () {
                              if (!isSelected) {
                                HapticFeedback.lightImpact();
                                widget.onChanged(index);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Opacity(
                                    opacity: isSelected ? 0.0 : 1.0,
                                    child: _buildIconWidget(item, size: 22, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 3),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? AppColors.darkBeige : AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
