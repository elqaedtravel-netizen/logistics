import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SwipeToActionButton extends StatefulWidget {
  final String text;
  final VoidCallback onSwiped;
  final Color backgroundColor;
  final Color thumbColor;

  const SwipeToActionButton({
    super.key,
    required this.text,
    required this.onSwiped,
    this.backgroundColor = AppColors.statusDelivered,
    this.thumbColor = Colors.white,
  });

  @override
  State<SwipeToActionButton> createState() => _SwipeToActionButtonState();
}

class _SwipeToActionButtonState extends State<SwipeToActionButton> {
  double _position = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - 56.0;

        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.backgroundColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: widget.backgroundColor.withOpacity(0.4), width: 1.5),
          ),
          child: Stack(
            children: [
              // نص السحب بالخلفية
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.backgroundColor,
                        fontWeight: FontWeight.black,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.keyboard_double_arrow_left, size: 20, color: widget.backgroundColor),
                  ],
                ),
              ),

              // الزر القابل للسحب
              Positioned(
                right: _position,
                top: 3,
                bottom: 3,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted) return;
                    setState(() {
                      // في التخطيط العربي (RTL)، السحب يكون لليسار (details.primaryDelta موجب بالنسبة للـ right)
                      _position = (_position - details.primaryDelta!).clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isCompleted) return;
                    if (_position >= maxDrag * 0.75) {
                      setState(() {
                        _position = maxDrag;
                        _isCompleted = true;
                      });
                      widget.onSwiped();
                    } else {
                      setState(() {
                        _position = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.backgroundColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
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
