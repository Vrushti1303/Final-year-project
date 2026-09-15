import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English', 'English'),
  hindi('hi', 'Hindi', 'हिंदी');

  final String code;
  final String englishName;
  final String nativeName;

  const AppLanguage(this.code, this.englishName, this.nativeName);
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<AppLanguage> {
  static const _langPrefKey = 'app_language_preference';

  LocaleNotifier() : super(AppLanguage.english) {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_langPrefKey);
    if (code != null) {
      final matched = AppLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLanguage.english,
      );
      state = matched;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langPrefKey, language.code);
  }

  String translate(String key, [Map<String, String>? params]) {
    final langCode = state.code;
    String raw = key;

    if (_translations.containsKey(key) && _translations[key]!.containsKey(langCode)) {
      raw = _translations[key]![langCode]!;
    } else if (_translations.containsKey(key) && _translations[key]!.containsKey('en')) {
      raw = _translations[key]!['en']!;
    }

    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramVal) {
        raw = raw.replaceAll('{$paramKey}', paramVal);
      });
    }

    return raw;
  }
}

extension TranslationExtension on BuildContext {
  String tr(String key, WidgetRef ref, [Map<String, String>? params]) {
    ref.watch(localeProvider);
    return ref.read(localeProvider.notifier).translate(key, params);
  }
}

