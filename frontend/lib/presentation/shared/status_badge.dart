import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  Color _getStatusColor(String s) {
    switch (s) {
      case 'Pending':
        return AppColors.statusPending;
      case 'In_Warehouse':
        return AppColors.statusInWarehouse;
      case 'Dispatched_to_Driver':
        return AppColors.statusDispatched;
      case 'Delivered':
        return AppColors.statusDelivered;
      case 'Postponed':
        return AppColors.statusPostponed;
      case 'Canceled':
        return AppColors.statusCanceled;
      case 'Returned':
        return AppColors.statusReturned;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatArabicStatus(String s) {
    return AppConstants.orderStatusArabic[s] ?? s.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatArabicStatus(status),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
