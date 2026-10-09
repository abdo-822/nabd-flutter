import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../utils/blood_compatibility.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  final _dataService = DataService();
  final _formKey = GlobalKey<FormState>();

  String _selectedBloodType = BloodCompatibility.bloodTypes.first;
  final _unitsController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isSubmitting = false;
  String? _phoneError;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUserModel;
    if (user != null) {
      if (user.phone.isNotEmpty) _phoneController.text = user.phone;
      if (user.location.isNotEmpty) _cityController.text = user.location;
    }
  }

  @override
  void dispose() {
    _unitsController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUserModel;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    final code = _codeController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _codeError = code.isEmpty ? 'كود الطلب مطلوب ولا يمكن إرسال الطلب بدونه' : null;
      _phoneError = phone.isEmpty ? 'رقم الهاتف مطلوب حتى يتمكن المتبرعون من الاتصال بك' : null;
    });

    if (_codeError != null || _phoneError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'bloodType': _selectedBloodType,
        'code': code,
        'phone': phone,
        'createdBy': user.uid,
      };

      final units = int.tryParse(_unitsController.text.trim());
      if (units != null) data['units'] = units;

      final city = _cityController.text.trim();
      if (city.isNotEmpty) data['location'] = city;

      final message = _messageController.text.trim();
      if (message.isNotEmpty) data['message'] = message;

      await _dataService.createBloodRequest(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نشر نداء التبرع بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: AppColors.critical,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final inputBg = isDark ? AppColors.darkInput : AppColors.input;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final textLightColor = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب دم جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // فصيلة الدم
              Text(
                'فصيلة الدم المطلوبة *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BloodCompatibility.bloodTypes.map((type) {
                  final isSelected = _selectedBloodType == type;
                  return ChoiceChip(
                    label: Text(
                      type,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : textColor,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedBloodType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // عدد الأكياس
              Text(
                'عدد الأكياس (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _unitsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'مثال: 2',
                  hintStyle: TextStyle(color: textLightColor),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // المدينة
              Text(
                'المدينة *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: BloodCompatibility.sudancities.map((c) {
                    final isSelected = _cityController.text == c;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ActionChip(
                        label: Text(
                          c,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: isSelected ? AppColors.primary : cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          setState(() {
                            _cityController.text = isSelected ? '' : c;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: 'أو اكتب المدينة يدوياً',
                  hintStyle: TextStyle(color: textLightColor),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // رسالة
              Text(
                'رسالة للمتبرعين (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'مثال: أحتاج تبرعاً عاجلاً لمريض في مستشفى كوستي، جزاكم الله خيراً.',
                  hintStyle: TextStyle(color: textLightColor),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // رقم الهاتف
              Text(
                'رقم الهاتف للتواصل *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _phoneError != null ? AppColors.critical : textColor,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
                decoration: InputDecoration(
                  hintText: 'أدخل رقم هاتف صالح للتواصل السريع',
                  hintStyle: TextStyle(color: textLightColor),
                  filled: true,
                  fillColor: inputBg,
                  errorText: _phoneError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // كود الطلب
              Text(
                'كود الطلب أو رقم الغرفة *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _codeError != null ? AppColors.critical : textColor,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _codeController,
                onChanged: (_) {
                  if (_codeError != null) setState(() => _codeError = null);
                },
                decoration: InputDecoration(
                  hintText: 'مثال: REQ-104 أو سرير رقم 5',
                  hintStyle: TextStyle(color: textLightColor),
                  filled: true,
                  fillColor: inputBg,
                  errorText: _codeError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // زر الإرسال
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'إرسال الطلب',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
