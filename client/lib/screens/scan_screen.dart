import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/api_service.dart';
import '../providers/locale_provider.dart';
import 'analysis_screen.dart';
import '../widgets/user_profile_button.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  
  bool _isProcessing = false;
  String _statusMessage = '';

  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _scanImage(ImageSource source) async {
    final loc = ref.read(localeProvider.notifier);
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _statusMessage = loc.translate('scan.processingPhoto');
      });

      String extractedText = '';

      if (_isMobile) {
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        try {
          final inputImage = InputImage.fromFilePath(image.path);
          final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
          extractedText = recognizedText.text;
        } catch (mlKitErr) {
          debugPrint('MLKit local OCR error, falling back to server vision: $mlKitErr');
        } finally {
          textRecognizer.close();
        }
      }

      final Uint8List bytes = await image.readAsBytes();
      final String mimeType = image.mimeType ?? (image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
      final String base64Str = base64Encode(bytes);

      if (extractedText.trim().length > 10) {
        await _analyzeText(
          extractedText, 
          title: image.name.isNotEmpty ? image.name : 'Photo Scan Document', 
          sourceType: 'Photo Scan', 
          base64Data: base64Str, 
          mimeType: mimeType
        );
        return;
      }

      // Multimodal AI Vision Fallback (Web, Desktop, or scanned images)
      final analysisResult = await ApiService.scanDocumentFile(bytes, mimeType, title: image.name, sourceType: 'Photo Scan');
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            originalText: analysisResult['extractedText'] ?? 'Scanned Property Image',
            analysis: analysisResult['analysis'] ?? [],
            documentTitle: image.name.isNotEmpty ? image.name : 'Scanned Property Agreement',
            sourceType: 'Photo Scan',
            fileData: base64Str,
            mimeType: mimeType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _scanPdf() async {
    final loc = ref.read(localeProvider.notifier);
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _isProcessing = true;
          _statusMessage = loc.translate('scan.processingPdf');
        });

        final PlatformFile file = result.files.single;
        List<int>? bytes = file.bytes?.toList();
        if (bytes == null && file.path != null) {
          final ioFile = File(file.path!);
          bytes = await ioFile.readAsBytes();
        }

        if (bytes == null || bytes.isEmpty) {
          throw Exception('Could not read selected document file.');
        }

        final Uint8List uint8bytes = Uint8List.fromList(bytes);
        final String fileName = file.name;
        final String ext = fileName.split('.').last.toLowerCase();
        final String base64Str = base64Encode(uint8bytes);

        if (ext == 'pdf') {
          String extractedText = '';
          try {
            final PdfDocument document = PdfDocument(inputBytes: uint8bytes);
            extractedText = PdfTextExtractor(document).extractText();
            document.dispose();
          } catch (pdfErr) {
            debugPrint('PdfTextExtractor error, falling back to server vision: $pdfErr');
          }

          if (extractedText.trim().length > 20) {
            await _analyzeText(
              extractedText, 
              title: fileName, 
              sourceType: 'PDF Document', 
              base64Data: base64Str, 
              mimeType: 'application/pdf'
            );
            return;
          }

          // Scanned PDF fallback via Multimodal Vision AI
          setState(() {
            _statusMessage = loc.translate('scan.processingPdfVision');
          });
          final analysisResult = await ApiService.scanDocumentFile(uint8bytes, 'application/pdf', title: fileName, sourceType: 'PDF Document');

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AnalysisScreen(
                originalText: analysisResult['extractedText'] ?? 'Scanned PDF Document',
                analysis: analysisResult['analysis'] ?? [],
                documentTitle: fileName,
                sourceType: 'PDF Document',
                fileData: base64Str,
                mimeType: 'application/pdf',
              ),
            ),
          );
        } else {
          final String mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
          final analysisResult = await ApiService.scanDocumentFile(uint8bytes, mimeType, title: fileName, sourceType: 'Photo Scan');

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AnalysisScreen(
                originalText: analysisResult['extractedText'] ?? 'Scanned Image Document',
                analysis: analysisResult['analysis'] ?? [],
                documentTitle: fileName,
                sourceType: 'Photo Scan',
                fileData: base64Str,
                mimeType: mimeType,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading document: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _analyzeText(String text, {String? title, String? sourceType, String? base64Data, String? mimeType}) async {
    final loc = ref.read(localeProvider.notifier);
    setState(() {
      _isProcessing = true;
      _statusMessage = loc.translate('scan.processingRisk');
    });

    try {
      final analysisResult = await ApiService.scanDocument(
        text, 
        title: title, 
        sourceType: sourceType ?? 'Text Description',
        base64Data: base64Data,
        mimeType: mimeType,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            originalText: text,
            analysis: analysisResult['analysis'] ?? [],
            documentTitle: title ?? 'Scanned Property Agreement',
            sourceType: sourceType ?? 'Text Description',
            fileData: base64Data ?? analysisResult['fileData'],
            mimeType: mimeType ?? analysisResult['mimeType'],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = colorScheme.surface;
    final primaryAccent = colorScheme.primary;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final borderColor = colorScheme.outline;
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          UserProfileButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isProcessing
                    ? _buildProcessingState(textPrimary, textSecondary, primaryAccent, loc)
                    : SingleChildScrollView(
                        key: const ValueKey('main_form'),
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              loc.translate('scan.title'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              loc.translate('scan.subtitle'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Hero Icon
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.document_scanner_outlined, size: 48, color: primaryAccent),
                            ),
                            const SizedBox(height: 32),

                            // Upload Card
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _HoverableButton(
                                    icon: Icons.camera_alt,
                                    label: loc.translate('scan.takePhoto'),
                                    onPressed: () => _scanImage(ImageSource.camera),
                                    isPrimary: true,
                                    primaryAccent: primaryAccent,
                                    textPrimary: textPrimary,
                                  ),
                                  const SizedBox(height: 16),
                                  _HoverableButton(
                                    icon: Icons.image,
                                    label: loc.translate('scan.uploadFromGallery'),
                                    onPressed: () => _scanImage(ImageSource.gallery),
                                    isPrimary: false,
                                    primaryAccent: primaryAccent,
                                    textPrimary: textPrimary,
                                  ),
                                  const SizedBox(height: 16),
                                  _HoverableButton(
                                    icon: Icons.picture_as_pdf,
                                    label: loc.translate('scan.uploadPdf'),
                                    onPressed: _scanPdf,
                                    isPrimary: false,
                                    primaryAccent: primaryAccent,
                                    textPrimary: textPrimary,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: borderColor, thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(loc.translate('common.or'), style: TextStyle(color: textSecondary, fontSize: 14)),
                                ),
                                Expanded(child: Divider(color: borderColor, thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Text Entry Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.translate('scan.documentContent'),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    loc.translate('scan.pastePrompt'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _FocusableTextField(
                                    controller: _textController,
                                    hintText: loc.translate('scan.pasteHint'),
                                    bgColor: bgColor,
                                    borderColor: borderColor,
                                    primaryAccent: primaryAccent,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                  const SizedBox(height: 24),
                                  _HoverableButton(
                                    icon: Icons.analytics_outlined,
                                    label: loc.translate('scan.analyzeBtn'),
                                    onPressed: () {
                                      if (_textController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(loc.translate('scan.emptyError'), style: const TextStyle(color: Colors.white)),
                                            backgroundColor: const Color(0xFFD76C6C),
                                          ),
                                        );
                                        return;
                                      }
                                      _analyzeText(_textController.text.trim());
                                    },
                                    isPrimary: true,
                                    primaryAccent: primaryAccent,
                                    textPrimary: textPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState(Color textPrimary, Color textSecondary, Color primaryAccent, LocaleNotifier loc) {
    return Center(
      key: const ValueKey('processing_state'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryAccent),
          const SizedBox(height: 24),
          Text(
            _statusMessage, 
            style: TextStyle(fontSize: 18, color: textPrimary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('scan.pleaseWait'),
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HoverableButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color primaryAccent;
  final Color textPrimary;

  const _HoverableButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    required this.primaryAccent,
    required this.textPrimary,
  });

  @override
  State<_HoverableButton> createState() => _HoverableButtonState();
}

class _HoverableButtonState extends State<_HoverableButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          height: 56,
          child: widget.isPrimary
              ? ElevatedButton.icon(
                  onPressed: widget.onPressed,
                  icon: Icon(widget.icon, color: Colors.white),
                  label: Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _isHovered ? 6 : 2,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: widget.onPressed,
                  icon: Icon(widget.icon, color: widget.textPrimary),
                  label: Text(widget.label, style: TextStyle(color: widget.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: widget.primaryAccent),
                    backgroundColor: _isHovered ? widget.primaryAccent.withValues(alpha: 0.1) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _FocusableTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final Color bgColor;
  final Color borderColor;
  final Color primaryAccent;
  final Color textPrimary;
  final Color textSecondary;

  const _FocusableTextField({
    required this.controller,
    this.hintText,
    required this.bgColor,
    required this.borderColor,
    required this.primaryAccent,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<_FocusableTextField> createState() => _FocusableTextFieldState();
}

class _FocusableTextFieldState extends State<_FocusableTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: widget.primaryAccent.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        minLines: 10,
        maxLines: null,
        style: TextStyle(color: widget.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Paste your legal document here...',
          hintStyle: TextStyle(color: widget.textSecondary),
          filled: true,
          fillColor: widget.bgColor,
          contentPadding: const EdgeInsets.all(18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: widget.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: widget.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: widget.primaryAccent, width: 2),
          ),
        ),
      ),
    );
  }
}
