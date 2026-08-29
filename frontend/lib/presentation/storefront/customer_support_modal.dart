import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomerSupportModal extends StatefulWidget {
  const CustomerSupportModal({super.key});

  @override
  State<CustomerSupportModal> createState() => _CustomerSupportModalState();
}

class _CustomerSupportModalState extends State<CustomerSupportModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'سارة إبراهيم');
  final _phoneController = TextEditingController(text: '01098765432');
  final _orderNumController = TextEditingController(text: 'ORD-2026-10001');
  final _detailsController = TextEditingController();

  String _ticketType = 'شكوى بخصوص موعد التسليم';
  bool _isSubmitting = false;

  void _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pop();

    final ticketId = 'TKT-2026-${(1000 + (DateTime.now().millisecond % 9000))}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 تم استلام طلبك بنجاح برقم تذكرة ($ticketId)! سيتم التواصل معك خلال ساعتين.'),
        backgroundColor: AppColors.statusDelivered,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
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
                        decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.support_agent, color: Colors.indigo, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تقديم شكوى أو مقترح (خدمة العملاء)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.black)),
                          Text('يسعدنا تلقي استفساراتك ومقترحاتك لتطوير الخدمة', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const Divider(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'اسم العميل بالكامل', prefixIcon: Icon(Icons.person)),
                      validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'رقم الهاتف للتواصل', prefixIcon: Icon(Icons.phone)),
                      validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _ticketType,
                      decoration: const InputDecoration(labelText: 'نوع الطلب'),
                      items: const [
                        DropdownMenuItem(value: 'شكوى بخصوص موعد التسليم', child: Text('شكوى بخصوص موعد التسليم')),
                        DropdownMenuItem(value: 'استفسار عن الشحنة والبوليصة', child: Text('استفسار عن الشحنة والبوليصة')),
                        DropdownMenuItem(value: 'اقتراح لتطوير الخدمة والتطبيق', child: Text('اقتراح لتطوير الخدمة والتطبيق')),
                        DropdownMenuItem(value: 'طلب استرجاع أو استبدال صنف', child: Text('طلب استرجاع أو استبدال صنف')),
                      ],
                      onChanged: (v) => setState(() => _ticketType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _orderNumController,
                      decoration: const InputDecoration(labelText: 'رقم البوليصة (اختياري)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل الشكوى أو المقترح بالتفصيل',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'يرجى كتابة تفاصيل الطلب' : null,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, size: 18),
                    label: const Text('إرسال التذكرة فوراً', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
