import 'package:flutter/material.dart';
import '../models/scheme_result.dart';

class ProfileForm extends StatefulWidget {
  final Function(SearchRequest) onSubmit;
  final bool isLoading;

  const ProfileForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final TextEditingController _queryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _businessType = 'Tailoring';
  String _businessStage = 'Startup';
  String _goal = 'Funding';
  String _state = 'Tamil Nadu';
  int _topK = 3;

  final List<String> _businessTypes = [
    'Tailoring',
    'Handicrafts',
    'Food Processing',
    'Agriculture',
    'Retail',
    'Manufacturing',
    'Services',
  ];

  final List<String> _businessStages = [
    'Idea',
    'Startup',
    'Early Stage',
    'Growing',
    'Established',
  ];

  final List<String> _goals = [
    'Funding',
    'Loan',
    'Training',
    'Subsidy',
    'Market Support',
    'Equipment',
    'Business Expansion',
  ];

  final List<String> _states = [
    'Tamil Nadu',
    'All India',
    'Karnataka',
    'Maharashtra',
    'Uttar Pradesh',
    'Gujarat',
    'Kerala',
    'Delhi',
    'Rajasthan',
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final queryText = _queryController.text.trim();
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your business need or choose a quick prompt.'),
          backgroundColor: Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final request = SearchRequest(
      query: queryText,
      profile: UserProfile(
        businessType: _businessType,
        businessStage: _businessStage,
        goal: _goal,
        state: _state,
      ),
      topK: _topK,
    );

    widget.onSubmit(request);
  }

  void _setExampleQuery(String text, String bType, String goal) {
    setState(() {
      _queryController.text = text;
      _businessType = bType;
      _goal = goal;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0B4F4A);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Clear 600px breakpoint
        final bool isMobile = constraints.maxWidth < 600;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title & Subtitle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.travel_explore_rounded,
                        color: primaryTeal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Schemes For You',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Tell us about your business needs and discover relevant government schemes.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Search / Need text field (Full Width)
                const Text(
                  'Your Business Need',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _queryController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Example: I need funding for my tailoring business',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Multilingual Quick Prompts (Wrapping)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickChip(
                      label: 'EN: Tailoring Funding',
                      onTap: () => _setExampleQuery(
                        'I need funding for my tailoring business',
                        'Tailoring',
                        'Funding',
                      ),
                    ),
                    _buildQuickChip(
                      label: 'தமிழ்: தையல் நிதி',
                      onTap: () => _setExampleQuery(
                        'எனது தையல் தொழிலுக்கு நிதி உதவி வேண்டும்',
                        'Tailoring',
                        'Funding',
                      ),
                    ),
                    _buildQuickChip(
                      label: 'हिंदी: सिलाई सहायता',
                      onTap: () => _setExampleQuery(
                        'मुझे अपने सिलाई व्यवसाय के लिए वित्तीय सहायता चाहिए',
                        'Tailoring',
                        'Funding',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2, 3, 4, 5. Dropdowns
                // Below 600px: True single-column mobile layout.
                // >= 600px: Side-by-side rows.
                if (isMobile) ...[
                  // Business Type: Full Width
                  _buildDropdown(
                    label: 'Business Type',
                    value: _businessType,
                    items: _businessTypes,
                    onChanged: (val) {
                      if (val != null) setState(() => _businessType = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Business Stage: Below Business Type and Full Width
                  _buildDropdown(
                    label: 'Business Stage',
                    value: _businessStage,
                    items: _businessStages,
                    onChanged: (val) {
                      if (val != null) setState(() => _businessStage = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Primary Goal: Below it and Full Width
                  _buildDropdown(
                    label: 'Primary Goal',
                    value: _goal,
                    items: _goals,
                    onChanged: (val) {
                      if (val != null) setState(() => _goal = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // State: Below it and Full Width
                  _buildDropdown(
                    label: 'State',
                    value: _state,
                    items: _states,
                    onChanged: (val) {
                      if (val != null) setState(() => _state = val);
                    },
                  ),
                ] else ...[
                  // Desktop / Tablet side-by-side
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Business Type',
                          value: _businessType,
                          items: _businessTypes,
                          onChanged: (val) {
                            if (val != null) setState(() => _businessType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Business Stage',
                          value: _businessStage,
                          items: _businessStages,
                          onChanged: (val) {
                            if (val != null) setState(() => _businessStage = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Primary Goal',
                          value: _goal,
                          items: _goals,
                          onChanged: (val) {
                            if (val != null) setState(() => _goal = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildDropdown(
                          label: 'State',
                          value: _state,
                          items: _states,
                          onChanged: (val) {
                            if (val != null) setState(() => _state = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // 6. Top Results Selector
                if (isMobile) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Results',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildTopKOption(3, 'Top 3')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTopKOption(5, 'Top 5')),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top Results',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Row(
                        children: [
                          _buildTopKOption(3, 'Top 3'),
                          const SizedBox(width: 8),
                          _buildTopKOption(5, 'Top 5'),
                        ],
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // Primary Button: "Find Matching Schemes" (Full Width)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: widget.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Finding your best matches...',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Find Matching Schemes',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0B4F4A)),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
              onChanged: onChanged,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopKOption(int count, String label) {
    final isSelected = _topK == count;
    const primaryTeal = Color(0xFF0B4F4A);

    return InkWell(
      onTap: () => setState(() => _topK = count),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? primaryTeal : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryTeal : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE0B2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE65100),
          ),
        ),
      ),
    );
  }
}
