import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'status_badge.dart';

class OrderTimelineWidget extends StatelessWidget {
  final String currentStatus;
  final List<dynamic> timelineHistory;

  const OrderTimelineWidget({
    super.key,
    required this.currentStatus,
    required this.timelineHistory,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return AppColors.statusPending;
      case 'In_Warehouse': return AppColors.statusInWarehouse;
      case 'Dispatched_to_Driver': return AppColors.statusDispatched;
      case 'Delivered': return AppColors.statusDelivered;
      case 'Postponed': return AppColors.statusPostponed;
      case 'Canceled': return AppColors.statusCanceled;
      case 'Returned': return AppColors.statusReturned;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // المراحل القياسية للشحنة
    final defaultMilestones = [
      {'status': 'Pending', 'title': 'تم تأكيد الأوردر', 'desc': 'تم تسجيل الطلب بالنظام وجاري إرساله للمخزن.'},
      {'status': 'In_Warehouse', 'title': 'في المخزن والتجهيز', 'desc': 'تم تجهيز الشحنة وطباعة بوليصة الشحن الحرارية.'},
      {'status': 'Dispatched_to_Driver', 'title': 'مع المندوب على خط السير', 'desc': 'خرجت الشحنة للتوصيل المباشر إلى عنوان العميل.'},
      {'status': 'Delivered', 'title': 'تم التسليم بنجاح', 'desc': 'تم تسليم الأوردر للعميل وتحصيل المبلغ المطلوب.'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timelineHistory.isNotEmpty ? timelineHistory.length : defaultMilestones.length,
      itemBuilder: (context, idx) {
        final isCustomHistory = timelineHistory.isNotEmpty;
        final item = isCustomHistory ? timelineHistory[idx] : defaultMilestones[idx];
        final status = isCustomHistory ? (item['status'] ?? 'Pending') : item['status'] as String;
        final title = isCustomHistory ? (AppConstants.orderStatusArabic[status] ?? status) : item['title'] as String;
        final notes = isCustomHistory ? (item['notes'] ?? '') : item['desc'] as String;
        final timestamp = isCustomHistory && item['timestamp'] != null
            ? item['timestamp'].toString().split('T')[0]
            : 'اليوم';
        final reasonCode = isCustomHistory ? item['reason_code'] : null;

        final isLast = idx == (isCustomHistory ? timelineHistory.length - 1 : defaultMilestones.length - 1);
        final color = _getStatusColor(status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مؤشر النقطة والخط الرأسي
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // محتوى المرحلة
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.black, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          Text(
                            timestamp,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          notes,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      if (reasonCode != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusPostponed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.statusPostponed.withOpacity(0.3)),
                          ),
                          child: Text(
                            'سبب التأجيل: $reasonCode',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusPostponed),
                          ),
                        ),
                      ],
                    ],
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
