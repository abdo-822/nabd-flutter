import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../utils/blood_compatibility.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _dataService = DataService();
  bool _isToggling = false;

  Future<void> _handleToggle(bool val) async {
    final auth = context.read<AuthService>();
    final user = auth.currentUserModel;
    if (user == null) return;

    final avail = BloodCompatibility.isDonorAvailable(
      isActive: user.isActive,
      lastDonationDate: user.lastDonationDate,
    );

    if (val && !avail.available && avail.availableFrom != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('غير متاح للتبرع حالياً', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'لا يمكن تفعيل التوفر الآن لأنك تبرعت بالدم خلال آخر 8 أسابيع.\n'
            'ستصبح متاحاً تلقائياً في تاريخ: ${avail.availableFrom!.year}-${avail.availableFrom!.month}-${avail.availableFrom!.day}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isToggling = true);
    try {
      await _dataService.setDonorActive(user.uid, val);
      await auth.reloadUserData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppColors.critical),
      );
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUserModel;
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final textLightColor = isDark ? AppColors.darkTextLight : AppColors.textLight;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('حالة التبرع')),
        body: const Center(child: Text('يرجى تسجيل الدخول لعرض حالة التبرع')),
      );
    }

    final avail = BloodCompatibility.isDonorAvailable(
      isActive: user.isActive,
      lastDonationDate: user.lastDonationDate,
    );
    final within8Weeks = !avail.available && avail.availableFrom != null;
    final recipients = BloodCompatibility.compatibleRecipients(user.bloodType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حالة التبرع', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // بطاقة الحالة العامة
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (avail.available ? AppColors.success : AppColors.critical).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        avail.available ? Icons.check_circle : Icons.access_time_filled,
                        size: 56,
                        color: avail.available ? AppColors.success : AppColors.critical,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      avail.available ? 'متاح للتبرع بالدم' : 'غير متاح للتبرع حالياً',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: avail.available ? AppColors.success : AppColors.critical,
                      ),
                    ),
                    if (!avail.available && avail.reason != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        avail.reason!,
                        style: TextStyle(color: textLightColor, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (within8Weeks) ...[
                      const SizedBox(height: 6),
                      Text(
                        'تاريخ التوفر القادم: ${avail.availableFrom!.year}-${avail.availableFrom!.month}-${avail.availableFrom!.day}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // بطاقة تفعيل / تعطيل التوفر
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تلقي طلبات التبرع العاجلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                          const SizedBox(height: 4),
                          Text(
                            within8Weeks
                                ? 'التوفر معطل تلقائياً (فترة راحة 8 أسابيع)'
                                : (user.isActive ? 'حسابك ظاهر للمحتاجين في مدينتك' : 'حسابك مخفي حالياً عن طلبات التبرع'),
                            style: TextStyle(fontSize: 12, color: textLightColor),
                          ),
                        ],
                      ),
                    ),
                    if (_isToggling)
                      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Switch(
                        value: within8Weeks ? false : user.isActive,
                        activeColor: AppColors.primary,
                        onChanged: within8Weeks ? null : _handleToggle,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // بطاقة بيانات التبرع
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('معلومات المتبرع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    const SizedBox(height: 14),
                    _buildInfoRow(
                      icon: Icons.water_drop,
                      title: 'فصيلة دمك:',
                      value: user.bloodType.isNotEmpty ? user.bloodType : 'غير محددة',
                      textColor: textColor,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      icon: Icons.favorite,
                      title: 'عدد مرات التبرع:',
                      value: '${user.donations} مرة',
                      textColor: textColor,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      icon: Icons.history,
                      title: 'آخر تبرع مسجل:',
                      value: user.lastDonationDate != null
                          ? DateTime.fromMillisecondsSinceEpoch(user.lastDonationDate!).toString().split(' ')[0]
                          : 'لم يتم تسجيل تبرع سابق',
                      textColor: textColor,
                    ),
                    if (recipients.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('الفصائل التي يمكنك إنقاذها بدمك:', style: TextStyle(fontSize: 13, color: textLightColor)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: recipients.map((r) => Chip(
                          label: Text(r, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                          backgroundColor: AppColors.primary,
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // إرشادات التبرع بالدم
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('شروط وإرشادات التبرع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTip('يجب أن تكون الفترة بين التبرعين 8 أسابيع (56 يوماً) على الأقل.'),
                    _buildTip('شرب كمية وفيرة من السوائل وتناول وجبة خفيفة قبل التبرع.'),
                    _buildTip('تجنب الأنشطة البدنية الشاقة بعد التبرع لعدة ساعات.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
