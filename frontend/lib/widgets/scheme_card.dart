import 'package:flutter/material.dart';

import '../models/scheme_result.dart';
import '../screens/document_upload_screen.dart';
import '../services/api_service.dart';

class SchemeCard extends StatefulWidget {
  final SchemeResult scheme;
  final String userQuery;

  const SchemeCard({super.key, required this.scheme, required this.userQuery});

  @override
  State<SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<SchemeCard> {
  String? _selectedFeedback;
  bool _isSubmittingFeedback = false;

  static const Color primaryTeal = Color(0xFF0B4F4A);

  Future<void> _sendFeedback(String feedbackType) async {
    if (_isSubmittingFeedback || _selectedFeedback == feedbackType) {
      return;
    }

    setState(() {
      _selectedFeedback = feedbackType;
      _isSubmittingFeedback = true;
    });

    try {
      await ApiService().submitFeedback(
        FeedbackRequest(
          query: widget.userQuery,
          schemeId: widget.scheme.schemeId,
          feedback: feedbackType,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            feedbackType == 'relevant'
                ? 'Thanks! Marked as Relevant.'
                : 'Feedback recorded: Not Relevant.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: feedbackType == 'relevant'
              ? primaryTeal
              : const Color(0xFF64748B),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit feedback.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingFeedback = false;
        });
      }
    }
  }

  void _continueToDocumentUpload(BuildContext ctx) {
    Navigator.pop(ctx);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentUploadScreen(
          schemeName: widget.scheme.schemeName,
          schemeId: widget.scheme.schemeId,
          requiredDocuments: widget.scheme.requiredDocuments ?? const [],
        ),
      ),
    );
  }

  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF9F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.scheme.schemeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scheme ID: ${widget.scheme.schemeId} • '
                          'State: ${widget.scheme.state ?? "All India"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Semantic relevance warning
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFFC2410C),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Semantic Relevance: This score shows how closely '
                        'the scheme matches your stated needs. Eligibility '
                        'must be verified separately using official scheme rules.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF9A3412),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.scheme.objective != null &&
                          widget.scheme.objective!.isNotEmpty) ...[
                        _buildDetailSection(
                          icon: Icons.flag_rounded,
                          title: 'Scheme Objective',
                          content: widget.scheme.objective!,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (widget.scheme.benefits != null &&
                          widget.scheme.benefits!.isNotEmpty) ...[
                        _buildDetailSection(
                          icon: Icons.card_giftcard_rounded,
                          title: 'Assistance & Benefits',
                          content: widget.scheme.benefits!,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (widget.scheme.targetBeneficiary != null &&
                          widget.scheme.targetBeneficiary!.isNotEmpty) ...[
                        _buildDetailSection(
                          icon: Icons.people_alt_rounded,
                          title: 'Target Beneficiaries',
                          content: widget.scheme.targetBeneficiary!,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (widget.scheme.businessTypes != null &&
                          widget.scheme.businessTypes!.isNotEmpty) ...[
                        _buildBusinessTypes(),
                        const SizedBox(height: 18),
                      ],

                      // Eligibility rules
                      if (widget.scheme.eligibilityRules != null &&
                          widget.scheme.eligibilityRules!.isNotEmpty) ...[
                        _buildListSection(
                          icon: Icons.fact_check_outlined,
                          title: 'Eligibility Rules',
                          items: widget.scheme.eligibilityRules!,
                        ),
                        const SizedBox(height: 18),
                      ] else ...[
                        _buildUnavailableSection(
                          icon: Icons.fact_check_outlined,
                          title: 'Eligibility Rules',
                          message: 'Verified eligibility rules are not available for this scheme yet.',
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Required documents
                      if (widget.scheme.requiredDocuments != null &&
                          widget.scheme.requiredDocuments!.isNotEmpty) ...[
                        _buildListSection(
                          icon: Icons.description_outlined,
                          title: 'Required Documents',
                          items: widget.scheme.requiredDocuments!,
                        ),
                        const SizedBox(height: 18),
                      ] else ...[
                        _buildUnavailableSection(
                          icon: Icons.description_outlined,
                          title: 'Required Documents',
                          message: 'Verified document requirements are not available for this scheme yet.',
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Official link
                      if (widget.scheme.officialLink != null &&
                          widget.scheme.officialLink!.isNotEmpty) ...[
                        _buildOfficialLink(widget.scheme.officialLink!),
                        const SizedBox(height: 18),
                      ],

                      // Architecture note
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.account_tree_outlined,
                              size: 18,
                              color: Color(0xFF1D4ED8),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Next step: documents can be uploaded and '
                                'passed to the OCR module. OCR and final '
                                'eligibility decisions are handled separately.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _continueToDocumentUpload(ctx),
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Continue to Document Upload'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Center(
                        child: Text(
                          'Stops before OCR processing',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(icon: icon, title: title),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildListSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(icon: icon, title: title),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 15,
                    color: primaryTeal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12.3,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableSection({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(icon: icon, title: title),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 17, color: primaryTeal),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.business_center_outlined,
          title: 'Supported Business Types',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.scheme.businessTypes!
              .map(
                (business) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    business,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildOfficialLink(String link) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.language_rounded,
          title: 'Official Scheme Portal',
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCCFBF1)),
          ),
          child: SelectableText(
            link,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF0F766E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeColors = _getBadgeColors(widget.scheme.matchBadge);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColors['bg'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: badgeColors['fg'],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.scheme.matchBadge,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColors['fg'],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 15,
                      color: primaryTeal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.scheme.relevancePercentage,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: primaryTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              widget.scheme.schemeName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.25,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 15,
                        color: Color(0xFFE65100),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Why this scheme matched',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...widget.scheme.whyMatched.map(
                    (reason) => Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3, right: 6),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 13,
                              color: primaryTeal,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDetailsBottomSheet(context),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFeedbackButton(
                      emoji: '👍',
                      label: 'Relevant',
                      feedbackType: 'relevant',
                    ),
                    const SizedBox(width: 6),
                    _buildFeedbackButton(
                      emoji: '👎',
                      label: 'Not Relevant',
                      feedbackType: 'not_relevant',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackButton({
    required String emoji,
    required String label,
    required String feedbackType,
  }) {
    final selected = _selectedFeedback == feedbackType;

    final isRelevant = feedbackType == 'relevant';

    final selectedBackground = isRelevant
        ? const Color(0xFFE0F2F1)
        : const Color(0xFFFFEBEE);

    final selectedColor = isRelevant
        ? const Color(0xFF004D40)
        : const Color(0xFFC62828);

    return InkWell(
      onTap: _isSubmittingFeedback ? null : () => _sendFeedback(feedbackType),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedBackground : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? selectedColor : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected ? selectedColor : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getBadgeColors(String badge) {
    switch (badge) {
      case 'High Match':
        return {'bg': const Color(0xFFE0F2F1), 'fg': const Color(0xFF00695C)};

      case 'Good Match':
        return {'bg': const Color(0xFFFFF3E0), 'fg': const Color(0xFFE65100)};

      default:
        return {'bg': const Color(0xFFE0F7FA), 'fg': const Color(0xFF00838F)};
    }
  }
}
