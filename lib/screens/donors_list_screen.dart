import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../utils/blood_compatibility.dart';

class DonorsListScreen extends StatefulWidget {
  const DonorsListScreen({super.key});

  @override
  State<DonorsListScreen> createState() => _DonorsListScreenState();
}

class _DonorsListScreenState extends State<DonorsListScreen> {
  final _dataService = DataService();
  List<UserModel> _donors = [];
  bool _isLoading = true;
  String? _selectedBloodType;
  String _statusFilter = 'الكل'; // 'الكل', 'متاح', 'غير متاح'

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  Future<void> _loadDonors() async {
    setState(() => _isLoading = true);
    try {
      final list = await _dataService.getDonors();
      setState(() {
        _donors = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  List<UserModel> get _filteredDonors {
    return _donors.where((donor) {
      final avail = BloodCompatibility.isDonorAvailable(
        isActive: donor.isActive,
        lastDonationDate: donor.lastDonationDate,
      );

      if (_statusFilter == 'متاح' && !avail.available) return false;
      if (_statusFilter == 'غير متاح' && avail.available) return false;

      if (_selectedBloodType != null && _selectedBloodType!.isNotEmpty) {
        if (!BloodCompatibility.canDonateTo(donor.bloodType, _selectedBloodType!)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final aAvail = BloodCompatibility.isDonorAvailable(
          isActive: a.isActive,
          lastDonationDate: a.lastDonationDate,
        ).available;
        final bAvail = BloodCompatibility.isDonorAvailable(
          isActive: b.isActive,
          lastDonationDate: b.lastDonationDate,
        ).available;
        return (bAvail ? 1 : 0) - (aAvail ? 1 : 0);
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final textLightColor = isDark ? AppColors.darkTextLight : AppColors.textLight;

    final filtered = _filteredDonors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة المتبرعين', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // لوحة التصفية
          Container(
            color: cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تصفية حسب فصيلة الدم للمريض:',
                  style: TextStyle(fontSize: 12, color: textLightColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('الكل'),
                        backgroundColor: _selectedBloodType == null ? AppColors.primary : (isDark ? AppColors.darkInput : AppColors.input),
                        labelStyle: TextStyle(
                          color: _selectedBloodType == null ? Colors.white : textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        onPressed: () => setState(() => _selectedBloodType = null),
                      ),
                      ...BloodCompatibility.bloodTypes.map((type) {
                        final isSelected = _selectedBloodType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(type),
                            backgroundColor: isSelected ? AppColors.primary : (isDark ? AppColors.darkInput : AppColors.input),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontWeight: FontWeight.bold,
                            ),
                            onPressed: () => setState(() => _selectedBloodType = isSelected ? null : type),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // حالة التوفر
                Row(
                  children: ['الكل', 'متاح', 'غير متاح'].map((status) {
                    final isSelected = _statusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: (isDark ? AppColors.darkInput : AppColors.input),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _statusFilter = status);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // قائمة المتبرعين
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadDonors,
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.person_search_outlined, size: 64, color: textLightColor),
                                    const SizedBox(height: 12),
                                    Text('لا يوجد متبرعون يطابقون شروط البحث', style: TextStyle(color: textColor, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final donor = filtered[index];
                              final avail = BloodCompatibility.isDonorAvailable(
                                isActive: donor.isActive,
                                lastDonationDate: donor.lastDonationDate,
                              );
                              final isExact = _selectedBloodType != null && donor.bloodType == _selectedBloodType;

                              return Card(
                                color: cardColor,
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: AppColors.primary.withOpacity(0.15),
                                                child: Text(
                                                  donor.bloodType,
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    donor.name.isNotEmpty ? donor.name : 'متبرع مسجل',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  if (donor.location.isNotEmpty)
                                                    Row(
                                                      children: [
                                                        Icon(Icons.location_on_outlined, size: 14, color: textLightColor),
                                                        const SizedBox(width: 2),
                                                        Text(donor.location, style: TextStyle(fontSize: 12, color: textLightColor)),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (avail.available ? AppColors.success : AppColors.critical).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              avail.available ? 'متاح' : 'غير متاح',
                                              style: TextStyle(
                                                color: avail.available ? AppColors.success : AppColors.critical,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (isExact) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('تطابق تام للفصيلة', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],

                                      if (!avail.available && avail.reason != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          avail.reason! + (avail.availableFrom != null ? ' (متاح من ${avail.availableFrom!.year}-${avail.availableFrom!.month}-${avail.availableFrom!.day})' : ''),
                                          style: TextStyle(fontSize: 12, color: textLightColor),
                                        ),
                                      ],

                                      if (donor.phone.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(donor.phone, style: TextStyle(color: textLightColor, fontSize: 14)),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                                                  onPressed: () => _makeCall(donor.phone),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.message, color: Color(0xFF25D366), size: 20),
                                                  onPressed: () => _openWhatsApp(donor.phone),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
