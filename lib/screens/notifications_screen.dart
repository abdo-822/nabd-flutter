import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import 'request_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _firestore = FirebaseFirestore.instance;

  String _getDateLabel(dynamic dateVal) {
    if (dateVal == null) return 'سابقاً';
    DateTime date;
    if (dateVal is Timestamp) {
      date = dateVal.toDate();
    } else if (dateVal is int) {
      date = DateTime.fromMillisecondsSinceEpoch(dateVal);
    } else {
      date = DateTime.tryParse(dateVal.toString()) ?? DateTime.now();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    if (date.isAfter(today)) return 'اليوم';
    if (date.isAfter(yesterday)) return 'أمس';
    if (date.isAfter(weekAgo)) return 'هذا الأسبوع';
    return 'سابقاً';
  }

  Future<void> _markAsRead(String uid, List<dynamic> allNotifications, String notifId) async {
    final updated = allNotifications.map((n) {
      final map = Map<String, dynamic>.from(n as Map);
      if (map['id'] == notifId) map['read'] = true;
      return map;
    }).toList();

    await _firestore.collection('users').doc(uid).update({'notifications': updated});
  }

  Future<void> _markAllAsRead(String uid, List<dynamic> allNotifications) async {
    final updated = allNotifications.map((n) {
      final map = Map<String, dynamic>.from(n as Map);
      map['read'] = true;
      return map;
    }).toList();

    await _firestore.collection('users').doc(uid).update({'notifications': updated});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديد جميع الإشعارات كمقروءة')),
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

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الإشعارات')),
        body: const Center(child: Text('يرجى تسجيل الدخول لعرض الإشعارات')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final rawList = data?['notifications'] as List<dynamic>? ?? [];

          if (rawList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_outlined, size: 72, color: textLightColor),
                    const SizedBox(height: 16),
                    Text('لا توجد إشعارات حالياً', style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('ستصلك إشعارات فورية عند نشر طلبات دم تتوافق معك أو استجابة أحد لطلباتك', style: TextStyle(color: textLightColor, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          // Sort notifications descending
          final sortedList = List<Map<String, dynamic>>.from(
            rawList.map((e) => Map<String, dynamic>.from(e as Map)),
          )..sort((a, b) {
              final aTime = a['createdAt']?.toString() ?? '';
              final bTime = b['createdAt']?.toString() ?? '';
              return bTime.compareTo(aTime);
            });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإشعارات (${sortedList.length})', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    TextButton.icon(
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('تحديد الكل كمقروء'),
                      onPressed: () => _markAllAsRead(user.uid, rawList),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) {
                    final item = sortedList[index];
                    final isRead = item['read'] == true;
                    final type = item['type']?.toString() ?? '';
                    final notifId = item['id']?.toString() ?? '';
                    final requestId = item['requestId']?.toString();

                    IconData iconData = Icons.notifications;
                    Color iconColor = AppColors.primary;

                    if (type == 'new_request') {
                      iconData = Icons.water_drop;
                      iconColor = AppColors.critical;
                    } else if (type == 'request_accepted') {
                      iconData = Icons.handshake;
                      iconColor = AppColors.success;
                    } else if (type == 'system') {
                      iconData = Icons.info_outline;
                      iconColor = Colors.orange;
                    }

                    return Card(
                      color: cardColor,
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: !isRead
                            ? const BorderSide(color: AppColors.primary, width: 1.5)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.15),
                          child: Icon(iconData, color: iconColor, size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['title']?.toString() ?? 'إشعار جديد',
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  color: textColor,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item['body']?.toString() ?? '',
                              style: TextStyle(color: textLightColor, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getDateLabel(item['createdAt']),
                                  style: TextStyle(color: textLightColor, fontSize: 11),
                                ),
                                if (requestId != null && requestId.isNotEmpty)
                                  const Text(
                                    'عرض التفاصيل >',
                                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (!isRead && notifId.isNotEmpty) {
                            await _markAsRead(user.uid, rawList, notifId);
                          }
                          if (requestId != null && requestId.isNotEmpty && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RequestDetailScreen(requestId: requestId),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
