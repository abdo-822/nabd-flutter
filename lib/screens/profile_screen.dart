import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../utils/blood_compatibility.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _dataService = DataService();

  void _showEditProfileDialog() {
    final auth = context.read<AuthService>();
    final user = auth.currentUserModel;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    String selectedBlood = user.bloodType.isNotEmpty ? user.bloodType : BloodCompatibility.bloodTypes.first;
    String selectedCity = user.location.isNotEmpty ? user.location : BloodCompatibility.sudancities.first;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = context.watch<ThemeProvider>().isDark;
          final cardColor = isDark ? AppColors.darkCard : AppColors.card;
          final inputBg = isDark ? AppColors.darkInput : AppColors.input;
          final textColor = isDark ? AppColors.darkText : AppColors.text;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('تعديل الملف الشخصي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text('الاسم الكامل', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('فصيلة الدم', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: BloodCompatibility.bloodTypes.map((t) {
                      final isSelected = selectedBlood == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: cardColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedBlood = t);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Text('المدينة', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: BloodCompatibility.sudancities.contains(selectedCity) ? selectedCity : BloodCompatibility.sudancities.first,
                    items: BloodCompatibility.sudancities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCity = val);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: isSaving ? null : () async {
                        setModalState(() => isSaving = true);
                        try {
                          await _dataService.updateUserProfile(user.uid, {
                            'name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'bloodType': selectedBlood,
                            'location': selectedCity,
                          });
                          await auth.reloadUserData();
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تحديث البيانات بنجاح'), backgroundColor: AppColors.success),
                          );
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppColors.critical),
                          );
                        }
                      },
                      child: isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthService>().signOut();
            },
            child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

    final initialLetter = (user?.name.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : (user?.email.isNotEmpty == true ? user!.email[0].toUpperCase() : 'ن');

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل الملف',
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // بطاقة المستخدم الرئيسية
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        initialLetter,
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.name.isNotEmpty == true ? user!.name : 'مستخدم منصة نبض',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(fontSize: 13, color: textLightColor),
                    ),
                    const SizedBox(height: 20),

                    // شبكة المعلومات المصغرة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBox(
                          icon: Icons.water_drop,
                          label: 'الفصيلة',
                          value: user?.bloodType.isNotEmpty == true ? user!.bloodType : '—',
                          color: AppColors.primary,
                          textColor: textColor,
                          textLightColor: textLightColor,
                        ),
                        _buildStatBox(
                          icon: Icons.location_on,
                          label: 'المدينة',
                          value: user?.location.isNotEmpty == true ? user!.location : '—',
                          color: Colors.orange,
                          textColor: textColor,
                          textLightColor: textLightColor,
                        ),
                        _buildStatBox(
                          icon: Icons.favorite,
                          label: 'التبرعات',
                          value: '${user?.donations ?? 0}',
                          color: AppColors.success,
                          textColor: textColor,
                          textLightColor: textLightColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // خيارات وإعدادات التطبيق
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  // المظهر الداكن
                  SwitchListTile(
                    secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary),
                    title: Text('المظهر الداكن (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('تبديل بين الوضع الليلي والنهاري', style: TextStyle(fontSize: 12, color: textLightColor)),
                    value: isDark,
                    activeColor: AppColors.primary,
                    onChanged: (val) => theme.toggleTheme(),
                  ),
                  const Divider(height: 1),

                  // رقم الهاتف
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    title: Text('رقم الهاتف للتواصل', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text(user?.phone.isNotEmpty == true ? user!.phone : 'غير محدد', style: TextStyle(color: textLightColor)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onPressed: _showEditProfileDialog,
                  ),
                  const Divider(height: 1),

                  // تعديل الملف
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.primary),
                    title: Text('تعديل البيانات الشخصية', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onPressed: _showEditProfileDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // زر تسجيل الخروج
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.critical),
                title: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.critical)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.critical),
                onTap: _showLogoutDialog,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color textLightColor,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
        Text(label, style: TextStyle(fontSize: 11, color: textLightColor)),
      ],
    );
  }
}
