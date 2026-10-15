import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/request_model.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../utils/blood_compatibility.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _dataService = DataService();
  bool _isResponding = false;

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الهاتف')),
      );
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    // Sanitize phone number (remove spaces, symbols)
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('whatsapp://send?phone=$cleanPhone');
    final webUri = Uri.parse('https://wa.me/$cleanPhone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تطبيق واتساب غير مثبت على الجهاز')),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الرقم إلى الحافظة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleAccept(RequestModel request) async {
    final auth = context.read<AuthService>();
    final user = auth.currentUserModel;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
      );
      return;
    }

    if (user.bloodType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديث ملفك الشخصي وإضافة فصيلة دمك أولاً'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }

    if (!BloodCompatibility.canDonateTo(user.bloodType, request.bloodType)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('فصيلة غير متوافقة طبياً', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'فصيلة دمك (${user.bloodType}) لا تتوافق طبياً مع فصيلة المريض (${request.bloodType}).\nحفاظاً على سلامة المريض، يمكن فقط للفصائل المتوافقة الاستجابة.',
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الاستجابة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل توافق على التبرع بالدم لهذا المريض (${request.bloodType})؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، أوافق', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isResponding = true);

    try {
      await _dataService.acceptBloodRequestWithCooldown(
        requestId: widget.requestId,
        donorId: user.uid,
        donorInfo: {
          'bloodType': user.bloodType,
          'phone': user.phone,
          'city': user.location,
        },
      );

      // Refresh auth user state to reflect donation increment & cooldown date
      await auth.reloadUserData();

      if (!mounted) return;

      // إظهار Snackbar بنجاح التبرع
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('❤️ تم التبرع بنجاح! جزاك الله خيراً', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('جزاك الله خيراً', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('تم تسجيل استجابتك بنجاح. يمكنك الآن الاتصال بطالب الدم للتنسيق.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (request.phone.isNotEmpty) _makeCall(request.phone);
              },
              child: const Text('الاتصال بالطالب الآن'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تنبيه', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final currentUser = auth.currentUserModel;
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final textLightColor = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<RequestModel?>(
        stream: _dataService.listenToRequest(widget.requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final request = snapshot.data;
          if (request == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: textLightColor),
                  const SizedBox(height: 12),
                  Text('الطلب غير موجود أو تم حذفه', style: TextStyle(fontSize: 16, color: textColor)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('رجوع'),
                  ),
                ],
              ),
            );
          }

          final isOwner = currentUser?.uid == request.createdBy;
          final isActive = request.status == 'active';
          final canAccept = isActive && !isOwner;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // بطاقة الفصيلة والحالة
                Card(
                  color: cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.water_drop, color: AppColors.primary, size: 36),
                                const SizedBox(width: 8),
                                Text(
                                  request.bloodType,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            _buildStatusBadge(request.status),
                          ],
                        ),
                        Divider(color: dividerColor, height: 28),

                        if (request.location != null && request.location!.isNotEmpty) ...[
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            title: 'المدينة',
                            value: request.location!,
                            textColor: textColor,
                            textLightColor: textLightColor,
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (request.units != null) ...[
                          _buildDetailRow(
                            icon: Icons.bloodtype_outlined,
                            title: 'عدد الأكياس المطلوبة',
                            value: '${request.units} أكياس',
                            textColor: textColor,
                            textLightColor: textLightColor,
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (request.code.isNotEmpty) ...[
                          _buildDetailRow(
                            icon: Icons.tag,
                            title: 'كود الطلب / الغرفة',
                            value: request.code,
                            textColor: textColor,
                            textLightColor: textLightColor,
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (request.message != null && request.message!.isNotEmpty) ...[
                          _buildDetailRow(
                            icon: Icons.chat_bubble_outline,
                            title: 'رسالة الطالب',
                            value: request.message!,
                            textColor: textColor,
                            textLightColor: textLightColor,
                          ),
                          const SizedBox(height: 12),
                        ],

                        _buildDetailRow(
                          icon: Icons.phone_outlined,
                          title: 'رقم الهاتف',
                          value: request.phone,
                          textColor: textColor,
                          textLightColor: textLightColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقة الاتصال والتواصل
                if (request.phone.isNotEmpty)
                  Card(
                    color: cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOwner ? 'بيانات التواصل مع طلبك' : 'التواصل المباشر مع صاحب الطلب',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.phone, size: 20),
                                  label: const Text('اتصال'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => _makeCall(request.phone),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.message, size: 20),
                                  label: const Text('واتساب'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => _openWhatsApp(request.phone),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy_outlined),
                                tooltip: 'نسخ الرقم',
                                style: IconButton.styleFrom(
                                  backgroundColor: inputBgColor(isDark),
                                ),
                                onPressed: () => _copyToClipboard(request.phone),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // قائمة المستجيبين (تظهر لصاحب الطلب فقط)
                if (isOwner && request.responders.isNotEmpty) ...[
                  Card(
                    color: cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.volunteer_activism, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'المستجيبون للطلب (${request.responders.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...request.responders.map((r) {
                            final rPhone = r['phone']?.toString() ?? '';
                            final rBlood = r['bloodType']?.toString() ?? '';
                            final rCity = r['city']?.toString() ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: inputBgColor(isDark),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    child: Text(
                                      rBlood,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'متبرع فصيلة: $rBlood',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        if (rCity.isNotEmpty)
                                          Text(
                                            rCity,
                                            style: TextStyle(fontSize: 12, color: textLightColor),
                                          ),
                                        Text(
                                          rPhone,
                                          style: TextStyle(fontSize: 13, color: textLightColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (rPhone.isNotEmpty) ...[
                                    IconButton(
                                      icon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                                      onPressed: () => _makeCall(rPhone),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.message, color: Color(0xFF25D366), size: 20),
                                      onPressed: () => _openWhatsApp(rPhone),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // زر استجابة للطلب (يظهر للمستخدمين الآخرين إذا كان الطلب نشطاً)
                if (canAccept)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.favorite, color: Colors.white),
                      label: _isResponding
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'استجابة للطلب والتبرع',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 3,
                      ),
                      onPressed: _isResponding ? null : () => _handleAccept(request),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Color inputBgColor(bool isDark) => isDark ? AppColors.darkInput : AppColors.input;

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color textLightColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: textLightColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: textLightColor)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String label;

    switch (status) {
      case 'active':
        badgeColor = AppColors.success;
        label = 'نشط';
        break;
      case 'fulfilled':
        badgeColor = AppColors.primary;
        label = 'مكتمل';
        break;
      case 'expired':
        badgeColor = AppColors.critical;
        label = 'منتهي';
        break;
      default:
        badgeColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
