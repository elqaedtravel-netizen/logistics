class AppConstants {
  static const String appName = 'أنتيجرافيتي للشحن واللوجستيات';
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';

  // Order Lifecycle Statuses in Egyptian Logistics Terminology
  static const Map<String, String> orderStatusArabic = {
    'Pending': 'قيد الانتظار',
    'In_Warehouse': 'في المخزن',
    'Dispatched_to_Driver': 'مع المندوب',
    'Delivered': 'تم التسليم',
    'Postponed': 'مؤجل',
    'Canceled': 'ملغي',
    'Returned': 'مرتجع للمخزن',
  };

  // Postponement Reasons in Egyptian Arabic
  static const List<Map<String, String>> postponementReasons = [
    {
      'code': 'CUSTOMER_UNREACHABLE',
      'label': 'العميل لا يجيب / الهاتف مغلق',
    },
    {
      'code': 'CUSTOMER_REQUESTED_RESCHEDULE',
      'label': 'طلب العميل تأجيل موعد الاستلام',
    },
    {
      'code': 'CUSTOMER_REFUSED_DELIVERY_TEMPORARILY',
      'label': 'العميل غير متواجد بالعنوان مؤقتاً',
    },
    {
      'code': 'INCORRECT_ADDRESS',
      'label': 'عنوان التوصيل غير دقيق أو ناقص',
    },
    {
      'code': 'OUT_OF_ROUTE_TIME',
      'label': 'انتهاء وقت خط السير اليومي',
    },
    {
      'code': 'WEATHER_OR_ROAD_BLOCKAGE',
      'label': 'ظروف جوية أو إغلاق طرق',
    },
    {
      'code': 'CASH_NOT_AVAILABLE',
      'label': 'المبلغ النقدي غير متوفر مع العميل حالياً',
    },
    {
      'code': 'OTHER',
      'label': 'سبب تشغيلي آخر',
    },
  ];

  // Egyptian Localized Payment Methods
  static const String paymentCod = 'CASH_ON_DELIVERY';
  static const String paymentPaymobCard = 'PAYMOB_CARD';
  static const String paymentPaymobWallet = 'PAYMOB_WALLET';
  static const String paymentPaymobMeeza = 'PAYMOB_MEEZA';

  static const Map<String, String> paymentMethodArabic = {
    'CASH_ON_DELIVERY': 'دفع عند الاستلام (كاش)',
    'PAYMOB_CARD': 'فيزا / ماستركارد (باي موب)',
    'PAYMOB_MEEZA': 'بطاقة ميزة الوطنية',
    'PAYMOB_WALLET': 'محفظة إلكترونية (فودافون كاش / إنستاباي)',
  };
}
