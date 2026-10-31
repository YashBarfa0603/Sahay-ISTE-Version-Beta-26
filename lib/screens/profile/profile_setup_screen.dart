import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/screens/auth/auth_gate.dart';
import 'package:sahay/utils/indian_states.dart';
import 'package:sahay/utils/profile_options.dart';
import 'package:sahay/utils/validators.dart';
import 'package:sahay/widgets/language_toggle.dart';

/// Mandatory post-signup profile setup screen completing demographic eligibility fields.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _districtController = TextEditingController();

  String? _selectedState;
  String? _selectedOccupation;
  String? _selectedGender;
  String? _selectedResidenceType;
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final currentAppLang = context.read<LocaleProvider>().languageCode;

    _selectedLanguage = user?.preferredLanguage ?? currentAppLang;
    if (user?.age != null) {
      _ageController.text = user!.age.toString();
    }
    if (user?.state != null) {
      _selectedState = user!.state;
    }
    if (user?.district != null) {
      _districtController.text = user!.district!;
    }
    if (user?.occupation != null) {
      _selectedOccupation = user!.occupation;
    }
    if (user?.gender != null) {
      _selectedGender = user!.gender;
    }
    if (user?.residenceType != null) {
      _selectedResidenceType = user!.residenceType;
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your state / कृपया अपना राज्य चुनें'),
          backgroundColor: AppColors.mutedCoral,
        ),
      );
      return;
    }

    if (_selectedOccupation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your occupation / कृपया अपना व्यवसाय चुनें'),
          backgroundColor: AppColors.mutedCoral,
        ),
      );
      return;
    }

    final lang = context.read<LocaleProvider>().languageCode;
    final parsedAge = int.tryParse(_ageController.text.trim()) ?? 0;

    final success = await auth.updateProfile({
      'age': parsedAge,
      'state': _selectedState,
      'district': _districtController.text.trim(),
      'occupation': _selectedOccupation,
      'preferredLanguage': _selectedLanguage,
      'gender': _selectedGender,
      'residenceType': _selectedResidenceType,
      'profileComplete': true,
      'onboardingCompleted': true,
      'onboardingCompletedAt': DateTime.now().toIso8601String(),
    }, lang: lang);

    if (success && mounted) {
      // Sync app locale with selected preferred language
      context.read<LocaleProvider>().setLocale(Locale(_selectedLanguage));
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isHi = context.watch<LocaleProvider>().languageCode == 'hi';
    final lang = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isHi ? 'प्रोफ़ाइल सेटअप' : 'Complete Profile',
          style: AppTextStyles.heading3.copyWith(color: AppColors.deepNavy),
        ),
        actions: [
          IconButton(
            tooltip: isHi ? 'साइन आउट' : 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.mutedCoral),
            onPressed: auth.isLoading ? null : () => auth.signOut(),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LanguageToggle(iconColor: AppColors.indianTeal, iconSize: 22),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isHi ? 'सटीक योजनाओं की खोज के लिए जानकारी दें' : 'A few details to match eligible schemes',
                  style: AppTextStyles.heading2.copyWith(color: AppColors.deepNavy, fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  isHi
                      ? 'यह जानकारी केवल सरकारी योजनाओं की पात्रता जांचने के लिए उपयोग की जाएगी।'
                      : 'These details are strictly used to evaluate government welfare schemes.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 20),

                // Error banner
                if (auth.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mutedCoral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.mutedCoral.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      auth.errorMessage!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Age (Mandatory)
                Text(
                  isHi ? 'आयु (वर्ष) *' : 'Age (Years) *',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: isHi ? 'उदा. 35' : 'e.g. 35',
                    prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.indianTeal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  validator: (v) => Validators.validateAge(v, lang),
                ),
                const SizedBox(height: 16),

                // State (Mandatory)
                Text(
                  isHi ? 'राज्य / केंद्र शासित प्रदेश *' : 'State / Union Territory *',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.indianTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  hint: Text(isHi ? 'राज्य चुनें' : 'Select State'),
                  items: IndianStates.states.map((st) {
                    final label = IndianStates.getStateName(st.code, lang);
                    return DropdownMenuItem(
                      value: st.code,
                      child: Text(label, style: AppTextStyles.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedState = val),
                  validator: (val) => val == null
                      ? (isHi ? 'कृपया राज्य चुनें' : 'Please select your state')
                      : null,
                ),
                const SizedBox(height: 16),

                // District (Mandatory)
                Text(
                  isHi ? 'ज़िला *' : 'District *',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _districtController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: isHi ? 'उदा. भोपाल' : 'e.g. Bhopal',
                    prefixIcon: const Icon(Icons.map_outlined, color: AppColors.indianTeal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isHi ? 'कृपया अपना ज़िला दर्ज करें' : 'Please enter your district';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Occupation (Mandatory - 13 canonical keys)
                Text(
                  isHi ? 'व्यवसाय / कार्यक्षेत्र *' : 'Occupation *',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedOccupation,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.indianTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  hint: Text(isHi ? 'व्यवसाय चुनें' : 'Select Occupation'),
                  items: ProfileOptions.occupations.map((occ) {
                    final label = ProfileOptions.getOccupationLabel(occ.key, lang);
                    return DropdownMenuItem(
                      value: occ.key,
                      child: Text(label, style: AppTextStyles.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedOccupation = val),
                  validator: (val) => val == null
                      ? (isHi ? 'कृपया व्यवसाय चुनें' : 'Please select your occupation')
                      : null,
                ),
                const SizedBox(height: 16),

                // Preferred Language (Mandatory)
                Text(
                  isHi ? 'पसंदीदा भाषा *' : 'Preferred Language *',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.translate_rounded, color: AppColors.indianTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
                    DropdownMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)')),
                    DropdownMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
                    DropdownMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
                    DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી (Gujarati)')),
                    DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ (Kannada)')),
                    DropdownMenuItem(value: 'or', child: Text('ଓଡ଼ିଆ (Odia)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedLanguage = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Gender (Optional)
                Text(
                  isHi ? 'लिंग (वैकल्पिक)' : 'Gender (Optional)',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.indianTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  hint: Text(isHi ? 'लिंग चुनें' : 'Select Gender'),
                  items: ProfileOptions.genders.map((g) {
                    final label = ProfileOptions.getGenderLabel(g.key, lang);
                    return DropdownMenuItem(
                      value: g.key,
                      child: Text(label, style: AppTextStyles.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                ),
                const SizedBox(height: 16),

                // Residence Type (Optional)
                Text(
                  isHi ? 'निवास प्रकार (वैकल्पिक)' : 'Residence Type (Optional)',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedResidenceType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.home_outlined, color: AppColors.indianTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  hint: Text(isHi ? 'निवास क्षेत्र चुनें' : 'Select Residence Type'),
                  items: ProfileOptions.residenceTypes.map((r) {
                    final label = ProfileOptions.getResidenceLabel(r.key, lang);
                    return DropdownMenuItem(
                      value: r.key,
                      child: Text(label, style: AppTextStyles.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedResidenceType = val),
                ),
                const SizedBox(height: 28),

                // Save button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indianTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isHi ? 'प्रोफ़ाइल सहेजें' : 'Save Profile',
                            style: AppTextStyles.buttonText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
