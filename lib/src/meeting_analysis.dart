/// Result of running a Template against a transcript via Gemini.
///
/// Stores section data in a flat `Map<sectionId, dynamic>`. UI iterates
/// the Template's sections and looks up the corresponding entry to
/// render. This means a meeting analysed under one template can be
/// rendered under another (re-analyse), and both apps interpret the
/// same section data identically.
class MeetingAnalysis {
  /// Section data keyed by section id. Values may be lists, maps,
  /// strings, or null depending on the section's schema.
  final Map<String, dynamic> sectionData;

  /// Optional raw markdown fallback. Useful when consumers want to
  /// render or share a flat-text version. Not currently produced by
  /// GeminiPromptBuilder — reserved for a future "comprehensive
  /// markdown" output mode.
  final String? rawMarkdown;

  /// Id of the Template used to produce this analysis. Empty string
  /// if unknown / legacy.
  final String templateId;

  /// Wall-clock when the analysis was produced.
  final DateTime analysedAt;

  const MeetingAnalysis({
    required this.sectionData,
    required this.templateId,
    required this.analysedAt,
    this.rawMarkdown,
  });

  /// Empty placeholder when Gemini returns nothing or call failed.
  factory MeetingAnalysis.empty({String templateId = ''}) => MeetingAnalysis(
        sectionData: const {},
        templateId: templateId,
        analysedAt: DateTime.now(),
      );

  // ── Convenience getters for known section ids ─────────────────────
  // Old code paths that used direct fields on MeetingAnalysis can keep
  // working with these accessors without caring about the section
  // architecture underneath.

  String get summary {
    final raw = sectionData['summary'];
    if (raw is String) return raw;
    return '';
  }

  List<Map<String, dynamic>> get actionItems {
    final raw = sectionData['action_items'];
    if (raw is! List) return const [];
    return [
      for (final r in raw)
        if (r is Map) Map<String, dynamic>.from(r),
    ];
  }

  List<Map<String, dynamic>> get decisions {
    final raw = sectionData['decisions'];
    if (raw is! List) return const [];
    return [
      for (final r in raw)
        if (r is Map) Map<String, dynamic>.from(r),
    ];
  }

  List<String> get risks {
    final raw = sectionData['risks'];
    if (raw is! List) return const [];
    return [for (final r in raw) r.toString()];
  }

  String get followUpEmail {
    final raw = sectionData['follow_up_email'];
    if (raw is String) return raw;
    return '';
  }

  // ── Serialisation ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'section_data': sectionData,
        'template_id': templateId,
        'analysed_at': analysedAt.toUtc().toIso8601String(),
        if (rawMarkdown != null) 'raw_markdown': rawMarkdown,
      };

  factory MeetingAnalysis.fromJson(Map<String, dynamic> j) => MeetingAnalysis(
        sectionData:
            Map<String, dynamic>.from(j['section_data'] as Map? ?? const {}),
        templateId: (j['template_id'] ?? '').toString(),
        analysedAt: DateTime.tryParse((j['analysed_at'] ?? '').toString()) ??
            DateTime.now(),
        rawMarkdown: j['raw_markdown']?.toString(),
      );
}
