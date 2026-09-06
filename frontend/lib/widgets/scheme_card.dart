import 'package:flutter/material.dart';
import '../models/scheme_result.dart';
import '../services/api_service.dart';

class SchemeCard extends StatefulWidget {
  final SchemeResult scheme;
  final String userQuery;

  const SchemeCard({
    super.key,
    required this.scheme,
    required this.userQuery,
  });

  @override
  State<SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<SchemeCard> {
  String? _selectedFeedback; // 'relevant' or 'not_relevant'
  bool _isSubmittingFeedback = false;

  Future<void> _sendFeedback(String feedbackType) async {
    if (_isSubmittingFeedback || _selectedFeedback == feedbackType) return;

    setState(() {
      _selectedFeedback = feedbackType;
      _isSubmittingFeedback = true;
    });

    await ApiService().submitFeedback(
      FeedbackRequest(
        query: widget.userQuery,
        schemeId: widget.scheme.schemeId,
        feedback: feedbackType,
      ),
    );

    if (mounted) {
      setState(() {
        _isSubmittingFeedback = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            feedbackType == 'relevant'
                ? 'Thanks! Marked as Relevant to help refine future ranking.'
                : 'Feedback recorded: Marked as Not Relevant.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: feedbackType == 'relevant'
              ? const Color(0xFF0B4F4A)
              : const Color(0xFF64748B),
        ),
      );
    }
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
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Title and Scheme ID
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
                          'Scheme ID: ${widget.scheme.schemeId} • State: ${widget.scheme.state ?? "All India"}',
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

              // Architectural Disclaimer Banner
              Container(
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
                        'Semantic Relevance Only: This ranking represents AI vector similarity to your stated needs. It does NOT constitute official eligibility approval.',
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

              // Scrollable Details
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.scheme.objective != null) ...[
                        _buildDetailSection(
                          icon: Icons.flag_rounded,
                          title: 'Scheme Objective',
                          content: widget.scheme.objective!,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (widget.scheme.benefits != null) ...[
                        _buildDetailSection(
                          icon: Icons.card_giftcard_rounded,
                          title: 'Assistance & Benefits',
                          content: widget.scheme.benefits!,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (widget.scheme.targetBeneficiary != null) ...[
                        _buildDetailSection(
                          icon: Icons.people_alt_rounded,
                          title: 'Target Beneficiaries',
                          content: widget.scheme.targetBeneficiary!,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (widget.scheme.businessTypes != null &&
                          widget.scheme.businessTypes!.isNotEmpty) ...[
                        const Text(
                          'Supported Business Types',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.scheme.businessTypes!
                              .map(
                                (b) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    b,
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
                        const SizedBox(height: 14),
                      ],
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
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0B4F4A)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0B4F4A);
    final badgeColorInfo = _getBadgeColors(widget.scheme.matchBadge);

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
            // Top Row: Match Badge & Relevance Score (Wrap-safe)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Badge: High Match / Good Match / Relevant
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: badgeColorInfo['bg'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: badgeColorInfo['fg'],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.scheme.matchBadge,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColorInfo['fg'],
                        ),
                      ),
                    ],
                  ),
                ),

                // Relevance Score as percentage (Strictly NOT eligibility)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 15,
                      color: Color(0xFF0B4F4A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.scheme.relevancePercentage,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B4F4A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scheme Name
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

            // "Why this scheme matched" Section
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

            // Bottom Actions: View Details + Feedback Buttons
            // Wrap ensures no horizontal overflow on narrow devices
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // View Details Button
                OutlinedButton.icon(
                  onPressed: () => _showDetailsBottomSheet(context),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Feedback buttons row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Feedback: 👍 Relevant
                    InkWell(
                      onTap: () => _sendFeedback('relevant'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedFeedback == 'relevant'
                              ? const Color(0xFFE0F2F1)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedFeedback == 'relevant'
                                ? const Color(0xFF004D40)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('👍', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              'Relevant',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _selectedFeedback == 'relevant'
                                    ? const Color(0xFF004D40)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Feedback: 👎 Not Relevant
                    InkWell(
                      onTap: () => _sendFeedback('not_relevant'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedFeedback == 'not_relevant'
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedFeedback == 'not_relevant'
                                ? const Color(0xFFC62828)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('👎', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              'Not Relevant',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _selectedFeedback == 'not_relevant'
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Map<String, Color> _getBadgeColors(String badge) {
    switch (badge) {
      case 'High Match':
        return {
          'bg': const Color(0xFFE0F2F1),
          'fg': const Color(0xFF00695C),
        };
      case 'Good Match':
        return {
          'bg': const Color(0xFFFFF3E0),
          'fg': const Color(0xFFE65100),
        };
      default:
        return {
          'bg': const Color(0xFFE0F7FA),
          'fg': const Color(0xFF00838F),
        };
    }
  }
}
