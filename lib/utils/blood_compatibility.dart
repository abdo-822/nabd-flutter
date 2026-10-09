class DonorAvailability {
  final bool available;
  final String? reason;
  final DateTime? availableFrom;

  const DonorAvailability({
    required this.available,
    this.reason,
    this.availableFrom,
  });
}

class BloodCompatibility {
  static const List<String> bloodTypes = [
    "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"
  ];

  static const List<String> cities = [
    "كوستي", "ربك", "الدويم", "القطينة", "تندلتي", "الجبلين",
    "أم دبيكرات", "أبو حجار", "الحمرة", "السلام", "الطبية", "الخرطوم", "أم درمان", "بحري"
  ];

  static const List<String> sudancities = cities;

  static const Map<String, List<String>> compatibilityMap = {
    "O-": ["O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+"],
    "O+": ["O+", "A+", "B+", "AB+"],
    "A-": ["A-", "A+", "AB-", "AB+"],
    "A+": ["A+", "AB+"],
    "B-": ["B-", "B+", "AB-", "AB+"],
    "B+": ["B+", "AB+"],
    "AB-": ["AB-", "AB+"],
    "AB+": ["AB+"],
  };

  /// هل يستطيع المتبرع التبرع للمريض؟
  static bool canDonateTo(String? donor, String? recipient) {
    if (donor == null || recipient == null || donor.isEmpty || recipient.isEmpty) return false;
    final allowed = compatibilityMap[donor];
    return allowed != null ? allowed.contains(recipient) : donor == recipient;
  }

  /// ما هي فصائل المتبرعين المتوافقة مع هذا المريض؟
  static List<String> getCompatibleDonors(String? recipient) {
    if (recipient == null || recipient.isEmpty) return [];
    return bloodTypes.where((donor) => canDonateTo(donor, recipient)).toList();
  }

  /// ما هي الفصائل التي يستطيع المتبرع التبرع لها؟
  static List<String> compatibleRecipients(String? donor) {
    if (donor == null || donor.isEmpty) return [];
    return compatibilityMap[donor] ?? [donor];
  }

  /// نص توضيحي لمن يستطيع المتبرع مساعدته
  static String compatibleWith(String donor) {
    final all = bloodTypes.where((bt) => canDonateTo(donor, bt)).toList();
    if (all.length == bloodTypes.length) return "يمكنك التبرع للجميع";
    if (all.isEmpty) return "لا يمكنك التبرع لأحد";
    return "يمكنك التبرع لـ: ${all.join(', ')}";
  }

  /// فحص توفر المتبرع (فترة راحة 8 أسابيع = 56 يوماً وحالة النشاط)
  static DonorAvailability isDonorAvailable({
    bool isActive = true,
    dynamic lastDonationDate,
  }) {
    if (lastDonationDate != null) {
      final int lastDonationMs = lastDonationDate is int
          ? lastDonationDate
          : int.tryParse(lastDonationDate.toString()) ?? 0;
      if (lastDonationMs > 0) {
        const int cooldownMs = 56 * 24 * 60 * 60 * 1000;
        final int cooldownEnd = lastDonationMs + cooldownMs;
        final int now = DateTime.now().millisecondsSinceEpoch;
        if (now < cooldownEnd) {
          return DonorAvailability(
            available: false,
            reason: 'تبرع خلال آخر 8 أسابيع',
            availableFrom: DateTime.fromMillisecondsSinceEpoch(cooldownEnd),
          );
        }
      }
    }

    return DonorAvailability(
      available: isActive,
      reason: isActive ? null : 'تم إيقاف التوفر يدوياً',
      availableFrom: null,
    );
  }
}
