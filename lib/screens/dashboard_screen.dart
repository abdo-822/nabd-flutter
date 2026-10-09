import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import 'campaigns_screen.dart';
import 'donation_screen.dart';
import 'donors_list_screen.dart';
import 'my_requests_screen.dart';
import 'request_blood_screen.dart';

class DashboardScreen extends StatelessWidget {
  final UserModel? user;
  const DashboardScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final currentUser = user ?? auth.currentUserModel;
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final textLightColor = isDark ? AppColors.darkTextLight : AppColors.textLight;

    final cards = [
      {
        'title': 'طلب دم',
        'subtitle': 'نشر نداء تبرع عاجل',
        'icon': Icons.local_hospital_rounded,
        'color': AppColors.primary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestBloodScreen())),
      },
      {
        'title': 'حملات التبرع',
        'subtitle': 'استعراض الحالات النشطة',
        'icon': Icons.volunteer_activism_rounded,
        'color': AppColors.warning,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => CampaignsScreen(user: currentUser))),
      },
      {
        'title': 'طلباتي',
        'subtitle': 'إدارة طلباتك والمستجيبين',
        'icon': Icons.assignment_rounded,
        'color': AppColors.success,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRequestsScreen())),
      },
      {
        'title': 'تبرع بالدم',
        'subtitle': 'حالتك ومعلومات التبرع',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFF1B5E20),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationScreen())),
      },
      {
        'title': 'المتبرعون',
        'subtitle': 'قائمة المتبرعين المتاحين',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF00897B),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonorsListScreen())),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.favorite_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('نبض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AuthService>().signOut();
                      },
                      child: const Text('خروج', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ترحيب
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      (currentUser?.name.isNotEmpty == true ? currentUser!.name[0] : 'م').toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً، ${currentUser?.name.isNotEmpty == true ? currentUser!.name : "مستخدم نبض"}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser?.bloodType.isNotEmpty == true
                              ? 'فصيلة دمك: ${currentUser!.bloodType}'
                              : 'معاً ننقذ حياة في السودان',
                          style: TextStyle(color: textLightColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'الخدمات السريعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final color = card['color'] as Color;
                return InkWell(
                  onTap: card['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(card['icon'] as IconData, color: color, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          card['title'] as String,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card['subtitle'] as String,
                          style: TextStyle(fontSize: 11, color: textLightColor),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
