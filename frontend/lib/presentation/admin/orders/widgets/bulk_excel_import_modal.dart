import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BulkExcelImportModal extends StatefulWidget {
  const BulkExcelImportModal({super.key});

  @override
  State<BulkExcelImportModal> createState() => _BulkExcelImportModalState();
}

class _BulkExcelImportModalState extends State<BulkExcelImportModal> {
  bool _fileLoaded = false;
  bool _isProcessing = false;
  String _fileName = '';
  int _ordersCount = 0;
  double _totalValue = 0.0;

  void _simulateFilePick() {
    setState(() {
      _fileLoaded = true;
      _fileName = 'شحنات_اليوم_فرع_القاهرة_150_اوردر.xlsx';
      _ordersCount = 142;
      _totalValue = 186400.0;
    });
  }

  void _confirmImport() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 تم استيراد وتوليد $_ordersCount بوليصة شحن جديدة بنجاح!'),
        backgroundColor: AppColors.statusDelivered,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 720,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.table_view, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('استيراد أوردرات وشحنات جماعية من Excel / CSV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.black)),
                        Text('رفع ملف إكسيل يحتوي على مئات الشحنات وتوليد بوالص الباركود دفعة واحدة', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const Divider(height: 24),

            if (!_fileLoaded)
              InkWell(
                onTap: _simulateFilePick,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      const Text('اضغط هنا لاختيار ملف إكسيل (XLSX / CSV)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('يدعم أعمدة: اسم العميل، الهاتف، العنوان، المحافظة، المبلغ المطلوب، كود الصنف', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(_fileName, style: const TextStyle(fontWeight: FontWeight.black, fontSize: 13)),
                        const Spacer(),
                        TextButton(onPressed: _simulateFilePick, child: const Text('تغيير الملف')),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          const Text('إجمالي الأوردرات الجاهزة:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Text('$_ordersCount أوردر', style: const TextStyle(fontWeight: FontWeight.black, fontSize: 15)),
                        ]),
                        Column(children: [
                          const Text('إجمالي قيمة التحصيل كاش:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Text('${_totalValue.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.black, fontSize: 15, color: AppColors.accent)),
                        ]),
                        Column(children: [
                          const Text('حالة الفحص والمطابقة:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const Text('صالح 100% ✓', style: TextStyle(fontWeight: FontWeight.black, fontSize: 13, color: Colors.green)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: !_fileLoaded || _isProcessing ? null : _confirmImport,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  icon: _isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.flash_on, size: 18),
                  label: Text('تأكيد الاستيراد وتوليد $_ordersCount بوليصة', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
