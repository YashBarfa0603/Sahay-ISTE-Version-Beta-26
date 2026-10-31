import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/api_response_models.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/services/backend_scheme_service.dart';
import 'package:sahay/utils/indian_states.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class CscLocatorScreen extends StatefulWidget {
  final String? initialPinCode;
  final String? initialState;
  final String? initialDistrict;

  const CscLocatorScreen({
    super.key,
    this.initialPinCode,
    this.initialState,
    this.initialDistrict,
  });

  @override
  State<CscLocatorScreen> createState() => _CscLocatorScreenState();
}

class _CscLocatorScreenState extends State<CscLocatorScreen> {
  final BackendSchemeService _backendService = BackendSchemeService();
  final TextEditingController _pinController = TextEditingController();

  String? _selectedState;
  String? _selectedDistrict;
  bool _isLoading = false;
  List<CscCentreModel> _centres = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.initialState ?? 'Madhya Pradesh';
    _selectedDistrict = widget.initialDistrict;
    if (widget.initialPinCode != null) {
      _pinController.text = widget.initialPinCode!;
    }
    _searchCentres();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _searchCentres() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pin = _pinController.text.trim();
      final response = await _backendService.searchCscCentres(
        state: _selectedState,
        district: _selectedDistrict,
        pinCode: pin.isNotEmpty ? pin : null,
      );

      setState(() {
        _centres = response.centres;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load CSC centres. Please check your connectivity.';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchDirections(String address) async {
    final query = Uri.encodeComponent(address);
    final mapUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
    final uri = Uri.tryParse(mapUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.tryParse('tel:$clean');
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().languageCode;
    final isHi = lang == 'hi';

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: isHi ? 'जन सेवा केंद्र खोजें (CSC)' : 'Find Assistance Centre (CSC)',
        showBackButton: true,
        showLanguageToggle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Filters Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.deepNavy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHi
                      ? 'नजदीकी सीएससी (जन सेवा केंद्र) खोजें'
                      : 'Find Authorized Common Service Centres',
                    style: AppTextStyles.heading3.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // State Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: IndianStates.states.any((s) => s.nameEnglish == _selectedState)
                                  ? _selectedState
                                  : null,
                              hint: Text(isHi ? 'राज्य चुनें' : 'Select State', style: AppTextStyles.caption),
                              isExpanded: true,
                              items: IndianStates.states.map((st) {
                                return DropdownMenuItem<String>(
                                  value: st.nameEnglish,
                                  child: Text(st.getLocalizedName(lang), style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedState = val;
                                  _selectedDistrict = null;
                                });
                                _searchCentres();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // PIN Code Search
                      Expanded(
                        child: TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: isHi ? 'पिन कोड (उदा. 462011)' : 'PIN Code (e.g. 462011)',
                            hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search_rounded, color: AppColors.indianTeal, size: 20),
                              onPressed: _searchCentres,
                            ),
                          ),
                          onSubmitted: (_) => _searchCentres(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Warning / Offline guidance banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.paleSage,
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.forestGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isHi
                          ? 'सभी केंद्र डिजिटल इंडिया के अंतर्गत अधिकृत हैं। आवेदन हेतु आधार एवं बैंक पासबुक साथ ले जाएं।'
                          : 'Official Digital India CSC partners. Carry Aadhaar and Bank Passbook for scheme enrollment.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.forestGreen, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.indianTeal))
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.mutedCoral, size: 40),
                              const SizedBox(height: 10),
                              Text(_errorMessage!, style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _searchCentres,
                                child: Text(isHi ? 'पुनः प्रयास करें' : 'Retry'),
                              ),
                            ],
                          ),
                        )
                      : _centres.isEmpty
                          ? Center(
                              child: Text(
                                isHi ? 'कोई केंद्र नहीं मिला।' : 'No centres found for selected filters.',
                                style: AppTextStyles.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _centres.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final centre = _centres[index];
                                return _buildCscCard(centre, isHi);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCscCard(CscCentreModel centre, bool isHi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warmSand),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softSaffron.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.deepNavy, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      centre.name,
                      style: AppTextStyles.heading3.copyWith(fontSize: 16, color: AppColors.deepNavy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isHi ? 'संचालक' : 'Operator'}: ${centre.vleName}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.indianTeal, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (centre.isVerified)
                const Chip(
                  label: Text('Verified', style: TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: AppColors.forestGreen,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${centre.address} - PIN: ${centre.pinCode}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.deepNavy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Services Available Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: centre.servicesAvailable.map((srv) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warmSand.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  srv,
                  style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.deepNavy),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Actions
          Row(
            children: [
              if (centre.contactNumber != null) ...[
                OutlinedButton.icon(
                  onPressed: () => _launchCall(centre.contactNumber!),
                  icon: const Icon(Icons.call_rounded, size: 16, color: AppColors.forestGreen),
                  label: Text(isHi ? 'कॉल करें' : 'Call', style: const TextStyle(color: AppColors.forestGreen, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.forestGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchDirections(centre.address),
                  icon: const Icon(Icons.directions_rounded, size: 16, color: Colors.white),
                  label: Text(isHi ? 'रास्ता देखें' : 'Directions', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indianTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