// Master Namespaced Translation Dictionary
// 'en' is 100% the verbatim source of truth from existing code.
// 'hi' is accurate and natural Hindi translation.
final Map<String, Map<String, String>> _translations = {
  // Common Actions
  'common.appName': {'en': 'LawBuddy', 'hi': 'LawBuddy'},
  'common.appSubtitle': {'en': 'AI Property Legal Assistant', 'hi': 'एआई संपत्ति कानूनी सहायक'},
  'common.cancel': {'en': 'Cancel', 'hi': 'रद्द करें'},
  'common.delete': {'en': 'Delete', 'hi': 'हटाएं'},
  'common.retry': {'en': 'Retry', 'hi': 'पुनः प्रयास करें'},
  'common.close': {'en': 'Close', 'hi': 'बंद करें'},
  'common.save': {'en': 'Save', 'hi': 'सहेजें'},
  'common.add': {'en': 'Add', 'hi': 'जोड़ें'},
  'common.or': {'en': 'OR', 'hi': 'या'},
  'common.understood': {'en': 'Understood', 'hi': 'समझ गया'},
  'common.gotIt': {'en': 'Got it', 'hi': 'समझ गया'},
  'common.viewDetails': {'en': 'View Details', 'hi': 'विवरण देखें'},
  'common.explore': {'en': 'Explore →', 'hi': 'देखें →'},
  'common.live': {'en': 'Live', 'hi': 'लाइव'},
  'common.back': {'en': 'Back', 'hi': 'पीछे'},
  'common.backToHome': {'en': 'Back to Home', 'hi': 'होम पर वापस जाएं'},
  'common.settings': {'en': 'Settings', 'hi': 'सेटिंग्स'},
  'common.language': {'en': 'Language', 'hi': 'भाषा'},
  'common.english': {'en': 'English', 'hi': 'English'},
  'common.hindi': {'en': 'हिंदी', 'hi': 'हिंदी'},
  'common.theme': {'en': 'Theme', 'hi': 'थीम'},
  'common.appearance': {'en': 'Theme', 'hi': 'थीम'},
  'common.themeAppearance': {'en': 'Theme & Appearance', 'hi': 'थीम और स्वरूप'},
  'common.chooseAppearance': {'en': 'Choose how LawBuddy looks', 'hi': 'चुनें कि LawBuddy कैसा दिखे'},
  'common.light': {'en': 'Light', 'hi': 'लाइट'},
  'common.dark': {'en': 'Dark', 'hi': 'डार्क'},
  'common.system': {'en': 'System', 'hi': 'सिस्टम'},
  'common.profile': {'en': 'Profile', 'hi': 'प्रोफाइल'},
  'common.accountDetails': {'en': 'Account Details', 'hi': 'खाता विवरण'},
  'common.fullName': {'en': 'Full Name', 'hi': 'पूरा नाम'},
  'common.emailAddress': {'en': 'Email Address', 'hi': 'ईमेल पता'},
  'common.signOut': {'en': 'Sign Out', 'hi': 'साइन आउट'},
  'common.signOutConfirm': {
    'en': 'Are you sure you want to sign out of your LawBuddy session?',
    'hi': 'क्या आप अपने LawBuddy सत्र से साइन आउट करना चाहते हैं?',
  },

  // Navigation & Branding
  'brand.name': {'en': 'LawBuddy', 'hi': 'LawBuddy'},
  'brand.tagline': {'en': 'LEGALTECH AI', 'hi': 'लीगलटेक एआई'},
  'brand.subtitle': {'en': 'AI Property Legal Assistant', 'hi': 'एआई संपत्ति कानूनी सहायक'},

  // Home Screen
  'home.goodMorning': {'en': 'Good Morning', 'hi': 'शुभ प्रभात'},
  'home.goodAfternoon': {'en': 'Good Afternoon', 'hi': 'शुभ दोपहर'},
  'home.goodEvening': {'en': 'Good Evening', 'hi': 'शुभ संध्या'},
  'home.greeting': {'en': '{greeting}, {name} 👋', 'hi': '{greeting}, {name} 👋'},
  'home.quickActions': {'en': 'Quick Actions', 'hi': 'त्वरित कार्य'},
  'home.quickActionsSubtitle': {
    'en': 'Select a tool to manage your property legal workflow',
    'hi': 'अपने संपत्ति कानूनी कार्यप्रवाह को प्रबंधित करने के लिए एक उपकरण चुनें',
  },
  'home.scanAgreement': {'en': 'Scan Agreement', 'hi': 'समझौता स्कैन करें'},
  'home.scanAgreementDesc': {'en': 'Analyze documents for legal risk', 'hi': 'कानूनी जोखिम के लिए दस्तावेजों का विश्लेषण करें'},
  'home.legalChatbot': {'en': 'Legal Chatbot', 'hi': 'कानूनी चैटबॉट'},
  'home.legalChatbotDesc': {'en': 'Ask property & RERA questions', 'hi': 'संपत्ति और रेरा पर प्रश्न पूछें'},
  'home.propertyChecklist': {'en': 'Property Checklist', 'hi': 'संपत्ति चेकलिस्ट'},
  'home.stampDutyCalculator': {'en': 'Stamp Duty Calculator', 'hi': 'स्टाम्प शुल्क कैलकुलेटर'},
  'home.stampDutyCalculatorDesc': {'en': 'Calculate stamp duty & registration charges', 'hi': 'स्टाम्प शुल्क और पंजीकरण शुल्क की गणना करें'},
  'home.activeChecklistsZero': {'en': '0 Active Checklists', 'hi': '0 सक्रिय चेकलिस्ट'},
  'home.activeChecklistsBadge': {'en': '{count} Active {unit}', 'hi': '{count} सक्रिय {unit}'},
  'home.checklistUnitSingular': {'en': 'Checklist', 'hi': 'चेकलिस्ट'},
  'home.checklistUnitPlural': {'en': 'Checklists', 'hi': 'चेकलिस्ट'},
  'home.checklistZeroTasks': {'en': '0 tasks • Tap to generate property guides', 'hi': '0 कार्य • संपत्ति गाइड बनाने के लिए टैप करें'},
  'home.checklistZeroCompleted': {'en': '0 tasks completed • Tap to view guides', 'hi': '0 कार्य पूर्ण • गाइड देखने के लिए टैप करें'},
  'home.checklistTasksProgress': {
    'en': '{completed} of {total} tasks completed across {count} {unit}',
    'hi': '{count} {unit} में {total} में से {completed} कार्य पूर्ण',
  },
  'home.guideUnitSingular': {'en': 'guide', 'hi': 'गाइड'},
  'home.guideUnitPlural': {'en': 'guides', 'hi': 'गाइड'},
  'home.recentDocuments': {'en': 'Recent Documents', 'hi': 'हाल के दस्तावेज़'},
  'home.viewAll': {'en': 'View All ({count})', 'hi': 'सभी देखें ({count})'},
  'home.noAgreementsScanned': {'en': 'No agreements scanned yet', 'hi': 'अभी तक कोई समझौता स्कैन नहीं किया गया है'},
  'home.uploadOrScanAgreement': {
    'en': 'Upload or scan your property agreement for AI risk assessment.',
    'hi': 'एआई जोखिम मूल्यांकन के लिए अपने संपत्ति समझौते को अपलोड या स्कैन करें।',
  },
  'home.scanOrUploadAgreementBtn': {'en': 'Scan or Upload Agreement', 'hi': 'समझौता स्कैन या अपलोड करें'},
  'home.latestLegalUpdates': {'en': 'Latest Legal Updates', 'hi': 'नवीनतम कानूनी अपडेट'},
  'home.noLegalUpdates': {'en': 'No legal updates available at this moment', 'hi': 'इस समय कोई कानूनी अपडेट उपलब्ध नहीं है'},
  'home.reraAlert': {'en': 'RERA ALERT', 'hi': 'रेरा अलर्ट'},
  'home.reraAdvisoryDetails': {'en': 'RERA Advisory Details', 'hi': 'रेरा सलाह विवरण'},
  'home.reraStatutoryNote': {
    'en': 'Under Section 18 of the RERA Act, promoter default in handover or escrow accounting mandates strict statutory interest compensation at SBI MCLR + 2%.',
    'hi': 'रेरा अधिनियम की धारा 18 के तहत, हैंडओवर या एस्क्रो अकाउंटिंग में प्रमोटर डिफॉल्ट होने पर SBI MCLR + 2% पर वैधानिक ब्याज मुआवजा अनिवार्य है।',
  },
  'home.askLegalAi': {'en': 'Ask Legal AI', 'hi': 'कानूनी एआई से पूछें'},
  'home.needLegalHelp': {'en': 'Need Legal Help? Ask LawBuddy', 'hi': 'कानूनी मदद चाहिए? LawBuddy से पूछें'},
  'home.overviewTitle': {'en': 'LEGAL PORTFOLIO OVERVIEW', 'hi': 'कानूनी पोर्टफोलियो अवलोकन'},
  'home.totalScannedDocs': {'en': 'Documents Analyzed', 'hi': 'विश्लेषण किए गए दस्तावेज़'},
  'home.totalScannedDocsSub': {'en': 'Agreements in workspace', 'hi': 'कार्यक्षेत्र में समझौते'},
  'home.highRiskCount': {'en': 'Risk Flags Identified', 'hi': 'पहचाने गए जोखिम'},
  'home.highRiskCountSub': {'en': 'Agreements requiring review', 'hi': 'समीक्षा आवश्यक समझौते'},
  'home.noHighRisks': {'en': 'No critical risk flags', 'hi': 'कोई गंभीर जोखिम नहीं'},
  'home.dueDiligenceProgress': {'en': 'Due Diligence Tasks', 'hi': 'जांच कार्य प्रगति'},
  'home.activeChecklists': {'en': 'Active Checklists', 'hi': 'सक्रिय चेकलिस्ट'},
  'home.systemOnline': {'en': 'Legal Engine Online', 'hi': 'कानूनी इंजन सक्रिय'},
  'home.primaryScanSpotlight': {'en': 'INSTANT AI ASSESSMENT', 'hi': 'त्वरित एआई मूल्यांकन'},
  'home.primaryScanCta': {'en': 'Start New Scan', 'hi': 'नया स्कैन शुरू करें'},

  'home.workspaceSubtitle': {'en': 'Your property legal workspace', 'hi': 'आपका संपत्ति कानूनी कार्यक्षेत्र'},
  'home.latestAnalysisReview': {'en': 'Latest Document Analysis', 'hi': 'नवीनतम दस्तावेज़ विश्लेषण'},
  'home.latestAnalysisSub': {'en': 'Real-time risk assessment & clause audit', 'hi': 'वास्तविक समय जोखिम मूल्यांकन और खंड ऑडिट'},
  'home.viewFullAnalysis': {'en': 'View Full Analysis', 'hi': 'पूर्ण विश्लेषण देखें'},
  'home.riskDistribution': {'en': 'Legal Risk Breakdown', 'hi': 'कानूनी जोखिम विवरण'},
  'home.riskDistributionSub': {'en': 'Clause severity across analyzed agreements', 'hi': 'विश्लेषण किए गए समझौतों में खंड गंभीरता'},
  'home.highRiskLabel': {'en': 'High Risk', 'hi': 'उच्च जोखिम'},
  'home.mediumRiskLabel': {'en': 'Caution', 'hi': 'सावधानी'},
  'home.lowRiskLabel': {'en': 'Compliant', 'hi': 'अनुपालन'},
  'home.dueDiligenceSection': {'en': 'Due Diligence Checklist', 'hi': 'उचित तत्परता चेकलिस्ट'},
  'home.dueDiligenceSub': {'en': 'Mandatory property transaction verification', 'hi': 'अनिवार्य संपत्ति लेनदेन सत्यापन'},
  'home.openChecklist': {'en': 'Open Checklist', 'hi': 'चेकलिस्ट खोलें'},
  'home.recentActivity': {'en': 'Recent Workspace Activity', 'hi': 'हालिया कार्यक्षेत्र गतिविधि'},
  'home.recentActivitySub': {'en': 'Audit trail of scans and verification progress', 'hi': 'स्कैन और सत्यापन प्रगति का ऑडिट ट्रेल'},
  'home.noActivityYet': {'en': 'No recent activity recorded yet', 'hi': 'अभी तक कोई हालिया गतिविधि दर्ज नहीं की गई है'},
  'home.legalIntelligence': {'en': 'Legal Intelligence & News', 'hi': 'कानूनी जानकारी और समाचार'},
  'home.legalIntelligenceSub': {'en': 'Real estate statutory alerts & circulars', 'hi': 'अचल संपत्ति वैधानिक अलर्ट और परिपत्र'},
  'home.reraAwarenessTitle': {'en': 'RERA Statutory Notice', 'hi': 'रेरा वैधानिक सूचना'},
  'home.reraAwarenessSub': {'en': 'Mandatory statutory protections under RERA', 'hi': 'रेरा के तहत अनिवार्य वैधानिक सुरक्षा'},

  // Sidebar Navigation Categories & Items
  'sidebar.overview': {'en': 'OVERVIEW', 'hi': 'अवलोकन'},
  'sidebar.workspace': {'en': 'WORKSPACE', 'hi': 'कार्यक्षेत्र'},
  'sidebar.legalTools': {'en': 'LEGAL TOOLS', 'hi': 'कानूनी उपकरण'},
  'sidebar.legalInfo': {'en': 'LEGAL INFORMATION', 'hi': 'कानूनी जानकारी'},
  'sidebar.main': {'en': 'MAIN', 'hi': 'मुख्य'},
  'sidebar.dashboard': {'en': 'Dashboard', 'hi': 'डैशबोर्ड'},
  'sidebar.documents': {'en': 'Documents', 'hi': 'दस्तावेज़'},
  'sidebar.riskAnalysis': {'en': 'Risk Analysis', 'hi': 'जोखिम विश्लेषण'},
  'sidebar.checklists': {'en': 'Checklists', 'hi': 'चेकलिस्ट'},
  'sidebar.reraCompliance': {'en': 'RERA & Compliance', 'hi': 'रेरा और अनुपालन'},
  'sidebar.legalAi': {'en': 'Legal AI', 'hi': 'कानूनी एआई'},
  'sidebar.stampDuty': {'en': 'Stamp Duty Calculator', 'hi': 'स्टाम्प शुल्क कैलकुलेटर'},
  'sidebar.settings': {'en': 'Settings', 'hi': 'सेटिंग्स'},
  'sidebar.profile': {'en': 'Profile', 'hi': 'प्रोफ़ाइल'},

  // Scan Screen
  'scan.title': {'en': 'Scan or Input Document', 'hi': 'दस्तावेज़ स्कैन या दर्ज करें'},
  'scan.subtitle': {
    'en': 'Upload a legal document for AI-powered verification and analysis.',
    'hi': 'एआई-संचालित सत्यापन और विश्लेषण के लिए एक कानूनी दस्तावेज़ अपलोड करें।',
  },
  'scan.takePhoto': {'en': 'Take a Photo', 'hi': 'फोटो खींचें'},
  'scan.uploadGallery': {'en': 'Upload from Gallery', 'hi': 'गैलरी से अपलोड करें'},
  'scan.uploadFromGallery': {'en': 'Upload from Gallery', 'hi': 'गैलरी से अपलोड करें'},
  'scan.uploadPdf': {'en': 'Upload PDF', 'hi': 'पीडीएफ अपलोड करें'},
  'scan.docContent': {'en': 'Document Content', 'hi': 'दस्तावेज़ सामग्री'},
  'scan.documentContent': {'en': 'Document Content', 'hi': 'दस्तावेज़ सामग्री'},
  'scan.pastePrompt': {'en': 'Paste or type the legal document here.', 'hi': 'कानूनी दस्तावेज़ को यहाँ पेस्ट या टाइप करें।'},
  'scan.hint': {'en': 'Paste your legal document here...', 'hi': 'अपना कानूनी दस्तावेज़ यहाँ पेस्ट करें...'},
  'scan.pasteHint': {'en': 'Paste your legal document here...', 'hi': 'अपना कानूनी दस्तावेज़ यहाँ पेस्ट करें...'},
  'scan.analyzeText': {'en': 'Analyze Document Text', 'hi': 'दस्तावेज़ टेक्स्ट का विश्लेषण करें'},
  'scan.analyzeBtn': {'en': 'Analyze Document Text', 'hi': 'दस्तावेज़ टेक्स्ट का विश्लेषण करें'},
  'scan.emptyError': {'en': 'Please enter or paste document text.', 'hi': 'कृपया दस्तावेज़ टेक्स्ट दर्ज या पेस्ट करें।'},
  'scan.analyzingImage': {'en': 'Analyzing image document...', 'hi': 'छवि दस्तावेज़ का विश्लेषण किया जा रहा है...'},
  'scan.processingPhoto': {'en': 'Analyzing image document...', 'hi': 'छवि दस्तावेज़ का विश्लेषण किया जा रहा है...'},
  'scan.readingDoc': {'en': 'Reading document...', 'hi': 'दस्तावेज़ पढ़ा जा रहा है...'},
  'scan.processingPdf': {'en': 'Reading document...', 'hi': 'दस्तावेज़ पढ़ा जा रहा है...'},
  'scan.analyzingVision': {'en': 'Analyzing scanned PDF via AI vision...', 'hi': 'एआई विज़न के माध्यम से स्कैन किए गए पीडीएफ का विश्लेषण किया जा रहा है...'},
  'scan.processingPdfVision': {'en': 'Analyzing scanned PDF via AI vision...', 'hi': 'एआई विज़न के माध्यम से स्कैन किए गए पीडीएफ का विश्लेषण किया जा रहा है...'},
  'scan.analyzingRisks': {'en': 'Analyzing for risks...', 'hi': 'जोखिमों का विश्लेषण किया जा रहा है...'},
  'scan.processingRisk': {'en': 'Analyzing for risks...', 'hi': 'जोखिमों का विश्लेषण किया जा रहा है...'},
  'scan.pleaseWait': {'en': 'Please wait while we process your request.', 'hi': 'कृपया प्रतीक्षा करें जब तक हम आपके अनुरोध को संसाधित करते हैं।'},

  // Chat Screen
  'chat.title': {'en': 'Legal AI Assistant', 'hi': 'कानूनी एआई सहायक'},
  'chat.subtitle': {'en': 'Indian Property, RERA & Contract Specialist', 'hi': 'भारतीय संपत्ति, रेरा और अनुबंध विशेषज्ञ'},
  'chat.chatHistory': {'en': 'Chat History', 'hi': 'चैट इतिहास'},
  'chat.newChat': {'en': 'New Chat', 'hi': 'नई बातचीत'},
  'chat.savedConsultations': {'en': 'Saved Consultations', 'hi': 'सहेजी गई बातचीत'},
  'chat.sessionsStored': {'en': '{count} sessions stored in Atlas', 'hi': 'Atlas में {count} सत्र संग्रहीत हैं'},
  'chat.searchConsultations': {'en': 'Search consultations...', 'hi': 'बातचीत खोजें...'},
  'chat.startNewConsultation': {'en': 'Start New Consultation', 'hi': 'नई बातचीत शुरू करें'},
  'chat.noMatchingConversations': {'en': 'No matching conversations', 'hi': 'कोई मिलती-जुलती बातचीत नहीं मिली'},
  'chat.noSavedConversations': {'en': 'No saved conversations yet', 'hi': 'अभी तक कोई सहेजी गई बातचीत नहीं है'},
  'chat.turnsCount': {'en': '{count} turns', 'hi': '{count} संदेश'},
  'chat.deleteTitle': {'en': 'Delete Conversation?', 'hi': 'बातचीत हटाएं?'},
  'chat.deleteContent': {
    'en': 'This conversation will be permanently removed from your saved chat history.',
    'hi': 'यह बातचीत आपके सहेजे गए चैट इतिहास से स्थायी रूप से हटा दी जाएगी।',
  },
  'chat.deletedToast': {'en': 'Conversation deleted', 'hi': 'बातचीत हटा दी गई'},
  'chat.heroHeadline': {'en': 'Indian Property & RERA Legal AI', 'hi': 'भारतीय संपत्ति और रेरा कानूनी एआई'},
  'chat.heroSubtitle': {
    'en': 'Instant legal analysis, agreement scrutiny, and RERA rights guidance for homebuyers, landlords & tenants.',
    'hi': 'घर खरीदारों, मकान मालिकों और किरायेदारों के लिए त्वरित कानूनी विश्लेषण, अनुबंध जांच और रेरा अधिकार मार्गदर्शन।',
  },
  'chat.tagRera': {'en': 'RERA Compliant', 'hi': 'रेरा अनुपालन'},
  'chat.tagTenancy': {'en': 'Model Tenancy Act', 'hi': 'मॉडल टेनेंसी एक्ट'},
  'chat.tagTransfer': {'en': 'Transfer of Property Act', 'hi': 'ट्रांसफर ऑफ प्रॉपर्टी एक्ट'},
  'chat.card1Cat': {'en': 'PROPERTY AGREEMENTS', 'hi': 'संपत्ति समझौते'},
  'chat.card1Title': {'en': 'Review Agreement Clauses', 'hi': 'समझौता खंडों की समीक्षा करें'},
  'chat.card1Desc': {
    'en': 'Scan lease or sale deed terms for hidden liabilities, lock-ins, and risky clauses.',
    'hi': 'छिपी हुई देनदारियों, लॉक-इन और जोखिम भरे खंडों के लिए पट्टे या बिक्री विलेख की शर्तों की जांच करें।',
  },
  'chat.card2Cat': {'en': 'RERA COMPLIANCE', 'hi': 'रेरा अनुपालन'},
  'chat.card2Title': {'en': 'RERA Rights & Delays', 'hi': 'रेरा अधिकार और देरी'},
  'chat.card2Desc': {
    'en': 'Understand builder handover delays, Section 18 interest compensation, and escrow norms.',
    'hi': 'बिल्डर हैंडओवर में देरी, धारा 18 ब्याज मुआवजा और एस्क्रो मानदंडों को समझें।',
  },
  'chat.card3Cat': {'en': 'LEGAL DRAFTING', 'hi': 'कानूनी प्रारूपण'},
  'chat.card3Title': {'en': 'Draft Tenancy & NOC', 'hi': 'किराया अनुबंध और एनओसी का मसौदा तैयार करें'},
  'chat.card3Desc': {
    'en': 'Generate standard residential lease, sale agreement, or NOC templates with statutory clauses.',
    'hi': 'वैधानिक खंडों के साथ मानक आवासीय पट्टा, बिक्री समझौता या एनओसी टेम्पलेट तैयार करें।',
  },
  'chat.card4Cat': {'en': 'STAMP DUTY & TITLE', 'hi': 'स्टाम्प शुल्क और शीर्षक'},
  'chat.card4Title': {'en': 'Stamp Duty & Registry', 'hi': 'स्टाम्प शुल्क और रजिस्ट्री'},
  'chat.card4Desc': {
    'en': 'Mandatory document checklist, encumbrance certificate, and state registration guidelines.',
    'hi': 'अनिवार्य दस्तावेज़ चेकलिस्ट, भार प्रमाणपत्र और राज्य पंजीकरण दिशानिर्देश।',
  },
  'chat.askLegalAi': {'en': 'Ask Legal AI', 'hi': 'कानूनी एआई से पूछें'},
  'chat.chip1': {'en': 'Delay penalty interest rate', 'hi': 'देरी जुर्माना ब्याज दर'},
  'chat.chip2': {'en': 'Carpet vs super built-up area', 'hi': 'कारपेट बनाम सुपर बिल्ट-अप क्षेत्र'},
  'chat.chip3': {'en': 'Security deposit refund rules', 'hi': 'सुरक्षा जमा वापसी नियम'},
  'chat.chip4': {'en': '70% builder escrow rule', 'hi': '70% बिल्डर एस्क्रो नियम'},
  'chat.disclaimer': {
    'en': 'Educational assistance for Indian Property Law. Consult a registered advocate for court representation.',
    'hi': 'भारतीय संपत्ति कानून के लिए शैक्षिक सहायता। अदालत में प्रतिनिधित्व के लिए एक पंजीकृत वकील से परामर्श करें।',
  },
  'chat.inputHint': {
    'en': 'Ask about property laws, RERA Section 18, delay remedies, or lease drafts...',
    'hi': 'संपत्ति कानूनों, रेरा धारा 18, देरी के उपायों या पट्टा मसौदे के बारे में पूछें...',
  },
  'chat.typingTitle': {'en': 'Legal AI is analyzing your query', 'hi': 'कानूनी एआई आपके प्रश्न का विश्लेषण कर रहा है'},
  'chat.typingSubtitle': {
    'en': 'Referencing Indian Property Laws & RERA database...',
    'hi': 'भारतीय संपत्ति कानूनों और रेरा डेटाबेस का संदर्भ लिया जा रहा है...',
  },
  'chat.rateLimitMessage': {
    'en': '⚠️ Our servers are currently busy due to high demand. Please wait 15 seconds before trying again.',
    'hi': '⚠️ उच्च मांग के कारण हमारे सर्वर वर्तमान में व्यस्त हैं। कृपया पुनः प्रयास करने से पहले 15 सेकंड प्रतीक्षा करें।',
  },
  'chat.rateLimitToast': {
    'en': 'Rate limit reached. Please wait a moment.',
    'hi': 'दर सीमा पूरी हो गई। कृपया कुछ क्षण प्रतीक्षा करें।',
  },

  // Stamp Duty Calculator Screen
  'calc.title': {'en': 'Stamp Duty Calculator', 'hi': 'स्टाम्प शुल्क कैलकुलेटर'},
  'calc.screenTitle': {'en': 'Stamp Duty Calculator', 'hi': 'स्टाम्प शुल्क कैलकुलेटर'},
  'calc.subtitle': {
    'en': 'Calculate estimated stamp duty and registration charges for your property transaction.',
    'hi': 'अपने संपत्ति लेनदेन के लिए अनुमानित स्टाम्प शुल्क और पंजीकरण शुल्क की गणना करें।',
  },
  'calc.screenSubtitle': {
    'en': 'Calculate estimated stamp duty and registration charges for your property transaction.',
    'hi': 'अपने संपत्ति लेनदेन के लिए अनुमानित स्टाम्प शुल्क और पंजीकरण शुल्क की गणना करें।',
  },
  'calc.cardTitle': {
    'en': 'Calculate Stamp Duty & Registration Charges',
    'hi': 'स्टाम्प शुल्क और पंजीकरण शुल्क की गणना करें',
  },
  'calc.propertyType': {'en': 'Property Type', 'hi': 'संपत्ति का प्रकार'},
  'calc.selectPropertyType': {'en': 'Select property type', 'hi': 'संपत्ति का प्रकार चुनें'},
  'calc.typeResidential': {'en': 'Residential', 'hi': 'आवासीय'},
  'calc.typeCommercial': {'en': 'Commercial', 'hi': 'व्यावसायिक'},
  'calc.typeAgricultural': {'en': 'Agricultural', 'hi': 'कृषि'},
  'calc.typeOther': {'en': 'Other', 'hi': 'अन्य'},
  'calc.state': {'en': 'State', 'hi': 'राज्य'},
  'calc.selectState': {'en': 'Select state', 'hi': 'राज्य चुनें'},
  'calc.agreementValue': {'en': 'Agreement Value (₹)', 'hi': 'समझौता मूल्य (₹)'},
  'calc.enterAgreementValue': {'en': 'Enter agreement value', 'hi': 'समझौता मूल्य दर्ज करें'},
  'calc.circleRate': {'en': 'Circle Rate / Market Value (₹)', 'hi': 'सर्किल दर / बाजार मूल्य (₹)'},
  'calc.enterCircleRate': {'en': 'Enter circle/market value', 'hi': 'सर्किल/बाजार मूल्य दर्ज करें'},
  'calc.gender': {'en': 'Gender', 'hi': 'लिंग'},
  'calc.selectGender': {'en': 'Select gender', 'hi': 'लिंग चुनें'},
  'calc.genderMale': {'en': 'Male', 'hi': 'पुरुष'},
  'calc.genderFemale': {'en': 'Female', 'hi': 'महिला'},
  'calc.genderJoint': {'en': 'Joint', 'hi': 'संयुक्त'},
  'calc.firstTimeBuyer': {'en': 'First-Time Buyer?', 'hi': 'पहली बार खरीदार?'},
  'calc.selectOption': {'en': 'Select option', 'hi': 'विकल्प चुनें'},
  'calc.yes': {'en': 'Yes', 'hi': 'हाँ'},
  'calc.no': {'en': 'No', 'hi': 'नहीं'},
  'calc.calculate': {'en': 'Calculate', 'hi': 'गणना करें'},
  'calc.calculateBtn': {'en': 'Calculate', 'hi': 'गणना करें'},
  'calc.reset': {'en': 'Reset', 'hi': 'रीसेट'},
  'calc.resetBtn': {'en': 'Reset', 'hi': 'रीसेट'},
  'calc.summary': {'en': 'Calculation Summary', 'hi': 'गणना सारांश'},
  'calc.summaryTitle': {'en': 'Calculation Summary', 'hi': 'गणना सारांश'},
  'calc.agreementValueRow': {'en': 'Agreement Value', 'hi': 'समझौता मूल्य'},
  'calc.rowAgreementValue': {'en': 'Agreement Value', 'hi': 'समझौता मूल्य'},
  'calc.circleRateRow': {'en': 'Circle Rate / Market Value', 'hi': 'सर्किल दर / बाजार मूल्य'},
  'calc.rowCircleRate': {'en': 'Circle Rate / Market Value', 'hi': 'सर्किल दर / बाजार मूल्य'},
  'calc.applicableMarketValueRow': {'en': 'Applicable Market Value', 'hi': 'लागू बाजार मूल्य'},
  'calc.rowApplicableMarketValue': {'en': 'Applicable Market Value', 'hi': 'लागू बाजार मूल्य'},
  'calc.stampDutyRow': {'en': 'Stamp Duty ({rate}%)', 'hi': 'स्टाम्प शुल्क ({rate}%)'},
  'calc.rowStampDuty': {'en': 'Stamp Duty ({rate}%)', 'hi': 'स्टाम्प शुल्क ({rate}%)'},
  'calc.registrationRow': {'en': 'Registration Charges ({rate}%)', 'hi': 'पंजीकरण शुल्क ({rate}%)'},
  'calc.rowRegistration': {'en': 'Registration Charges ({rate}%)', 'hi': 'पंजीकरण शुल्क ({rate}%)'},
  'calc.totalPayable': {'en': 'TOTAL PAYABLE', 'hi': 'कुल देय राशि'},
  'calc.stampPlusReg': {'en': 'Stamp Duty + Registration', 'hi': 'स्टाम्प शुल्क + पंजीकरण'},
  'calc.disclaimer': {
    'en': 'These calculations are estimates based on the selected rates. Actual stamp duty and registration charges may vary depending on the state, property type, transaction details, applicable government rules, exemptions, and current rates. Please verify the applicable rates with the relevant government authority before making a transaction.',
    'hi': 'ये गणनाएं चयनित दरों के आधार पर अनुमानित हैं। राज्य, संपत्ति के प्रकार, लेनदेन के विवरण, लागू सरकारी नियमों, छूटों और वर्तमान दरों के आधार पर वास्तविक स्टाम्प शुल्क और पंजीकरण शुल्क भिन्न हो सकते हैं। कृपया कोई भी लेनदेन करने से पहले संबंधित सरकारी प्राधिकरण से लागू दरों की पुष्टि करें।',
  },
  'calc.fillAllError': {
    'en': 'Please select options for all dropdown fields.',
    'hi': 'कृपया सभी ड्रॉपडाउन फ़ील्ड के लिए विकल्प चुनें।',
  },
  'calc.validValueError': {
    'en': 'Please enter a valid Agreement Value or Circle Rate.',
    'hi': 'कृपया एक वैध समझौता मूल्य या सर्किल दर दर्ज करें।',
  },

  // Checklists Screen
  'checklists.title': {'en': 'My Checklists', 'hi': 'मेरी चेकलिस्ट'},
  'checklists.new': {'en': 'New', 'hi': 'नया'},
  'checklists.newBtn': {'en': 'New', 'hi': 'नया'},
  'checklists.newChecklist': {'en': 'New Checklist', 'hi': 'नई चेकलिस्ट'},
  'checklists.prompt': {
    'en': 'What kind of transaction are you doing?',
    'hi': 'आप किस प्रकार का लेनदेन कर रहे हैं?',
  },
  'checklists.question': {
    'en': 'What kind of transaction are you doing?',
    'hi': 'आप किस प्रकार का लेनदेन कर रहे हैं?',
  },
  'checklists.hint': {'en': 'e.g. Selling a flat in Mumbai', 'hi': 'उदा. मुंबई में फ्लैट बेचना'},
  'checklists.generate': {'en': 'Generate', 'hi': 'तैयार करें'},
  'checklists.generateBtn': {'en': 'Generate', 'hi': 'तैयार करें'},
  'checklists.empty': {
    'en': 'No checklists found.\nTap "New" to generate one.',
    'hi': 'कोई चेकलिस्ट नहीं मिली।\nनई बनाने के लिए "नया" पर टैप करें।',
  },
  'checklists.untitled': {'en': 'Untitled Checklist', 'hi': 'शीर्षकहीन चेकलिस्ट'},
  'checklists.addItem': {'en': 'Add Item', 'hi': 'आइटम जोड़ें'},
  'checklists.addNewItem': {'en': 'Add New Item', 'hi': 'नया आइटम जोड़ें'},
  'checklists.enterTitle': {'en': 'Enter the title of the new task', 'hi': 'नए कार्य का शीर्षक दर्ज करें'},
  'checklists.enterTaskTitle': {'en': 'Enter the title of the new task', 'hi': 'नए कार्य का शीर्षक दर्ज करें'},
  'checklists.verifyTitleDeed': {'en': 'e.g. Verify Title Deed', 'hi': 'उदा. टाइटल डीड सत्यापित करें'},
  'checklists.taskHint': {'en': 'e.g. Verify Title Deed', 'hi': 'उदा. टाइटल डीड सत्यापित करें'},
  'checklists.add': {'en': 'Add', 'hi': 'जोड़ें'},
  'checklists.addBtn': {'en': 'Add', 'hi': 'जोड़ें'},
  'checklists.deleteChecklist': {'en': 'Delete Checklist', 'hi': 'चेकलिस्ट हटाएं'},
  'checklists.deleteConfirm': {'en': 'Are you sure you want to delete this checklist?', 'hi': 'क्या आप वाकई इस चेकलिस्ट को हटाना चाहते हैं?'},
  'checklists.deletedSuccess': {'en': 'Checklist deleted successfully', 'hi': 'चेकलिस्ट सफलतापूर्वक हटा दी गई'},
  'checklists.renameChecklist': {'en': 'Rename Checklist', 'hi': 'चेकलिस्ट का नाम बदलें'},
  'checklists.enterNewName': {'en': 'Enter new checklist name', 'hi': 'नया चेकलिस्ट नाम दर्ज करें'},
  'checklists.renamedSuccess': {'en': 'Checklist renamed successfully', 'hi': 'चेकलिस्ट का नाम सफलतापूर्वक बदल दिया गया'},
  'checklists.deleteItem': {'en': 'Delete Item', 'hi': 'आइटम हटाएं'},
  'checklists.deleteItemConfirm': {'en': 'Delete this task from checklist?', 'hi': 'क्या इस कार्य को चेकलिस्ट से हटाना है?'},
  'checklists.itemDeleted': {'en': 'Task removed', 'hi': 'कार्य हटा दिया गया'},
  'checklists.filterAll': {'en': 'All Tasks', 'hi': 'सभी कार्य'},
  'checklists.filterPending': {'en': 'Pending', 'hi': 'लंबित'},
  'checklists.filterCompleted': {'en': 'Completed', 'hi': 'पूर्ण'},
  'checklists.progress': {'en': 'Progress', 'hi': 'प्रगति'},
  'checklists.completedRatio': {'en': '{completed} of {total} completed', 'hi': '{total} में से {completed} पूर्ण'},
  'checklists.allDone': {'en': 'All due-diligence items completed!', 'hi': 'सभी जांच कार्य पूर्ण हो गए!'},
  'checklists.starterTitle': {'en': 'Quick Starter Templates', 'hi': 'त्वरित टेम्पलेट'},
  'checklists.template1': {'en': 'Buying Resale Flat', 'hi': 'पुनर्विक्रय फ्लैट खरीदना'},
  'checklists.template2': {'en': 'Under-Construction RERA Property', 'hi': 'निर्माणाधीन रेरा संपत्ति'},
  'checklists.template3': {'en': 'Commercial Lease Agreement', 'hi': 'व्यावसायिक लीज समझौता'},
  'checklists.template4': {'en': 'Agricultural / Plot Land Due Diligence', 'hi': 'कृषि / प्लॉट भूमि जांच'},
  'checklists.subtitle': {'en': "Track your property's legal due diligence.", 'hi': 'अपनी संपत्ति की कानूनी जांच की निगरानी करें।'},
  'checklists.heroTitle': {'en': 'PROPERTY DUE DILIGENCE', 'hi': 'संपत्ति उचित सावधानी'},
  'checklists.heroHeadline': {'en': 'Verify before you commit.', 'hi': 'प्रतिबद्ध होने से पहले पुष्टि करें।'},
  'checklists.heroSub': {'en': 'Keep every important legal verification step organized in one place.', 'hi': 'प्रत्येक महत्वपूर्ण कानूनी सत्यापन कदम को एक स्थान पर व्यवस्थित रखें।'},
  'checklists.casesHeading': {'en': 'Active Due-Diligence Cases', 'hi': 'सक्रिय उचित सावधानी मामले'},
  'checklists.verificationBadge': {'en': 'PROPERTY VERIFICATION', 'hi': 'संपत्ति सत्यापन'},
  'checklists.dueDiligenceProgress': {'en': 'Due-diligence progress', 'hi': 'उचित सावधानी प्रगति'},
  'checklists.inProgress': {'en': 'In Progress', 'hi': 'प्रगति में'},
  'checklists.completed': {'en': 'Completed', 'hi': 'पूर्ण'},
  'checklists.emptyTitle': {'en': 'Start your property due diligence', 'hi': 'अपनी संपत्ति की उचित सावधानी शुरू करें'},
  'checklists.emptySub': {'en': 'Create a checklist to organize the legal documents, approvals and verification steps you need before committing to a property.', 'hi': 'संपत्ति के लिए प्रतिबद्ध होने से पहले आवश्यक कानूनी दस्तावेजों, अनुमोदनों और सत्यापन चरणों को व्यवस्थित करने के लिए एक चेकलिस्ट बनाएं।'},
  'checklists.quickStartSub': {'en': 'Start with a property-specific due-diligence checklist.', 'hi': 'संपत्ति-विशिष्ट चेकलिस्ट के साथ शुरुआत करें।'},

  // Recent Documents Screen
  'recentDocs.title': {'en': 'Recent Documents', 'hi': 'हाल के दस्तावेज़'},
  'recentDocs.scanNew': {'en': 'Scan New Document', 'hi': 'नया दस्तावेज़ स्कैन करें'},
  'recentDocs.scanNewDoc': {'en': 'Scan New Document', 'hi': 'नया दस्तावेज़ स्कैन करें'},
  'recentDocs.repository': {'en': 'Document Legal Repository', 'hi': 'दस्तावेज़ कानूनी रिपॉजिटरी'},
  'recentDocs.repoTitle': {'en': 'Document Legal Repository', 'hi': 'दस्तावेज़ कानूनी रिपॉजिटरी'},
  'recentDocs.vaultSubtitle': {
    'en': 'Your property documents, organized and analyzed.',
    'hi': 'आपके संपत्ति दस्तावेज़, व्यवस्थित और विश्लेषित।',
  },
  'recentDocs.secureVault': {'en': 'SECURE LEGAL VAULT', 'hi': 'सुरक्षित कानूनी वॉल्ट'},
  'recentDocs.documents': {'en': 'DOCUMENTS', 'hi': 'दस्तावेज़'},
  'recentDocs.totalAnalyzed': {
    'en': '{count} total property agreements analyzed',
    'hi': 'कुल {count} संपत्ति समझौतों का विश्लेषण किया गया',
  },
  'recentDocs.repoSubtitle': {
    'en': '{count} total property agreements analyzed',
    'hi': 'कुल {count} संपत्ति समझौतों का विश्लेषण किया गया',
  },
  'recentDocs.total': {'en': 'Total', 'hi': 'कुल'},
  'recentDocs.statTotal': {'en': 'Total', 'hi': 'कुल'},
  'recentDocs.highRisk': {'en': 'High Risk', 'hi': 'उच्च जोखिम'},
  'recentDocs.statHighRisk': {'en': 'High Risk', 'hi': 'उच्च जोखिम'},
  'recentDocs.caution': {'en': 'Caution', 'hi': 'सावधानी'},
  'recentDocs.statCaution': {'en': 'Caution', 'hi': 'सावधानी'},
  'recentDocs.compliant': {'en': 'Compliant', 'hi': 'अनुरूप'},
  'recentDocs.statCompliant': {'en': 'Compliant', 'hi': 'अनुरूप'},
  'recentDocs.searchHint': {'en': 'Search documents by title or risk...', 'hi': 'शीर्षक या जोखिम के अनुसार दस्तावेज़ खोजें...'},
  'recentDocs.all': {'en': 'All', 'hi': 'सभी'},
  'recentDocs.filterAll': {'en': 'All', 'hi': 'सभी'},
  'recentDocs.noDocsMatching': {'en': 'No documents matching "{query}"', 'hi': '"{query}" से मेल खाता कोई दस्तावेज़ नहीं मिला'},
  'recentDocs.noMatch': {'en': 'No documents matching "{query}"', 'hi': '"{query}" से मेल खाता कोई दस्तावेज़ नहीं मिला'},
  'recentDocs.noDocsCategory': {'en': 'No documents in this category', 'hi': 'इस श्रेणी में कोई दस्तावेज़ नहीं'},
  'recentDocs.noCategory': {'en': 'No documents in this category', 'hi': 'इस श्रेणी में कोई दस्तावेज़ नहीं'},
  'recentDocs.emptyPrompt': {
    'en': 'Scan a new agreement or document to get an instant AI legal risk report.',
    'hi': 'तुरंत एआई कानूनी जोखिम रिपोर्ट प्राप्त करने के लिए एक नया समझौता या दस्तावेज़ स्कैन करें।',
  },
  'recentDocs.emptyDesc': {
    'en': 'Scan a new agreement or document to get an instant AI legal risk report.',
    'hi': 'तुरंत एआई कानूनी जोखिम रिपोर्ट प्राप्त करने के लिए एक नया समझौता या दस्तावेज़ स्कैन करें।',
  },
  'recentDocs.scanned': {'en': 'Scanned {time}', 'hi': '{time} स्कैन किया गया'},
  'recentDocs.scannedPrefix': {'en': 'Scanned {time}', 'hi': '{time} स्कैन किया गया'},
  'recentDocs.justNow': {'en': 'Just now', 'hi': 'अभी'},
  'recentDocs.mAgo': {'en': '{count}m ago', 'hi': '{count} मिनट पहले'},
  'recentDocs.hAgo': {'en': '{count}h ago', 'hi': '{count} घंटे पहले'},
  'recentDocs.dAgo': {'en': '{count}d ago', 'hi': '{count} दिन पहले'},
  'recentDocs.recently': {'en': 'Recently', 'hi': 'हाल ही में'},
  'recentDocs.rename': {'en': 'Rename Document', 'hi': 'दस्तावेज़ का नाम बदलें'},
  'recentDocs.renameTitle': {'en': 'Rename Document', 'hi': 'दस्तावेज़ का नाम बदलें'},
  'recentDocs.renameHint': {'en': 'Enter document name', 'hi': 'दस्तावेज़ का नाम दर्ज करें'},
  'recentDocs.save': {'en': 'Save', 'hi': 'सहेजें'},
  'recentDocs.cancel': {'en': 'Cancel', 'hi': 'रद्द करें'},
  'recentDocs.delete': {'en': 'Delete Document', 'hi': 'दस्तावेज़ हटाएं'},
  'recentDocs.deleteConfirm': {'en': 'Are you sure you want to delete this document analysis?', 'hi': 'क्या आप वाकई इस दस्तावेज़ विश्लेषण को हटाना चाहते हैं?'},
  'recentDocs.renamedSuccess': {'en': 'Document renamed successfully', 'hi': 'दस्तावेज़ का नाम सफलतापूर्वक बदल दिया गया'},
  'recentDocs.deletedSuccess': {'en': 'Document deleted successfully', 'hi': 'दस्तावेज़ सफलतापूर्वक हटा दिया गया'},
  'recentDocs.actions': {'en': 'Actions', 'hi': 'कार्रवाइयां'},
  'recentDocs.viewDocument': {'en': 'View Document', 'hi': 'दस्तावेज़ देखें'},
  'recentDocs.viewAnalysis': {'en': 'View Analysis', 'hi': 'विश्लेषण देखें'},
  'recentDocs.downloadReport': {'en': 'Download Risk Report', 'hi': 'जोखिम रिपोर्ट डाउनलोड करें'},
  'recentDocs.reanalyze': {'en': 'Re-analyze Document', 'hi': 'दस्तावेज़ का पुनः विश्लेषण करें'},
  'recentDocs.downloadingReport': {'en': 'Generating & downloading risk report PDF...', 'hi': 'जोखिम रिपोर्ट पीडीएफ तैयार और डाउनलोड की जा रही है...'},
  'recentDocs.reportDownloaded': {'en': 'Legal Risk Report PDF downloaded successfully', 'hi': 'कानूनी जोखिम रिपोर्ट पीडीएफ सफलतापूर्वक डाउनलोड की गई'},
  'recentDocs.reanalyzing': {'en': 'Re-analyzing document with Legal AI...', 'hi': 'लीगल एआई के साथ दस्तावेज़ का पुनः विश्लेषण किया जा रहा है...'},
  'recentDocs.reanalyzeSuccess': {'en': 'Document re-analyzed successfully', 'hi': 'दस्तावेज़ का पुनः विश्लेषण सफलतापूर्वक पूरा हुआ'},
  'recentDocs.reanalyzeFailed': {'en': 'Failed to re-analyze document', 'hi': 'दस्तावेज़ का पुनः विश्लेषण करने में विफल'},

  // Analysis Screen
  'analysis.reportTitle': {'en': 'Risk Analysis Report', 'hi': 'जोखिम विश्लेषण रिपोर्ट'},
  'analysis.title': {'en': 'Risk Analysis Report', 'hi': 'जोखिम विश्लेषण रिपोर्ट'},
  'analysis.highRiskDetected': {'en': 'High Legal Risk Detected', 'hi': 'उच्च कानूनी जोखिम का पता चला'},
  'analysis.moderateCaution': {'en': 'Moderate Caution Advised', 'hi': 'मध्यम सावधानी की सलाह दी गई है'},
  'analysis.standardLowRisk': {'en': 'Standard / Low Risk', 'hi': 'मानक / कम जोखिम'},
  'analysis.exportPdf': {'en': 'Export PDF', 'hi': 'पीडीएफ निर्यात करें'},
  'analysis.highRiskCount': {'en': '🔴 {count} High Risk', 'hi': '🔴 {count} उच्च जोखिम'},
  'analysis.pillHighRisk': {'en': '🔴 {count} High Risk', 'hi': '🔴 {count} उच्च जोखिम'},
  'analysis.cautionCount': {'en': '🟡 {count} Caution', 'hi': '🟡 {count} सावधानी'},
  'analysis.pillCaution': {'en': '🟡 {count} Caution', 'hi': '🟡 {count} सावधानी'},
  'analysis.compliantCount': {'en': '🟢 {count} Compliant', 'hi': '🟢 {count} अनुरूप'},
  'analysis.pillCompliant': {'en': '🟢 {count} Compliant', 'hi': '🟢 {count} अनुरूप'},
  'analysis.clausesTotal': {'en': '{count} Clauses Total', 'hi': '{count} कुल खंड'},
  'analysis.pillTotalClauses': {'en': '{count} Clauses Total', 'hi': '{count} कुल खंड'},
  'analysis.sourceDocTitle': {'en': 'Uploaded Source Document & Text', 'hi': 'अपलोड किया गया स्रोत दस्तावेज़ और पाठ'},
  'analysis.sourceDocDefault': {'en': 'Uploaded Source Document & Text', 'hi': 'अपलोड किया गया स्रोत दस्तावेज़ और पाठ'},
  'analysis.originalUploaded': {'en': 'Original uploaded contract file', 'hi': 'मूल अपलोड की गई अनुबंध फ़ाइल'},
  'analysis.originalContractFile': {'en': 'Original uploaded contract file', 'hi': 'मूल अपलोड की गई अनुबंध फ़ाइल'},
  'analysis.expandWindow': {'en': 'Expand Window', 'hi': 'विंडो बड़ा करें'},
  'analysis.originalContractText': {'en': 'Original Contract Text:', 'hi': 'मूल अनुबंध पाठ:'},
  'analysis.analyzedClauses': {'en': 'Analyzed Clauses & Explanations', 'hi': 'विश्लेषण किए गए खंड और स्पष्टीकरण'},
  'analysis.tapToExplain': {'en': 'Tap to explain', 'hi': 'स्पष्टीकरण के लिए टैप करें'},
  'analysis.riskRationale': {'en': 'Risk Rationale: {reason}', 'hi': 'जोखिम का कारण: {reason}'},
  'analysis.simplifyingJargon': {'en': 'Simplifying legal jargon with AI...', 'hi': 'एआई के साथ कानूनी शब्दावली को सरल बनाया जा रहा है...'},
  'analysis.plainEnglish': {'en': 'Plain English Translation', 'hi': 'सरल अनुवाद'},
  'analysis.gotIt': {'en': 'Got it', 'hi': 'समझ गया'},
  'analysis.pdfSuccess': {'en': 'Legal Risk Assessment Report exported successfully!', 'hi': 'कानूनी जोखिम मूल्यांकन रिपोर्ट सफलतापूर्वक निर्यात की गई!'},
  'analysis.exportSuccess': {'en': 'Legal Risk Assessment Report exported successfully!', 'hi': 'कानूनी जोखिम मूल्यांकन रिपोर्ट सफलतापूर्वक निर्यात की गई!'},
  'analysis.pdfFailed': {'en': 'Failed to export PDF: {error}', 'hi': 'पीडीएफ निर्यात करने में विफल: {error}'},
  'analysis.copySuccess': {'en': 'Contract text copied to clipboard!', 'hi': 'अनुबंध पाठ क्लिपबोर्ड पर कॉपी किया गया!'},
  'analysis.copyText': {'en': 'Copy Text', 'hi': 'पाठ कॉपी करें'},
  'analysis.extractedWords': {'en': 'Original Extracted Text ({count} words)', 'hi': 'मूल निकाला गया पाठ ({count} शब्द)'},

  // Auth / Login / Signup / OTP
  'auth.welcomeBack': {'en': 'Welcome Back', 'hi': 'वापसी पर स्वागत है'},
  'auth.enterEmailPhone': {
    'en': 'Enter your email or phone to receive a secure OTP code.',
    'hi': 'सुरक्षित ओटीपी कोड प्राप्त करने के लिए अपना ईमेल या फोन दर्ज करें।',
  },
  'auth.loginOtpPrompt': {
    'en': 'Enter your email or phone to receive a secure OTP code.',
    'hi': 'सुरक्षित ओटीपी कोड प्राप्त करने के लिए अपना ईमेल या फोन दर्ज करें।',
  },
  'auth.email': {'en': 'Email', 'hi': 'ईमेल'},
  'auth.mobile': {'en': 'Mobile', 'hi': 'मोबाइल'},
  'auth.emailAddress': {'en': 'Email Address', 'hi': 'ईमेल पता'},
  'auth.mobileNumber': {'en': 'Mobile Number', 'hi': 'मोबाइल नंबर'},
  'auth.fullName': {'en': 'Full Name', 'hi': 'पूरा नाम'},
  'auth.emailHint': {'en': 'name@example.com', 'hi': 'name@example.com'},
  'auth.phoneHint': {'en': 'e.g. 9876543210', 'hi': 'उदा. 9876543210'},
  'auth.nameHint': {'en': 'e.g. John Doe', 'hi': 'उदा. राहुल शर्मा'},
  'auth.enterIdentifier': {'en': 'Please enter your {type}', 'hi': 'कृपया अपना {type} दर्ज करें'},
  'auth.enterFullName': {'en': 'Please enter your full name', 'hi': 'कृपया अपना पूरा नाम दर्ज करें'},
  'auth.validEmail': {'en': 'Enter a valid email address', 'hi': 'एक मान्य ईमेल पता दर्ज करें'},
  'auth.validPhone': {'en': 'Enter a valid phone number', 'hi': 'एक मान्य फ़ोन नंबर दर्ज करें'},
  'auth.sendOtp': {'en': 'Send Secure OTP', 'hi': 'सुरक्षित ओटीपी भेजें'},
  'auth.sendSecureOtp': {'en': 'Send Secure OTP', 'hi': 'सुरक्षित ओटीपी भेजें'},
  'auth.createAccount': {'en': 'Create Account', 'hi': 'खाता बनाएं'},
  'auth.createYourAccount': {'en': 'Create your account', 'hi': 'अपना खाता बनाएं'},
  'auth.enterDetails': {'en': 'Enter your details to get started securely with LawBuddy.', 'hi': 'LawBuddy के साथ सुरक्षित रूप से शुरुआत करने के लिए अपना विवरण दर्ज करें।'},
  'auth.noAccount': {'en': "Don't have an account? ", 'hi': 'खाता नहीं है? '},
  'auth.dontHaveAccount': {'en': "Don't have an account? ", 'hi': 'खाता नहीं है? '},
  'auth.alreadyHaveAccount': {'en': 'Already have an account? ', 'hi': 'पहले से ही एक खाता है? '},
  'auth.signUp': {'en': 'Sign Up', 'hi': 'साइन अप करें'},
  'auth.logIn': {'en': 'Log In', 'hi': 'लॉग इन करें'},
  'auth.backToHome': {'en': 'Back to Home', 'hi': 'होम पर वापस जाएं'},
  'auth.intelligentProtection': {
    'en': 'Intelligent Protection for Property Agreements.',
    'hi': 'संपत्ति समझौतों के लिए बुद्धिमान सुरक्षा।',
  },
  'auth.signInSubtitle': {
    'en': 'Sign in to access your saved document scans, RERA compliance checks, and real-time legal assistant.',
    'hi': 'अपने सहेजे गए दस्तावेज़ स्कैन, रेरा अनुपालन जांच और रीयल-टाइम कानूनी सहायक तक पहुंचने के लिए साइन इन करें।',
  },
  'auth.loginHeroDesc': {
    'en': 'Sign in to access your saved document scans, RERA compliance checks, and real-time legal assistant.',
    'hi': 'अपने सहेजे गए दस्तावेज़ स्कैन, रेरा अनुपालन जांच और रीयल-टाइम कानूनी सहायक तक पहुंचने के लिए साइन इन करें।',
  },
  'auth.buildSaferJourney': {'en': 'Build a Safer Property Journey.', 'hi': 'एक सुरक्षित संपत्ति यात्रा का निर्माण करें।'},
  'auth.signUpSubtitle': {
    'en': 'Create your account to securely scan, analyze, and manage your property agreements with LawBuddy.',
    'hi': 'LawBuddy के साथ अपने संपत्ति समझौतों को सुरक्षित रूप से स्कैन, विश्लेषण और प्रबंधित करने के लिए अपना खाता बनाएं।',
  },
  'auth.reraSafety': {'en': 'RERA & Contract Safety', 'hi': 'रेरा और अनुबंध सुरक्षा'},
  'auth.aiReady': {'en': 'AI Analysis Ready', 'hi': 'एआई विश्लेषण तैयार'},
  'auth.clauseAssessment': {'en': 'Clause Risk Assessment • Escrow Compliance', 'hi': 'खंड जोखिम मूल्यांकन • एस्क्रो अनुपालन'},
  'auth.agreementIntelligence': {'en': 'Agreement Intelligence', 'hi': 'अनुबंध बुद्धिमत्ता'},
  'auth.aiProtectionReady': {'en': 'AI Protection Ready', 'hi': 'एआई सुरक्षा तैयार'},
  'auth.clauseDocVerification': {'en': 'Clause Risk Assessment • Document Verification', 'hi': 'खंड जोखिम मूल्यांकन • दस्तावेज़ सत्यापन'},
  'auth.encrypted': {'en': 'End-to-end encrypted • Strictly confidential', 'hi': 'एंड-टू-एंड एन्क्रिप्टेड • पूरी तरह गोपनीय'},
  'auth.verifyYourEmail': {'en': 'Verify Your Email', 'hi': 'अपना ईमेल सत्यापित करें'},
  'auth.verifyEmail': {'en': 'Verify Your Email', 'hi': 'अपना ईमेल सत्यापित करें'},
  'auth.enter6Digit': {'en': 'Enter the 6-digit code sent to\n{email}', 'hi': '{email}\nपर भेजा गया 6 अंकों का कोड दर्ज करें'},
  'auth.enterCodeSentTo': {'en': 'Enter the 6-digit code sent to\n{email}', 'hi': '{email}\nपर भेजा गया 6 अंकों का कोड दर्ज करें'},
  'auth.codeExpiresIn': {'en': 'Code expires in {time}', 'hi': 'कोड {time} में समाप्त हो जाएगा'},
  'auth.codeExpired': {'en': 'Code has expired', 'hi': 'कोड समाप्त हो चुका है'},
  'auth.verify': {'en': 'Verify', 'hi': 'सत्यापित करें'},
  'auth.didntReceiveCode': {'en': "Didn't receive the code? ", 'hi': 'कोड प्राप्त नहीं हुआ? '},
  'auth.resend': {'en': 'Resend', 'hi': 'पुनः भेजें'},
  'auth.waitCooldown': {'en': 'Wait {seconds}s', 'hi': '{seconds}s प्रतीक्षा करें'},
  'auth.waitSeconds': {'en': 'Wait {seconds}s', 'hi': '{seconds}s प्रतीक्षा करें'},
  'auth.otpSentSuccess': {'en': 'OTP sent successfully', 'hi': 'ओटीपी सफलतापूर्वक भेजा गया'},
  'auth.otpResendFailed': {'en': 'Failed to resend OTP', 'hi': 'ओटीपी पुनः भेजने में विफल'},
  'auth.enterValidOtp': {'en': 'Please enter a valid 6-digit OTP', 'hi': 'कृपया एक मान्य 6-अंकीय ओटीपी दर्ज करें'},
  'auth.verificationSuccess': {'en': 'Verification successful!', 'hi': 'सत्यापन सफल!'},
  'auth.invalidOtp': {'en': 'Invalid OTP', 'hi': 'अमान्य ओटीपी'},
};
