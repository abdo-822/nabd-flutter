import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../utils/blood_compatibility.dart';
import 'request_detail_screen.dart';

class CampaignsScreen extends StatefulWidget {
  final UserModel? user;
  const CampaignsScreen({super.key, this.user});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final _dataService = DataService();
  final _searchController = TextEditingController();
  bool _onlyCompatible = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _onlyCompatible = widget.user?.bloodType.isNotEmpty == true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userBlood = widget.user?.bloodType;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المتبرعون'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالفصيلة، المدينة أو الرسالة...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                if (userBlood != null && userBlood.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilterChip(
                        label: Text('متوافقة معي ($userBlood)'),
                        selected: _onlyCompatible,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: _onlyCompatible ? Colors.white : null),
                        onSelected: (val) => setState(() => _onlyCompatible = true),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('جميع الطلبات'),
                        selected: !_onlyCompatible,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: !_onlyCompatible ? Colors.white : null),
                        onSelected: (val) => setState(() => _onlyCompatible = false),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: _dataService.listenToActiveRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ في تحميل الطلبات: ${snapshot.error}'));
                }

                final allRequests = snapshot.data ?? [];
                final filtered = allRequests.where((req) {
                  if (_onlyCompatible && userBlood != null && userBlood.isNotEmpty) {
                    if (!BloodCompatibility.canDonateTo(userBlood, req.bloodType)) {
                      return false;
                    }
                  }
                  if (_searchQuery.isNotEmpty) {
                    final blood = req.bloodType.toLowerCase();
                    final loc = (req.location ?? '').toLowerCase();
                    final msg = (req.message ?? '').toLowerCase();
                    if (!blood.contains(_searchQuery) &&
                        !loc.contains(_searchQuery) &&
                        !msg.contains(_searchQuery)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          _onlyCompatible
                              ? 'لا توجد طلبات متوافقة مع فصيلتك حالياً'
                              : 'لا توجد طلبات تبرع نشطة حالياً',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestDetailScreen(requestId: item.id),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 28),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.bloodType,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'نشط',
                                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              if (item.location != null && item.location!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text('المدينة: ${item.location}', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (item.units != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.bloodtype_outlined, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text('الأكياس المطلوبة: ${item.units}', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (item.message != null && item.message!.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.message_outlined, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.message!,
                                        style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('اضغط لعرض التفاصيل والتواصل ←',
                                    style: TextStyle(color: AppColors.primary, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
