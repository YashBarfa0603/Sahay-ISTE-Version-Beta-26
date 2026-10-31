import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/screens/application/smart_filler_validation_screen.dart';
import 'package:sahay/services/sahay_bridge_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SmartFillerPortalScreen extends StatefulWidget {
  final SchemeModel scheme;

  const SmartFillerPortalScreen({super.key, required this.scheme});

  @override
  State<SmartFillerPortalScreen> createState() => _SmartFillerPortalScreenState();
}

class _SmartFillerPortalScreenState extends State<SmartFillerPortalScreen> {
  WebViewController? _webViewController;
  bool _isWebViewSupported = true;
  bool _isLoadingPortal = true;
  int _loadingProgress = 0;
  bool _isAutoFilling = false;
  bool _isAutoFilled = false;
  bool _isReadingBack = false;
  String? _portalErrorMessage;
  String _currentUrl = '';
  final Map<String, dynamic> _liveReadBackData = {};
  final List<Map<String, dynamic>> _populateEventResults = [];

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.scheme.applicationUrl ?? 'https://pmkisan.gov.in';
    _initWebView();
  }

  void _initWebView() {
    try {
      final controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.setBackgroundColor(Colors.white);

      // Register secure SahayBridge bidirectional channel
      controller.addJavaScriptChannel(
        'SahayBridge',
        onMessageReceived: _handleBridgeMessage,
      );

      controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoadingPortal = true;
                _currentUrl = url;
                _portalErrorMessage = null;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoadingPortal = false;
                _currentUrl = url;
              });
              // Attempt automated fill after portal finishes loading
              _triggerAutofill();
            }
          },
          onWebResourceError: (error) {
            debugPrint('SmartFillerPortalScreen: WebResourceError: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoadingPortal = false;
                _portalErrorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (request) {
            // Origin Security Guard: Only allow navigation to registered portal domain or official Indian gov gateways
            final targetUri = Uri.tryParse(request.url);
            final targetHost = targetUri?.host.toLowerCase() ?? '';
            final allowedDomain = _getAllowedDomain();

            final isAllowed = targetHost.contains(allowedDomain) ||
                targetHost.endsWith('.gov.in') ||
                targetHost.endsWith('.nic.in') ||
                targetHost.contains('localhost') ||
                targetHost.contains('127.0.0.1');

            if (isAllowed) {
              return NavigationDecision.navigate;
            } else {
              debugPrint('SmartFillerPortalScreen: Navigation blocked to untrusted origin: ${request.url}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigation to external domain "$targetHost" was prevented for citizen security.'),
                  backgroundColor: Colors.red.shade800,
                ),
              );
              return NavigationDecision.prevent;
            }
          },
        ),
      );

      final initialUri = Uri.tryParse(_currentUrl);
      if (initialUri != null) {
        controller.loadRequest(initialUri);
      }

      _webViewController = controller;
    } catch (e) {
      debugPrint('SmartFillerPortalScreen: WebViewController initialization fallback: $e');
      _isWebViewSupported = false;
      _isLoadingPortal = false;
    }
  }

  String _getAllowedDomain() {
    final rawUrl = widget.scheme.applicationUrl ?? '';
    final parsed = Uri.tryParse(rawUrl);
    if (parsed != null && parsed.host.isNotEmpty) {
      return parsed.host.toLowerCase().replaceAll('www.', '');
    }
    return 'gov.in';
  }

  void _handleBridgeMessage(JavaScriptMessage jsMessage) {
    debugPrint('SmartFillerPortalScreen: Bridge message received: ${jsMessage.message}');
    final provider = context.read<ApplicationProvider>();
    final session = provider.currentSession;
    final validFields = session?.sections.expand((s) => s.fields).map((f) => f.fieldId).toList() ?? [];

    final bridgeMessage = SahayBridgeMessage.parse(
      rawJson: jsMessage.message,
      expectedPortalDomain: _getAllowedDomain(),
      currentUrl: _currentUrl,
      currentSessionId: session?.sessionId,
      validFieldIds: validFields,
    );

    if (!bridgeMessage.isValid) {
      debugPrint('SmartFillerPortalScreen: Invalid bridge message: ${bridgeMessage.validationError}');
      return;
    }

    if (bridgeMessage.action == SahayBridgeAction.populateResults) {
      setState(() {
        _isAutoFilling = false;
        _isAutoFilled = true;
        _populateEventResults.clear();
        _populateEventResults.addAll(bridgeMessage.populateResults);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SAHAY Autofill: ${bridgeMessage.populateResults.length} fields populated on portal.'),
          backgroundColor: AppColors.forestGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (bridgeMessage.action == SahayBridgeAction.readbackResults) {
      setState(() {
        _isReadingBack = false;
        _liveReadBackData.clear();
        _liveReadBackData.addAll(bridgeMessage.readBackData);
      });
      _submitReadBackToBackend(_liveReadBackData);
    } else if (bridgeMessage.action == SahayBridgeAction.portalError) {
      setState(() {
        _isAutoFilling = false;
        _portalErrorMessage = bridgeMessage.errorMessage;
      });
    }
  }

  Future<void> _triggerAutofill() async {
    final provider = context.read<ApplicationProvider>();
    setState(() => _isAutoFilling = true);

    await provider.fetchPortalPopulationPayload();
    final payload = provider.portalPayload;

    if (payload != null && payload.declarativeInstructions.isNotEmpty) {
      final script = payload.declarativeInstructions.first['script']?.toString() ?? '';
      if (_webViewController != null && script.isNotEmpty) {
        try {
          await _webViewController!.runJavaScript(script);
        } catch (e) {
          debugPrint('SmartFillerPortalScreen: JS execution error: $e');
        }
      }
    }

    // Populate fallback state from session fields for resilient verification
    final session = provider.currentSession;
    if (session != null) {
      for (final sec in session.sections) {
        for (final f in sec.fields) {
          if (f.mappedValue != null && !_liveReadBackData.containsKey(f.fieldId)) {
            _liveReadBackData[f.fieldId] = f.mappedValue;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _isAutoFilling = false;
        _isAutoFilled = true;
      });
    }
  }

  Future<void> _triggerReadBackAndProceed() async {
    setState(() => _isReadingBack = true);
    final provider = context.read<ApplicationProvider>();
    final session = provider.currentSession;

    // Emitting readback script to WebView
    if (_webViewController != null && session != null) {
      final readBackScript = """
      (function() {
        var report = { action: 'READBACK_RESULTS', data: {} };
        var inputs = document.querySelectorAll('input, select, textarea');
        inputs.forEach(function(el) {
          var key = el.id || el.name;
          if (key) {
            report.data[key] = el.type === 'checkbox' ? (el.checked ? 'true' : 'false') : el.value;
          }
        });
        if (window.SahayBridge && window.SahayBridge.postMessage) {
          window.SahayBridge.postMessage(JSON.stringify(report));
        }
        return JSON.stringify(report);
      })();
      """;

      try {
        final result = await _webViewController!.runJavaScriptReturningResult(readBackScript);
        final raw = result.toString();
        if (raw.isNotEmpty && raw != 'null') {
          // Parse stringified result if returned directly
          try {
            final cleaned = raw.startsWith('"') && raw.endsWith('"') ? jsonDecode(raw) : raw;
            final map = jsonDecode(cleaned.toString());
            if (map is Map && map['data'] is Map) {
              final readMap = Map<String, dynamic>.from(map['data'] as Map);
              for (final k in readMap.keys) {
                _liveReadBackData[k] = readMap[k];
              }
            }
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('SmartFillerPortalScreen: Direct readback evaluation error: $e');
      }
    }

    _submitReadBackToBackend(_liveReadBackData);
  }

  Future<void> _submitReadBackToBackend(Map<String, dynamic> readBackData) async {
    final provider = context.read<ApplicationProvider>();
    await provider.verifyReadBack(readBackData);

    if (!mounted) return;
    setState(() => _isReadingBack = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartFillerValidationScreen(scheme: widget.scheme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final session = appProvider.currentSession;
    final targetUrl = _currentUrl.isNotEmpty ? _currentUrl : (widget.scheme.applicationUrl ?? 'https://pmkisan.gov.in');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Portal Auto-Fill Assistant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reload Portal',
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _webViewController?.reload(),
          ),
          IconButton(
            tooltip: 'Trigger Autofill',
            icon: const Icon(Icons.auto_fix_high, size: 20, color: AppColors.softSaffron),
            onPressed: _isAutoFilling ? null : _triggerAutofill,
          ),
        ],
      ),
      body: Column(
        children: [
          // Assistant Header & Stage Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.deepNavy, borderRadius: BorderRadius.circular(20)),
                  child: const Text('STAGE 4 OF 7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                const Text('Official Portal Auto-Fill & Bridge', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const Spacer(),
                if (_isAutoFilling || _isReadingBack)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.softSaffron)),
              ],
            ),
          ),

          // Portal Target URL & Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                const Icon(Icons.lock, color: AppColors.forestGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    targetUrl,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, overflow: TextOverflow.ellipsis),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isAutoFilled ? AppColors.forestGreen : Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isAutoFilling
                        ? 'AUTOFILLING...'
                        : (_isAutoFilled ? 'FIELDS POPULATED' : 'PORTAL CONNECTED'),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // Loading Progress Bar
          if (_isLoadingPortal)
            LinearProgressIndicator(
              value: _loadingProgress / 100.0,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.softSaffron),
              minHeight: 3,
            ),

          // Mandatory Manual Action Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFEF3C7),
            child: Row(
              children: const [
                Icon(Icons.shield_outlined, color: Color(0xFF92400E), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Manual Citizen Step: Visual CAPTCHA, Aadhaar OTP and legal declarations must be entered directly by you.',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Portal Error Alert if applicable
          if (_portalErrorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Portal Note: ${_portalErrorMessage!}',
                      style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Live WebView or Desktop Fallback Inspector
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isWebViewSupported && _webViewController != null
                    ? WebViewWidget(controller: _webViewController!)
                    : _buildFallbackInspectionView(session),
              ),
            ),
          ),

          // Bottom Action Bar to Run Read-Back
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: Row(
              children: [
                // Manual Continuation Option
                Expanded(
                  flex: 4,
                  child: OutlinedButton(
                    onPressed: () => _submitReadBackToBackend(_liveReadBackData),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.deepNavy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Manual Continue', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  ),
                ),
                const SizedBox(width: 12),
                // Read-Back Verification Button
                Expanded(
                  flex: 6,
                  child: ElevatedButton.icon(
                    onPressed: _isReadingBack ? null : _triggerReadBackAndProceed,
                    icon: _isReadingBack
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepNavy))
                        : const Icon(Icons.fact_check_rounded, color: AppColors.deepNavy),
                    label: Text(
                      _isReadingBack ? 'Inspecting DOM...' : 'Verify Portal Inputs',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softSaffron,
                      foregroundColor: AppColors.deepNavy,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInspectionView(ApplicationSession? session) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey.shade100,
          child: Row(
            children: const [
              Icon(Icons.terminal_rounded, size: 16, color: AppColors.forestGreen),
              SizedBox(width: 6),
              Text(
                'SahayBridge Active (Desktop / Headless Environment)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Live Script Field Injection Mapping:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.deepNavy),
              ),
              const SizedBox(height: 10),
              if (session != null)
                ...session.sections.expand((s) => s.fields).map((f) {
                  final isFilled = f.mappedValue != null && f.mappedValue.toString().trim().isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFilled ? Colors.green.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isFilled ? Colors.green.shade200 : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(isFilled ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: isFilled ? AppColors.forestGreen : Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f.fieldLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        Text(
                          isFilled ? f.mappedValue.toString() : 'Missing',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isFilled ? AppColors.deepNavy : Colors.grey),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
