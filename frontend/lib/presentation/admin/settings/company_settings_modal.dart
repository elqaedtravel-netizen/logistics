import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class CompanySettingsModal extends ConsumerStatefulWidget {
  const CompanySettingsModal({super.key});

  @override
  ConsumerState<CompanySettingsModal> createState() => _CompanySettingsModalState();
}

class _CompanySettingsModalState extends ConsumerState<CompanySettingsModal> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController(text: 'شركة أنتيجرافيتي إكسبريس للخدمات اللوجستية والشحن ش.م.م');
  final _instapayController = TextEditingController(text: 'antigravity.logistics@instapay');
  final _vodafoneController = TextEditingController(text: '01012345678');
  final _orangeController = TextEditingController(text: '01212345678');
  final _etisalatController = TextEditingController(text: '01112345678');
  final _wePayController = TextEditingController(text: '01512345678');
  
  final _bankNameController = TextEditingController(text: 'البنك التجاري الدولي (CIB مصر)');
  final _accountHolderController = TextEditingController(text: 'شركة أنتيجرافيتي إكسبريس ش.م.م');
  final _accountNumberController = TextEditingController(text: '100045892019');
  final _ibanController = TextEditingController(text: 'EG380010004589201900000000000');
  final _swiftController = TextEditingController(text: 'CIBEEGCX');

  bool _isSaving = false;

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await Future.delayed(const Duration(milliseconds: 600)); // محاكاة الحفظ

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم حفظ بيانات الدفع الرسمية للشركة وتحديثها للعملاء والمناديب فوراً!'),
        backgroundColor: AppColors.statusDelivered,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 760,
        height: 640,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الهيدر
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إعدادات بيانات الدفع والحسابات البنكية الرسمية للشركة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.black)),
                          Text('تظهر هذه البيانات إلزامياً للعملاء أثناء الدفع الإلكتروني وللمناديب عند توريد العهدة', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const Divider(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. عنوان إنستاباي والمحافظ
                      const Text('١. تطبيق إنستاباي (InstaPay) والمحافظ الإلكترونية:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 13)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _instapayController,
                        decoration: const InputDecoration(labelText: 'عنوان إنستاباي الرسمي للشركة (InstaPay Address / IPA)', prefixIcon: Icon(Icons.alternate_email)),
                        validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _vodafoneController,
                              decoration: const InputDecoration(labelText: 'محفظة فودافون كاش', prefixIcon: Icon(Icons.phone_android)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _orangeController,
                              decoration: const InputDecoration(labelText: 'محفظة أورنج كاش', prefixIcon: Icon(Icons.phone_android)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _etisalatController,
                              decoration: const InputDecoration(labelText: 'محفظة اتصالات كاش', prefixIcon: Icon(Icons.phone_android)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _wePayController,
                              decoration: const InputDecoration(labelText: 'محفظة وي باي (WE Pay)', prefixIcon: Icon(Icons.phone_android)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. الحساب البنكي الرسمي والآيبان
                      const Text('٢. الحساب البنكي الرسمي والآيبان (IBAN):', style: TextStyle(fontWeight: FontWeight.black, fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _bankNameController,
                              decoration: const InputDecoration(labelText: 'اسم البنك', prefixIcon: Icon(Icons.account_balance)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _accountHolderController,
                              decoration: const InputDecoration(labelText: 'اسم صاحب الحساب بالبنك'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ibanController,
                        decoration: const InputDecoration(labelText: 'رقم الآيبان البنكي الدولي (IBAN)', prefixIcon: Icon(Icons.numbers)),
                        validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _accountNumberController,
                              decoration: const InputDecoration(labelText: 'رقم الحساب البنكي الداخلي'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _swiftController,
                              decoration: const InputDecoration(labelText: 'رمز السويفت (SWIFT Code)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, size: 18),
                    label: const Text('حفظ ونشر بيانات الدفع', style: TextStyle(fontWeight: FontWeight.bold)),
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
