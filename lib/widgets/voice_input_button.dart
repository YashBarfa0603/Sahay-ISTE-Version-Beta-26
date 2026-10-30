import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/services/voice_service.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String recognizedText) onResult;
  final VoiceService? voiceService;
  final String? idleLabel;
  final String? listeningLabel;
  final double size;
  final bool showLabel;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.voiceService,
    this.idleLabel,
    this.listeningLabel,
    this.size = 56.0,
    this.showLabel = true,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late final VoiceService _voiceService;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rippleAnimation;

  bool _isListening = false;
  bool _ownsVoiceService = false;

  @override
  void initState() {
    super.initState();
    if (widget.voiceService != null) {
      _voiceService = widget.voiceService!;
      _ownsVoiceService = false;
    } else {
      _voiceService = VoiceService();
      _ownsVoiceService = true;
      _voiceService.initialize();
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    if (_isListening) {
      _voiceService.stopListening();
    }
    _pulseController.dispose();
    if (_ownsVoiceService) {
      _voiceService.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleListening() async {
    final localeProvider = Provider.of<LocaleProvider?>(context, listen: false);
    final langCode = localeProvider?.languageCode ?? 'en';

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening(langCode);
    }
  }

  Future<void> _startListening(String langCode) async {
    setState(() {
      _isListening = true;
    });
    _pulseController.repeat(reverse: true);

    try {
      await _voiceService.startListening(
        locale: langCode,
        onResult: (text) {
          if (mounted && text.isNotEmpty) {
            widget.onResult(text);
          }
        },
      );
    } catch (e) {
      debugPrint('VoiceInputButton startListening failed: $e');
      if (mounted) {
        _stopListening();
      }
    }
  }

  Future<void> _stopListening() async {
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isListening = false;
    });

    try {
      await _voiceService.stopListening();
    } catch (e) {
      debugPrint('VoiceInputButton stopListening failed: $e');
    }
  }

  String _getIdleText(String langCode) {
    if (widget.idleLabel != null) return widget.idleLabel!;
    switch (langCode) {
      case 'hi':
        return 'बोलने के लिए टैप करें';
      case 'ta':
        return 'பேச தட்டவும்';
      case 'mr':
        return 'बोलण्यासाठी टॅप करा';
      case 'bn':
        return 'কথা বলতে ট্যাপ করুন';
      case 'gu':
        return 'બોલવા માટે ટેપ કરો';
      case 'kn':
        return 'ಮಾತನಾಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ';
      case 'or':
        return 'କହିବା ପାଇଁ ଟ୍ୟାପ୍ କରନ୍ତୁ';
      case 'en':
      default:
        return 'Tap to speak';
    }
  }

  String _getListeningText(String langCode) {
    if (widget.listeningLabel != null) return widget.listeningLabel!;
    switch (langCode) {
      case 'hi':
        return 'सुन रहे हैं...';
      case 'ta':
        return 'கேட்கிறது...';
      case 'mr':
        return 'ऐकत आहे...';
      case 'bn':
        return 'শুনছি...';
      case 'gu':
        return 'સાંભળી રહ્યા છીએ...';
      case 'kn':
        return 'ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದ್ದೇವೆ...';
      case 'or':
        return 'ଶୁଣୁଛି...';
      case 'en':
      default:
        return 'Listening...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider?>();
    final langCode = localeProvider?.languageCode ?? 'en';

    final label = _isListening ? _getListeningText(langCode) : _getIdleText(langCode);
    final buttonColor = _isListening ? AppColors.softSaffron : AppColors.indianTeal;
    final iconColor = _isListening ? AppColors.deepNavy : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Pulsing Ripple (active only when listening)
            if (_isListening)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: widget.size * _rippleAnimation.value,
                    height: widget.size * _rippleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.softSaffron.withValues(
                        alpha: (1.0 - _pulseController.value) * 0.45,
                      ),
                    ),
                  );
                },
              ),

            // Inner Pulsing Button
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isListening ? _scaleAnimation.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Material(
                    color: buttonColor,
                    shape: const CircleBorder(),
                    elevation: _isListening ? 6 : 3,
                    shadowColor: buttonColor.withValues(alpha: 0.4),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _toggleListening,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        alignment: Alignment.center,
                        child: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          size: widget.size * 0.52,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        if (widget.showLabel) ...[
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.caption.copyWith(
              color: _isListening ? AppColors.mutedAmber : AppColors.deepNavy,
              fontWeight: _isListening ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
