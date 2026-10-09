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

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _dataService = DataService();

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('whatsapp://send?phone=$cleanPhone');
    final webUri = Uri.parse('https://wa.me/$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الرقم'), duration: Duration(seconds: 1)),
    );
  }

  void _showDeleteDialog(String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا الطلب نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _dataService.deleteBloodRequest(requestId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الطلب بنجاح')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppColors.critical),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(RequestModel request) {
    String selectedBlood = request.bloodType;
    final unitsCtrl = TextEditingController(text: request.units?.toString() ?? '');
    final cityCtrl = TextEditingController(text: request.location ?? '');
    final phoneCtrl = TextEditingController(text: request.phone);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
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
                      Text('تعديل الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('فصيلة الدم:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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
                          if (val) setSheetState(() => selectedBlood = t);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('عدد الأكياس:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: unitsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('المدينة:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: cityCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('رقم الهاتف:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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
                        if (phoneCtrl.text.trim().isEmpty) return;
                        setSheetState(() => isSaving = true);
                        try {
                          final updateData = <String, dynamic>{
                            'bloodType': selectedBlood,
                            'phone': phoneCtrl.text.trim(),
                          };
                          final units = int.tryParse(unitsCtrl.text.trim());
                          if (units != null) updateData['units'] = units;
                          if (cityCtrl.text.trim().isNotEmpty) updateData['location'] = cityCtrl.text.trim();

                          await _dataService.updateBloodRequest(request.id, updateData);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تحديث الطلب بنجاح'), backgroundColor: AppColors.success),
                          );
                        } catch (e) {
                          setSheetState(() => isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUserModel;
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final textLightColor = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي الخاصة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('يرجى تسجيل الدخول'))
          : StreamBuilder<List<RequestModel>>(
              stream: _dataService.listenToUserRequests(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 72, color: textLightColor),
                          const SizedBox(height: 16),
                          Text('لا توجد طلبات دم خاصة بك حالياً', style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('يمكنك إنشاء طلب دم جديد وسيظهر هنا مع المستجيبين له', style: TextStyle(color: textLightColor, fontSize: 14), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Card(
                      color: cardColor,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // رأس البطاقة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.15),
                                      child: Text(
                                        req.bloodType,
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('فصيلة: ${req.bloodType}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                        if (req.location != null)
                                          Text(req.location!, style: TextStyle(fontSize: 12, color: textLightColor)),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                      tooltip: 'تعديل',
                                      onPressed: () => _showEditSheet(req),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.critical),
                                      tooltip: 'حذف',
                                      onPressed: () => _showDeleteDialog(req.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (req.units != null)
                              Text('الأكياس المطلوبة: ${req.units}', style: TextStyle(color: textLightColor, fontSize: 13)),
                            if (req.code.isNotEmpty)
                              Text('كود الطلب: ${req.code}', style: TextStyle(color: textLightColor, fontSize: 13)),
                            Text('رقم الهاتف: ${req.phone}', style: TextStyle(color: textLightColor, fontSize: 13)),

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // المستجيبون
                            Row(
                              children: [
                                const Icon(Icons.people_outline, size: 18, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'المستجيبون (${req.responders.length})',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (req.responders.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text('لا يوجد مستجيبون لهذا الطلب حتى الآن', style: TextStyle(color: textLightColor, fontSize: 12)),
                              )
                            else
                              ...req.responders.map((r) {
                                final rPhone = r['phone']?.toString() ?? '';
                                final rBlood = r['bloodType']?.toString() ?? '';
                                final rCity = r['city']?.toString() ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.darkInput : AppColors.input),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primary.withOpacity(0.2),
                                        child: Text(rBlood, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(rPhone, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                            if (rCity.isNotEmpty)
                                              Text(rCity, style: TextStyle(fontSize: 11, color: textLightColor)),
                                          ],
                                        ),
                                      ),
                                      if (rPhone.isNotEmpty) ...[
                                        IconButton(
                                          icon: const Icon(Icons.phone, size: 18, color: AppColors.primary),
                                          onPressed: () => _makeCall(rPhone),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.message, size: 18, color: Color(0xFF25D366)),
                                          onPressed: () => _openWhatsApp(rPhone),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                                          onPressed: () => _copyPhone(rPhone),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
