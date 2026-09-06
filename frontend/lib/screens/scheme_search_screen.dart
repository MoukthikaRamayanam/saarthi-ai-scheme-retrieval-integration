import 'package:flutter/material.dart';
import '../models/scheme_result.dart';
import '../services/api_service.dart';
import '../widgets/profile_form.dart';
import '../widgets/scheme_card.dart';
import '../widgets/bottom_nav.dart';

enum SearchState { initial, loading, empty, error, results }

class SchemeSearchScreen extends StatefulWidget {
  const SchemeSearchScreen({super.key});

  @override
  State<SchemeSearchScreen> createState() => _SchemeSearchScreenState();
}

class _SchemeSearchScreenState extends State<SchemeSearchScreen> {
  final ApiService _apiService = ApiService();
  SearchState _searchState = SearchState.initial;
  List<SchemeResult> _results = [];
  String _errorMessage = '';
  SearchRequest? _lastRequest;

  Future<void> _performSearch(SearchRequest request) async {
    setState(() {
      _lastRequest = request;
      _searchState = SearchState.loading;
      _errorMessage = '';
    });

    try {
      final results = await _apiService.searchSchemes(request);
      if (!mounted) return;

      setState(() {
        _results = results;
        _searchState = results.isEmpty ? SearchState.empty : SearchState.results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _searchState = SearchState.error;
      });
    }
  }

  void _showApiSettingsDialog() {
    final controller = TextEditingController(text: _apiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.settings_ethernet_rounded, color: Color(0xFF0B4F4A)),
              SizedBox(width: 8),
              Text(
                'API Base URL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure backend host for FastAPI:',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'http://10.0.2.2:8000',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '• Android Emulator: http://10.0.2.2:8000\n• Web / Windows / Mac: http://127.0.0.1:8000\n• Physical Phone: http://<YOUR_LAN_IP>:8000',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  _apiService.setBaseUrl(text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('API URL updated to: $text'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B4F4A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const creamBackground = Color(0xFFFBF9F5);
    const primaryTeal = Color(0xFF0B4F4A);
    const orangeAccent = Color(0xFFE65100);

    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B4F4A), Color(0xFF0D6E66)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'SAARTHI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI',
              style: TextStyle(
                color: orangeAccent,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'BGE-M3',
                style: TextStyle(
                  color: primaryTeal,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF475569)),
            tooltip: 'Configure Backend URL',
            onPressed: _showApiSettingsDialog,
          ),
        ],
      ),
      bottomNavigationBar: const SaarthiBottomNav(currentIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryTeal,
          onRefresh: () async {
            if (_lastRequest != null) {
              await _performSearch(_lastRequest!);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Architecture Banner: Non-eligibility reminder
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hub_outlined, size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Semantic Retrieval Module: BGE-M3 ranks schemes by vector similarity. Eligibility is validated separately.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search & Profile Form
                    ProfileForm(
                      isLoading: _searchState == SearchState.loading,
                      onSubmit: _performSearch,
                    ),
                    const SizedBox(height: 24),

                    // Search State Content
                    _buildSearchStateContent(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchStateContent() {
    switch (_searchState) {
      case SearchState.initial:
        return _buildInitialState();
      case SearchState.loading:
        return _buildLoadingState();
      case SearchState.empty:
        return _buildEmptyState();
      case SearchState.error:
        return _buildErrorState();
      case SearchState.results:
        return _buildResultsList();
    }
  }

  Widget _buildInitialState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 48,
            color: const Color(0xFF0B4F4A).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ready to Discover Schemes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your requirement above or tap a multilingual prompt to find matching opportunities.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    const primaryTeal = Color(0xFF0B4F4A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Finding your best matches...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryTeal,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Encoding query with BAAI BGE-M3 & calculating vector similarity...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          const Text(
            'No matching schemes found.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try broadening your business need description or selecting a different goal/stage.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              if (_lastRequest != null) {
                _performSearch(_lastRequest!);
              }
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4E6)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: Color(0xFFE11D48),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to fetch schemes. Please try again.',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9F1239),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage.isNotEmpty ? _errorMessage : 'A server or network error occurred.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFBE123C),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (_lastRequest != null) {
                _performSearch(_lastRequest!);
              }
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B4F4A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Matched Schemes (${_results.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const Text(
              'Ranked by Relevance',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B4F4A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            return SchemeCard(
              scheme: _results[index],
              userQuery: _lastRequest?.query ?? '',
            );
          },
        ),
      ],
    );
  }
}
