import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/api_service.dart';
import 'analysis_screen.dart';
import '../widgets/theme_toggle_button.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  
  bool _isProcessing = false;
  String _statusMessage = '';

  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _scanImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Extracting text...';
      });

      String extractedText = '';

      if (_isMobile) {
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        try {
          final inputImage = InputImage.fromFilePath(image.path);
          final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
          extractedText = recognizedText.text;
        } finally {
          textRecognizer.close();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera OCR is supported on mobile devices. Please paste document text below for Web analysis.')),
          );
        }
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      if (extractedText.isEmpty) {
        throw Exception('No text found in the image.');
      }

      await _analyzeText(extractedText);
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
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb, // Web requires bytes directly
      );

      if (result != null) {
        setState(() {
          _isProcessing = true;
          _statusMessage = 'Extracting PDF text...';
        });

        List<int>? bytes;
        if (kIsWeb) {
          bytes = result.files.single.bytes?.toList();
        } else {
          final file = File(result.files.single.path!);
          bytes = await file.readAsBytes();
        }

        if (bytes == null || bytes.isEmpty) {
          throw Exception('Could not read file.');
        }

        final PdfDocument document = PdfDocument(inputBytes: bytes);
        final String extractedText = PdfTextExtractor(document).extractText();
        document.dispose();

        if (extractedText.trim().isEmpty) {
          throw Exception('No readable text found in this PDF.');
        }

        await _analyzeText(extractedText, title: result.files.single.name);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading PDF: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _analyzeText(String text, {String? title}) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyzing for risks...';
    });

    try {
      final analysisResult = await ApiService.scanDocument(text, title: title);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            originalText: text,
            analysis: analysisResult['analysis'] ?? [],
            documentTitle: title ?? 'Scanned Property Agreement',
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
          ThemeToggleButton(),
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
                    ? _buildProcessingState(textPrimary, textSecondary, primaryAccent)
                    : SingleChildScrollView(
                        key: const ValueKey('main_form'),
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Scan or Input Document',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Upload a legal document for AI-powered verification and analysis.',
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
                                    label: 'Take a Photo',
                                    onPressed: () => _scanImage(ImageSource.camera),
                                    isPrimary: true,
                                    primaryAccent: primaryAccent,
                                    textPrimary: textPrimary,
                                  ),
                                  const SizedBox(height: 16),
                                  _HoverableButton(
                                    icon: Icons.image,
                                    label: 'Upload from Gallery',
                                    onPressed: () => _scanImage(ImageSource.gallery),
                                    isPrimary: false,
                                    primaryAccent: primaryAccent,
                                    textPrimary: textPrimary,
                                  ),
                                  const SizedBox(height: 16),
                                  _HoverableButton(
                                    icon: Icons.picture_as_pdf,
                                    label: 'Upload PDF',
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
                                  child: Text('OR', style: TextStyle(color: textSecondary, fontSize: 14)),
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
                                    'Document Content',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Paste or type the legal document here.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _FocusableTextField(
                                    controller: _textController,
                                    bgColor: bgColor,
                                    borderColor: borderColor,
                                    primaryAccent: primaryAccent,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                  const SizedBox(height: 24),
                                  _HoverableButton(
                                    icon: Icons.analytics_outlined,
                                    label: 'Analyze Document Text',
                                    onPressed: () {
                                      if (_textController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter or paste document text.', style: TextStyle(color: Colors.white)),
                                            backgroundColor: Color(0xFFD76C6C),
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

  Widget _buildProcessingState(Color textPrimary, Color textSecondary, Color primaryAccent) {
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
            'Please wait while we process your request.',
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
  final Color bgColor;
  final Color borderColor;
  final Color primaryAccent;
  final Color textPrimary;
  final Color textSecondary;

  const _FocusableTextField({
    required this.controller,
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
          hintText: 'Paste your legal document here...',
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
