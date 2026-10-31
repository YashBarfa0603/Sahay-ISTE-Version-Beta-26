import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/api_response_models.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/services/backend_scheme_service.dart';

class IncomeEstimationModal extends StatefulWidget {
  final Function(double estimatedAnnualIncome) onEstimateApplied;

  const IncomeEstimationModal({
    super.key,
    required this.onEstimateApplied,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(double estimatedAnnualIncome) onEstimateApplied,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncomeEstimationModal(onEstimateApplied: onEstimateApplied),
    );
  }

  @override
  State<IncomeEstimationModal> createState() => _IncomeEstimationModalState();
}

class _IncomeEstimationModalState extends State<IncomeEstimationModal> {
  final BackendSchemeService _backendService = BackendSchemeService();

  String _selectedSource = 'unorganized_worker';
  double _monthlyPerEarner = 8000.0;
  int _householdEarners = 1;
  bool _hasAgriIncome = false;
  final double _agriAnnual = 25000.0;

  bool _isCalculating = false;
  IncomeEstimationApiResponse? _calculationResult;

  final List<Map<String, String>> _sources = [
    {'id': 'farming', 'labelEn': 'Farmer / Cultivator', 'labelHi': 'किसान / काश्तकार'},
    {'id': 'daily_wage', 'labelEn': 'Daily Wage Labor', 'labelHi': 'दैनिक मजदूरी'},
    {'id': 'street_vendor', 'labelEn': 'Street Vendor / Hawkers', 'labelHi': 'रेहड़ी / पटरी विक्रेता'},
    {'id': 'artisan', 'labelEn': 'Artisan / Craftsperson', 'labelHi': 'कारीगर / शिल्पकार'},
    {'id': 'unorganized_worker', 'labelEn': 'Unorganized Worker', 'labelHi': 'असंगठित श्रमिक'},
    {'id': 'salaried_private', 'labelEn': 'Private Salaried', 'labelHi': 'निजी कर्मचारी'},
    {'id': 'small_business', 'labelEn': 'Small Shop / Business', 'labelHi': 'छोटा व्यापार / दुकान'},
  ];

  Future<void> _calculateIncome() async {
    setState(() => _isCalculating = true);

    try {
      final req = IncomeEstimationRequest(
        primarySource: _selectedSource,
        monthlyEstimatedIncome: _monthlyPerEarner,
        householdEarners: _householdEarners,
        hasAgriculturalIncome: _hasAgriIncome,
        seasonalAgriculturalIncome: _hasAgriIncome ? _agriAnnual : null,
      );

      final res = await _backendService.estimateHouseholdIncome(req);
      setState(() {
        _calculationResult = res;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() => _isCalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().languageCode;
    final isHi = lang == 'hi';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.warmIvory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.deepNavy.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                const Icon(Icons.calculate_outlined, color: AppColors.indianTeal, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHi ? 'पारिवारिक आय का सुरक्षित अनुमान' : 'Household Income Estimation',
                        style: AppTextStyles.heading3.copyWith(color: AppColors.deepNavy, fontSize: 17),
                      ),
                      Text(
                        isHi ? 'अनौपचारिक आय के लिए विश्वसनीय गणना' : 'Conservative estimation for informal earners',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_calculationResult == null) ...[
              // Step 1: Livelihood Source
              Text(
                isHi ? '1. मुख्य आजीविका का साधन चुनें' : '1. Select primary livelihood source',
                style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sources.map((s) {
                  final isSelected = _selectedSource == s['id'];
                  return ChoiceChip(
                    label: Text(
                      isHi ? s['labelHi']! : s['labelEn']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.deepNavy,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.indianTeal,
                    backgroundColor: Colors.white,
                    onSelected: (val) {
                      if (val) setState(() => _selectedSource = s['id']!);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Step 2: Monthly per earner
              Text(
                isHi
                    ? '2. लगभग मासिक आय प्रति कमाने वाला: ₹${_monthlyPerEarner.toStringAsFixed(0)}'
                    : '2. Approximate monthly earning per earner: ₹${_monthlyPerEarner.toStringAsFixed(0)}',
                style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
              ),
              Slider(
                value: _monthlyPerEarner,
                min: 3000,
                max: 40000,
                divisions: 37,
                activeColor: AppColors.indianTeal,
                label: '₹${_monthlyPerEarner.toStringAsFixed(0)}',
                onChanged: (val) => setState(() => _monthlyPerEarner = val),
              ),

              // Step 3: Earners
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isHi ? '3. परिवार में कुल कमाने वाले सदस्य' : '3. Total earning members in family',
                    style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.indianTeal),
                        onPressed: _householdEarners > 1
                            ? () => setState(() => _householdEarners--)
                            : null,
                      ),
                      Text('$_householdEarners', style: AppTextStyles.heading3.copyWith(color: AppColors.deepNavy)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.indianTeal),
                        onPressed: _householdEarners < 6
                            ? () => setState(() => _householdEarners++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),

              // Step 4: Agriculture harvest optional
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.forestGreen,
                title: Text(
                  isHi ? 'कृषि / मौसमी फसल से अतिरिक्त आय' : 'Additional seasonal agricultural harvest income',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.deepNavy),
                ),
                value: _hasAgriIncome,
                onChanged: (val) => setState(() => _hasAgriIncome = val ?? false),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isCalculating ? null : _calculateIncome,
                  icon: _isCalculating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    isHi ? 'अनुमानित आय की गणना करें' : 'Calculate Conservative Estimate',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indianTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else ...[
              // Result View
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paleSage,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHi ? 'अनुमानित वार्षिक पारिवारिक आय:' : 'Estimated Annual Household Income Range:',
                      style: AppTextStyles.caption.copyWith(color: AppColors.forestGreen, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${_calculationResult!.minAnnualIncome.toStringAsFixed(0)} — ₹${_calculationResult!.maxAnnualIncome.toStringAsFixed(0)}',
                      style: AppTextStyles.heading1.copyWith(color: AppColors.deepNavy, fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _calculationResult!.explanation,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.deepNavy, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      isHi ? 'मुख्य आधार एवं शर्तें:' : 'Assumptions:',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ..._calculationResult!.assumptions.map(
                      (a) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(a, style: AppTextStyles.caption)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _calculationResult = null),
                      child: Text(isHi ? 'बदलाव करें' : 'Recalculate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onEstimateApplied(_calculationResult!.medianEstimate);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indianTeal,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isHi ? 'यह अनुमान लागू करें' : 'Apply This Estimate',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
