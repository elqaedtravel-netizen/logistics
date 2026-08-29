import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

class CreateAdminUserModal extends StatefulWidget {
  const CreateAdminUserModal({super.key});

  @override
  State<CreateAdminUserModal> createState() => _CreateAdminUserModalState();
}

class _CreateAdminUserModalState extends State<CreateAdminUserModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Password@123');
  final _nationalIdController = TextEditingController();
  final _licenseController = TextEditingController();

  String _selectedRole = 'HubManager'; // HubManager, FinanceAdmin, OperationsAdmin, Driver, MerchantAdmin
  String _vehicleType = 'موتوسيكل';
  double _commission = 10.0;

  final Map<String, bool> _permissions = {
    'orders.create': true,
    'orders.dispatch': true,
    'finance.settle': false,
    'inventory.manage': true,
    'users.manage': false,
    'settings.edit': false,
  };

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'SuperAdmin') {
        _permissions.updateAll((key, val) => true);
      } else if (role == 'HubManager') {
        _permissions['orders.create'] = true;
        _permissions['orders.dispatch'] = true;
        _permissions['inventory.manage'] = true;
        _permissions['finance.settle'] = false;
        _permissions['users.manage'] = false;
        _permissions['settings.edit'] = false;
      } else if (role == 'FinanceAdmin') {
        _permissions['finance.settle'] = true;
        _permissions['settings.edit'] = true;
        _permissions['orders.create'] = false;
        _permissions['orders.dispatch'] = false;
        _permissions['inventory.manage'] = false;
        _permissions['users.manage'] = false;
      } else if (role == 'OperationsAdmin') {
        _permissions['orders.dispatch'] = true;
        _permissions['orders.create'] = true;
        _permissions['inventory.manage'] = false;
        _permissions['finance.settle'] = false;
      }
    });
  }

  void _submitUser() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم تسجيل ${_nameController.text.trim()} كـ ($_selectedRole) وتفعيل صلاحياته بنجاح!'),
        backgroundColor: AppColors.statusDelivered,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 780,
        height: 660,
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
                        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.person_add_alt_1, color: AppColors.accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تسجيل مدير / مندوب جديد وتحديد الصلاحيات (RBAC)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.black)),
                          Text('إضافة حسابات المديرين والمناديب مع تعيين الصلاحيات المخصصة لكل دور', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                      // 1. البيانات الأساسية والدور
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'الاسم بالكامل', prefixIcon: Icon(Icons.person)),
                              validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(labelText: 'الدور الوظيفي', prefixIcon: Icon(Icons.badge)),
                              items: const [
                                DropdownMenuItem(value: 'HubManager', child: Text('مدير فرع ومستودع')),
                                DropdownMenuItem(value: 'FinanceAdmin', child: Text('مسؤول مالي وخزينة')),
                                DropdownMenuItem(value: 'OperationsAdmin', child: Text('مسؤول عمليات وتوزيع')),
                                DropdownMenuItem(value: 'Driver', child: Text('مندوب توصيل')),
                                DropdownMenuItem(value: 'MerchantAdmin', child: Text('حساب تاجر متعاقد')),
                                DropdownMenuItem(value: 'SuperAdmin', child: Text('مدير عام (كافة الصلاحيات)')),
                              ],
                              onChanged: (v) {
                                if (v != null) _onRoleChanged(v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(labelText: 'البريد الإلكتروني للدخول', prefixIcon: Icon(Icons.email)),
                              validator: (v) => v?.contains('@') != true ? 'أدخل بريد إلكتروني صحيح' : null,
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
                      const SizedBox(height: 16),

                      // 2. إذا كان الدور مندوب: بيانات المركبة والرخصة
                      if (_selectedRole == 'Driver') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('بيانات مندوب التوصيل والعهدة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nationalIdController,
                                      decoration: const InputDecoration(labelText: 'الرقم القومي (١٤ رقم)'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _licenseController,
                                      decoration: const InputDecoration(labelText: 'رقم رخصة القيادة'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _vehicleType,
                                      decoration: const InputDecoration(labelText: 'نوع المركبة'),
                                      items: const [
                                        DropdownMenuItem(value: 'موتوسيكل', child: Text('موتوسيكل')),
                                        DropdownMenuItem(value: 'سيارة', child: Text('سيارة')),
                                        DropdownMenuItem(value: 'فان بضائع', child: Text('فان بضائع')),
                                        DropdownMenuItem(value: 'تروسيكل', child: Text('تروسيكل')),
                                      ],
                                      onChanged: (v) => setState(() => _vehicleType = v!),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 3. الصلاحيات المخصصة
                      const Text('تخصيص وتحديد الصلاحيات الدقيقة (Granular Permissions):', style: TextStyle(fontWeight: FontWeight.black, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              dense: true,
                              value: _permissions['orders.create'],
                              title: const Text('إنشاء وتعديل أذونات الشحن وبوالص التوزيع', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: const Text('السماح بإدخال بيانات الشحنات وتوليد بوالص الباركود', style: TextStyle(fontSize: 10)),
                              onChanged: (v) => setState(() => _permissions['orders.create'] = v!),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _permissions['orders.dispatch'],
                              title: const Text('إسناد وتوزيع الشحنات على خطوط سير المناديب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: const Text('تخصيص الأوردرات وتعيين المناديب لكل منطقة', style: TextStyle(fontSize: 10)),
                              onChanged: (v) => setState(() => _permissions['orders.dispatch'] = v!),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _permissions['finance.settle'],
                              title: const Text('تصفية العهد النقدية وإدارة الخزينة والعمولات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: const Text('تسجيل استلام الكاش من المناديب وتحويل مستحقات التجار', style: TextStyle(fontSize: 10)),
                              onChanged: (v) => setState(() => _permissions['finance.settle'] = v!),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _permissions['inventory.manage'],
                              title: const Text('إدارة المخازن والأرصدة وطباعة باركود الأصناف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: const Text('تسجيل الوارد والصادر والجرد بالمستودعات', style: TextStyle(fontSize: 10)),
                              onChanged: (v) => setState(() => _permissions['inventory.manage'] = v!),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _permissions['settings.edit'],
                              title: const Text('تعديل بيانات الدفع والحسابات البنكية الرسمية للشركة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: const Text('تحديث أرقام إنستاباي والمحافظ الإلكترونية والآيبان', style: TextStyle(fontSize: 10)),
                              onChanged: (v) => setState(() => _permissions['settings.edit'] = v!),
                            ),
                          ],
                        ),
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
                    onPressed: _submitUser,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('تأكيد تسجيل الحساب والصلاحيات', style: TextStyle(fontWeight: FontWeight.bold)),
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
