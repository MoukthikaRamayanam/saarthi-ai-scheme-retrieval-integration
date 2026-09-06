class UserProfile {
  final String businessType;
  final String businessStage;
  final String goal;
  final String state;

  UserProfile({
    this.businessType = '',
    this.businessStage = '',
    this.goal = '',
    this.state = 'Tamil Nadu',
  });

  Map<String, dynamic> toJson() => {
        'business_type': businessType,
        'business_stage': businessStage,
        'goal': goal,
        'state': state,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        businessType: json['business_type'] ?? '',
        businessStage: json['business_stage'] ?? '',
        goal: json['goal'] ?? '',
        state: json['state'] ?? 'Tamil Nadu',
      );
}

class SearchRequest {
  final String query;
  final UserProfile? profile;
  final int topK;

  SearchRequest({
    required this.query,
    this.profile,
    this.topK = 3,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        if (profile != null) 'profile': profile!.toJson(),
        'top_k': topK,
      };
}

class SchemeResult {
  final String schemeId;
  final String schemeName;
  final double relevanceScore;
  final List<String> whyMatched;
  final String? objective;
  final String? benefits;
  final String? targetBeneficiary;
  final List<String>? businessTypes;
  final String? state;

  SchemeResult({
    required this.schemeId,
    required this.schemeName,
    required this.relevanceScore,
    required this.whyMatched,
    this.objective,
    this.benefits,
    this.targetBeneficiary,
    this.businessTypes,
    this.state,
  });

  /// STRICT RULE: Never label as "eligibility". It represents semantic relevance only.
  String get relevancePercentage {
    final pct = (relevanceScore * 100).clamp(0, 100).toStringAsFixed(0);
    return '$pct% Relevant';
  }

  String get matchBadge {
    if (relevanceScore >= 0.80) {
      return 'High Match';
    } else if (relevanceScore >= 0.65) {
      return 'Good Match';
    } else {
      return 'Relevant';
    }
  }

  factory SchemeResult.fromJson(Map<String, dynamic> json) {
    return SchemeResult(
      schemeId: json['scheme_id'] ?? '',
      schemeName: json['scheme_name'] ?? 'Unknown Scheme',
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      whyMatched: (json['why_matched'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      objective: json['objective'],
      benefits: json['benefits'],
      targetBeneficiary: json['target_beneficiary'],
      businessTypes: (json['business_types'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      state: json['state'],
    );
  }
}

class FeedbackRequest {
  final String query;
  final String schemeId;
  final String feedback; // 'relevant' or 'not_relevant'

  FeedbackRequest({
    required this.query,
    required this.schemeId,
    required this.feedback,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'scheme_id': schemeId,
        'feedback': feedback,
      };
}
