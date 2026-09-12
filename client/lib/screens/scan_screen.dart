import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _ScanScreenState extends ConsumerState<ScanScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  
  bool _isProcessing = false;
  String _statusMessage = '';
  Offset _mousePos = const Offset(600, 300);

  // Animations
  AnimationController? _ambientController;
  Animation<double>? _pulseAnimation;
  AnimationController? _radarController;
  AnimationController? _entryController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  void _initControllers() {
    if (_entryController == null) {
      _entryController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryController!, curve: Curves.easeOutCubic),
      );
      _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController!, curve: Curves.easeOutCubic),
      );
      _entryController!.forward();
    }

    _ambientController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    _pulseAnimation ??= Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ambientController!, curve: Curves.easeInOutSine),
    );

    _radarController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void dispose() {
    _entryController?.dispose();
    _ambientController?.dispose();
    _radarController?.dispose();
    _textController.dispose();
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: const Color(0xFFEF4444),
      ));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error reading document: ${e.toString()}'),
        backgroundColor: const Color(0xFFEF4444),
      ));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _loadSampleAgreement() {
    _textController.text = '''BUILDER-BUYER AGREEMENT CLAUSES (EXCERPT)

1. HANDOVER TIMELINE & DELAY PENALTY:
The Developer agrees to offer possession of the Apartment within 36 months from the date of sanction of building plans. If the Developer fails to deliver possession within the stipulated time, the Developer shall pay compensation to the Allottee calculated at ₹5 per sq. ft. of super built-up area per month for the period of delay.

2. ALLOTTEE DEFAULT & CANCELLATION:
If the Allottee fails to pay any installment on the due date, interest at the rate of 18% per annum compounded monthly shall be payable by the Allottee on the delayed amount. If default persists beyond 30 days, the Developer reserves the right to cancel the allotment and forfeit 20% of the total consideration.

3. ESCROW ACCOUNT & PAYMENT MILESTONES:
All amounts paid by the Allottee shall be deposited into the general operating account of the Developer. The Developer reserves the right to alter construction milestones and demand progress payments accordingly.

4. SUPER AREA VS CARPET AREA VARIATION:
The final sale consideration is subject to variation based on architectural revisions. Any increase in the super built-up area up to 10% shall be billed additionally to the Allottee at prevailing market rates.

5. INDEMNITY & STATUTORY CLEARANCES:
The Developer represents that necessary zoning approvals are under application with local municipal bodies and environmental clearance will be obtained prior to occupancy certificate issuance.''';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _initControllers();
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    final bgGradientColors = isDark
        ? const [
            Color(0xFF162B43),
            Color(0xFF13253A),
            Color(0xFF101F31),
          ]
        : const [
            Color(0xFFFBF8EE),
            Color(0xFFF7F1D0),
            Color(0xFFF4EFE0),
          ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
      body: MouseRegion(
        onHover: (event) {
          if (isDesktop) {
            setState(() => _mousePos = event.position);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bgGradientColors,
            ),
          ),
          child: Stack(
            children: [
              // ==========================================
              // AMBIENT LIGHTING (MATCHING DASHBOARD)
              // ==========================================
              AnimatedBuilder(
                animation: _ambientController!,
                builder: (context, child) {
                  final pulse = _pulseAnimation?.value ?? 1.0;
                  return Stack(
                    children: [
                      // Orb 1: Top-Left Cyan Ambient Aurora
                      Positioned(
                        top: -140 + (25 * _ambientController!.value),
                        left: -120 + (20 * _ambientController!.value),
                        child: IgnorePointer(
                          child: Container(
                            width: 580 * pulse,
                            height: 580 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.13 : 0.08),
                                  const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.06 : 0.03),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Orb 2: Bottom-Right Gold Ambient Aurora
                      Positioned(
                        bottom: -100 + (30 * (1.0 - _ambientController!.value)),
                        right: -140,
                        child: IgnorePointer(
                          child: Container(
                            width: 620 * (2.0 - pulse),
                            height: 620 * (2.0 - pulse),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.09 : 0.05),
                                  const Color(0xFFFFDF8C).withValues(alpha: isDark ? 0.04 : 0.02),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Orb 3: Mouse-responsive Interactive Spotlight (Desktop)
                      if (isDesktop)
                        Positioned(
                          left: _mousePos.dx - 350,
                          top: _mousePos.dy - 350,
                          child: IgnorePointer(
                            child: Container(
                              width: 700,
                              height: 700,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.045 : 0.025),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // ==========================================
              // MAIN CONTENT
              // ==========================================
              SafeArea(
                child: Column(
                  children: [
                    // TOP BAR
                    _buildTopBar(context, isDark, loc),

                    // BODY CONTENT
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _isProcessing
                            ? _buildProcessingState(isDark, loc)
                            : FadeTransition(
                                opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                                child: SlideTransition(
                                  position: _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isDesktop ? 48.0 : 20.0,
                                      vertical: 16.0,
                                    ),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 1040),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // HERO HEADER
                                            _buildHeroHeader(isDark, loc, isDesktop),
                                            const SizedBox(height: 28),

                                            // 3 ACTION CARDS (CAMERA, GALLERY, PDF)
                                            _buildUploadOptionsGrid(isDark, loc, isDesktop),
                                            const SizedBox(height: 36),

                                            // STYLISH DIVIDER
                                            _buildSectionDivider(isDark, loc),
                                            const SizedBox(height: 32),

                                            // DIRECT TEXT INPUT STUDIO
                                            _buildDirectTextInputCard(isDark, loc, isDesktop),
                                            const SizedBox(height: 48),

                                            // SECURITY & PRIVACY FOOTER
                                            _buildSecurityBadge(isDark),
                                            const SizedBox(height: 32),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR
  // ==========================================
  Widget _buildTopBar(BuildContext context, bool isDark, LocaleNotifier loc) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left: Back button
          Align(
            alignment: Alignment.centerLeft,
            child: _HoverGlassButton(
              onTap: () => Navigator.of(context).pop(),
              isDark: isDark,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.translate('common.back'),
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center: True exact center alignment
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.35 : 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF38BDF8),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF38BDF8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI CONTRACT VERIFICATION STUDIO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF38BDF8),
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Profile Button
          const Align(
            alignment: Alignment.centerRight,
            child: UserProfileButton(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HERO HEADER
  // ==========================================
  Widget _buildHeroHeader(bool isDark, LocaleNotifier loc, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Eyebrow Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF91ADCD).withValues(alpha: isDark ? 0.16 : 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF91ADCD).withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFFC5A85E) : const Color(0xFF92764B),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFFC5A85E) : const Color(0xFF92764B)).withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'RERA COMPLIANCE • LEGAL OCR • RISK DETECTION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFC5A85E) : const Color(0xFF244A78),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Main Title
        Text(
          loc.translate('scan.title'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 32 : 24,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            loc.translate('scan.subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 14.5 : 13.5,
              height: 1.45,
              color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Supported Formats Pills
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFormatPill('Physical Deed Photos', Icons.camera_alt_outlined, const Color(0xFF38BDF8), isDark),
            _buildFormatPill('Gallery Scans & PNGs', Icons.image_outlined, const Color(0xFFC5A85E), isDark),
            _buildFormatPill('PDF Agreements', Icons.picture_as_pdf_outlined, const Color(0xFF38BDF8), isDark),
            _buildFormatPill('Direct Clause Paste', Icons.notes_outlined, const Color(0xFF10B981), isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatPill(String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFD6DFEC) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UPLOAD OPTIONS GRID (CAMERA, GALLERY, PDF)
  // ==========================================
  Widget _buildUploadOptionsGrid(bool isDark, LocaleNotifier loc, bool isDesktop) {
    final uploadCards = [
      _UploadActionCardData(
        title: loc.translate('scan.takePhoto'),
        description: 'Instant OCR scanning of physical deed pages via camera.',
        icon: Icons.camera_enhance_rounded,
        accentColor: const Color(0xFF38BDF8),
        badgeText: 'CAMERA SCAN',
        onTap: () => _scanImage(ImageSource.camera),
      ),
      _UploadActionCardData(
        title: loc.translate('scan.uploadFromGallery'),
        description: 'Upload high-resolution document photos or screenshots.',
        icon: Icons.photo_library_outlined,
        accentColor: const Color(0xFFC5A85E),
        badgeText: 'PHOTO GALLERY',
        onTap: () => _scanImage(ImageSource.gallery),
      ),
      _UploadActionCardData(
        title: loc.translate('scan.uploadPdf'),
        description: 'Upload multi-page PDF agreements & registry documents.',
        icon: Icons.picture_as_pdf_outlined,
        accentColor: const Color(0xFF38BDF8),
        badgeText: 'PDF DOCUMENT',
        onTap: _scanPdf,
      ),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: uploadCards.map((card) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _UploadActionCard(
                data: card,
                isDark: isDark,
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Column(
        children: uploadCards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: _UploadActionCard(
              data: card,
              isDark: isDark,
            ),
          );
        }).toList(),
      );
    }
  }

  // ==========================================
  // SECTION DIVIDER
  // ==========================================
  Widget _buildSectionDivider(bool isDark, LocaleNotifier loc) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  (isDark ? const Color(0xFF334356) : const Color(0xFFD6CEBE)).withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16263B) : const Color(0xFFEBE3D3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFFC5A85E)).withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              '${loc.translate('common.or')} PASTE DOCUMENT CLAUSES',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF91ADCD) : const Color(0xFF63748A),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? const Color(0xFF334356) : const Color(0xFFD6CEBE)).withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DIRECT TEXT INPUT STUDIO
  // ==========================================
  Widget _buildDirectTextInputCard(bool isDark, LocaleNotifier loc, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  const Color(0xFF334356).withValues(alpha: 0.4),
                  const Color(0xFF16263B).withValues(alpha: 0.2),
                ]
              : [
                  const Color(0xFFE4DDD0),
                  const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  const Color(0xFFE4DDD0),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2), // Gradient border
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1B2F48).withValues(alpha: 0.95)
              : const Color(0xFFFBF8EE).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20.8),
        ),
        padding: EdgeInsets.all(isDesktop ? 28.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Action Helpers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('scan.documentContent'),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                              ),
                            ),
                            Text(
                              loc.translate('scan.pastePrompt'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sample Agreement Quick-Load Helper
                TextButton.icon(
                  onPressed: _loadSampleAgreement,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFC5A85E)),
                  label: Text(
                    'Load Sample Agreement',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC5A85E),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFC5A85E).withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: const Color(0xFFC5A85E).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Styled TextField Studio
            _StudioTextField(
              controller: _textController,
              hintText: loc.translate('scan.pasteHint'),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Bottom CTA Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Clear button
                if (_textController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _textController.clear()),
                    icon: const Icon(Icons.clear_rounded, size: 14, color: Color(0xFFEF4444)),
                    label: Text(
                      'Clear',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Primary Analyze CTA Button
                _AnalyzeSubmitButton(
                  label: loc.translate('scan.analyzeBtn'),
                  onPressed: () {
                    final text = _textController.text.trim();
                    if (text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            loc.translate('scan.emptyError'),
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }
                    _analyzeText(text);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECURITY & PRIVACY FOOTER
  // ==========================================
  Widget _buildSecurityBadge(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 6),
        Text(
          'End-to-End Encrypted • Legal Documents Are Processed Confidentially Under Indian Privacy Norms',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PROCESSING / ANALYZING STATE (AI RADAR)
  // ==========================================
  Widget _buildProcessingState(bool isDark, LocaleNotifier loc) {
    return Center(
      key: const ValueKey('processing_state'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Holographic Scanning Radar Orb
            AnimatedBuilder(
              animation: _radarController!,
              builder: (context, child) {
                final radarVal = _radarController!.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer expanding ripple
                    Container(
                      width: 140 + (30 * radarVal),
                      height: 140 + (30 * radarVal),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: (1.0 - radarVal) * 0.4),
                          width: 2,
                        ),
                      ),
                    ),

                    // Middle pulse ring
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Central Icon
                    const Icon(
                      Icons.document_scanner_rounded,
                      size: 48,
                      color: Color(0xFF38BDF8),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 36),

            // Status message
            Text(
              _statusMessage.isNotEmpty ? _statusMessage : loc.translate('scan.processingRisk'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              loc.translate('scan.pleaseWait'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
              ),
            ),
            const SizedBox(height: 24),

            // AI Progress Indeterminate Bar
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFF1E3552),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// UPLOAD ACTION CARD MODEL & WIDGET
// ==========================================
class _UploadActionCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String badgeText;
  final VoidCallback onTap;

  _UploadActionCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.badgeText,
    required this.onTap,
  });
}

class _UploadActionCard extends StatefulWidget {
  final _UploadActionCardData data;
  final bool isDark;

  const _UploadActionCard({
    required this.data,
    required this.isDark,
  });

  @override
  State<_UploadActionCard> createState() => _UploadActionCardState();
}

class _UploadActionCardState extends State<_UploadActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.data;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedSlide(
          offset: _isHovered ? const Offset(0.0, -0.03) : Offset.zero,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isHovered
                    ? [
                        item.accentColor.withValues(alpha: 0.7),
                        item.accentColor.withValues(alpha: 0.35),
                        const Color(0xFF16263B).withValues(alpha: 0.6),
                      ]
                    : (isDark
                        ? [
                            item.accentColor.withValues(alpha: 0.3),
                            const Color(0xFF334356).withValues(alpha: 0.4),
                            const Color(0xFF16263B).withValues(alpha: 0.2),
                          ]
                        : [
                            const Color(0xFFE4DDD0),
                            item.accentColor.withValues(alpha: 0.25),
                            const Color(0xFFE4DDD0),
                          ]),
              ),
              boxShadow: [
                BoxShadow(
                  color: item.accentColor.withValues(alpha: _isHovered ? (isDark ? 0.3 : 0.12) : 0.0),
                  blurRadius: _isHovered ? 24 : 0,
                  spreadRadius: _isHovered ? 1 : 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? (_isHovered ? 0.4 : 0.22) : (_isHovered ? 0.08 : 0.03)),
                  blurRadius: _isHovered ? 18 : 8,
                  offset: Offset(0, _isHovered ? 6 : 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.2), // Gradient border
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? (_isHovered ? const Color(0xFF1E3552).withValues(alpha: 0.96) : const Color(0xFF182A40).withValues(alpha: 0.94))
                    : (_isHovered ? const Color(0xFFFAF6EB).withValues(alpha: 0.98) : const Color(0xFFFDFBF7).withValues(alpha: 0.96)),
                borderRadius: BorderRadius.circular(18.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Icon Container + Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: _isHovered ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(alpha: _isHovered ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.accentColor.withValues(alpha: _isHovered ? 0.55 : 0.25),
                                ),
                                boxShadow: [
                                  if (_isHovered)
                                    BoxShadow(
                                      color: item.accentColor.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                    ),
                                ],
                              ),
                              child: Icon(item.icon, color: item.accentColor, size: 22),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: item.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.accentColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              item.badgeText,
                              style: GoogleFonts.inter(
                                color: item.accentColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        item.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Bottom Action Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select & Upload',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: item.accentColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      AnimatedSlide(
                        offset: _isHovered ? const Offset(0.3, 0) : Offset.zero,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: item.accentColor,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// STUDIO TEXTFIELD
// ==========================================
class _StudioTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool isDark;

  const _StudioTextField({
    required this.controller,
    this.hintText,
    required this.isDark,
  });

  @override
  State<_StudioTextField> createState() => _StudioTextFieldState();
}

class _StudioTextFieldState extends State<_StudioTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132337) : const Color(0xFFF7F1D0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused
              ? const Color(0xFF38BDF8)
              : (isDark ? const Color(0xFF2B415C) : const Color(0xFFD6CEBE)),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        minLines: 8,
        maxLines: 16,
        style: GoogleFonts.inter(
          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF1E293B),
          fontSize: 14,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Paste agreement text here...',
          hintStyle: GoogleFonts.inter(
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontSize: 13.5,
          ),
          filled: false,
          contentPadding: const EdgeInsets.all(18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// ==========================================
// ANALYZE SUBMIT BUTTON (GLOWING GRADIENT CTA)
// ==========================================
class _AnalyzeSubmitButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _AnalyzeSubmitButton({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_AnalyzeSubmitButton> createState() => _AnalyzeSubmitButtonState();
}

class _AnalyzeSubmitButtonState extends State<_AnalyzeSubmitButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF38BDF8),
                  Color(0xFF2563EB),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: _isHovered ? 0.5 : 0.3),
                  blurRadius: _isHovered ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedSlide(
                  offset: _isHovered ? const Offset(0.25, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HOVER GLASS BUTTON HELPER
// ==========================================
class _HoverGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;

  const _HoverGlassButton({
    required this.child,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_HoverGlassButton> createState() => _HoverGlassButtonState();
}

class _HoverGlassButtonState extends State<_HoverGlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark ? const Color(0xFF223A58) : const Color(0xFFF4EFE0))
                : (widget.isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.8) : const Color(0xFFFBF8EE).withValues(alpha: 0.9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFFC5A85E)).withValues(alpha: _isHovered ? 0.5 : 0.2),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
