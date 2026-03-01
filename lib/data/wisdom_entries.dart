// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

/// Wisdom entries for Grade 4–6 economic principles.
/// Tagged with context metadata for smart triggering.
library;

class WisdomEntry {
  final String id;
  final String text;
  final List<String> tags;
  final int minCooldownSeconds;

  const WisdomEntry({
    required this.id,
    required this.text,
    required this.tags,
    this.minCooldownSeconds = 180, // 3 minutes default
  });
}

/// Grade 4–6 Words of Wisdom
const List<WisdomEntry> grade4to6Wisdom = [
  // Win / Success
  WisdomEntry(
    id: 'win_planning',
    text: 'Good planning and hard work lead to prosperity.',
    tags: ['win', 'success', 'profit', 'preparation'],
    minCooldownSeconds: 240,
  ),
  WisdomEntry(
    id: 'win_steady',
    text: 'Steady decisions build stronger results than rushed choices.',
    tags: ['win', 'success', 'patience'],
    minCooldownSeconds: 240,
  ),
  WisdomEntry(
    id: 'win_small_steps',
    text: 'Small, consistent gains compound into large achievements.',
    tags: ['win', 'success', 'patience'],
    minCooldownSeconds: 240,
  ),

  // Loss / Failure
  WisdomEntry(
    id: 'loss_learning',
    text: 'Every setback teaches what success cannot.',
    tags: ['loss', 'failure', 'learning'],
    minCooldownSeconds: 180,
  ),
  WisdomEntry(
    id: 'loss_recovery',
    text: 'Losses are temporary. What you learn from them lasts.',
    tags: ['loss', 'failure', 'resilience'],
    minCooldownSeconds: 180,
  ),
  WisdomEntry(
    id: 'loss_adjustment',
    text: 'When a route fails, adjust your strategy—not your integrity.',
    tags: ['loss', 'failure', 'integrity', 'adjustment'],
    minCooldownSeconds: 180,
  ),

  // Risk / Warning
  WisdomEntry(
    id: 'risk_caution',
    text: 'Bold decisions require careful preparation.',
    tags: ['risk', 'warning', 'preparation'],
    minCooldownSeconds: 120,
  ),
  WisdomEntry(
    id: 'risk_measurement',
    text: 'Measure twice, commit once.',
    tags: ['risk', 'warning', 'patience'],
    minCooldownSeconds: 120,
  ),
  WisdomEntry(
    id: 'risk_balance',
    text: 'Opportunity and caution balance each other.',
    tags: ['risk', 'warning', 'balance'],
    minCooldownSeconds: 120,
  ),

  // Upgrade / Investment
  WisdomEntry(
    id: 'upgrade_investment',
    text: 'Invest in better tools, gain better outcomes.',
    tags: ['upgrade', 'investment', 'improvement'],
    minCooldownSeconds: 300,
  ),
  WisdomEntry(
    id: 'upgrade_foundation',
    text: 'Upgrading your foundation strengthens everything built upon it.',
    tags: ['upgrade', 'investment', 'foundation'],
    minCooldownSeconds: 300,
  ),
  WisdomEntry(
    id: 'upgrade_timing',
    text: 'The best time to upgrade was yesterday. The second best time is now.',
    tags: ['upgrade', 'investment', 'timing'],
    minCooldownSeconds: 300,
  ),

  // Preparation / Planning
  WisdomEntry(
    id: 'prep_routes',
    text: 'Know your routes before you travel them.',
    tags: ['preparation', 'planning', 'knowledge'],
    minCooldownSeconds: 200,
  ),
  WisdomEntry(
    id: 'prep_fuel',
    text: 'Fuel discipline prevents stranded ships.',
    tags: ['preparation', 'planning', 'fuel', 'discipline'],
    minCooldownSeconds: 200,
  ),
  WisdomEntry(
    id: 'prep_margins',
    text: 'Plan for margins, not just profit.',
    tags: ['preparation', 'planning', 'safety'],
    minCooldownSeconds: 200,
  ),

  // Patience
  WisdomEntry(
    id: 'patience_markets',
    text: 'Markets reward patience as much as skill.',
    tags: ['patience', 'timing', 'markets'],
    minCooldownSeconds: 220,
  ),
  WisdomEntry(
    id: 'patience_decisions',
    text: 'Hesitation is not weakness—it is measurement.',
    tags: ['patience', 'decision', 'caution'],
    minCooldownSeconds: 220,
  ),
  WisdomEntry(
    id: 'patience_growth',
    text: 'Growth happens over time, not in a single trade.',
    tags: ['patience', 'growth', 'long-term'],
    minCooldownSeconds: 220,
  ),

  // Integrity / Ethics
  WisdomEntry(
    id: 'integrity_trust',
    text: 'Trust is earned slowly and lost quickly.',
    tags: ['integrity', 'trust', 'ethics'],
    minCooldownSeconds: 240,
  ),
  WisdomEntry(
    id: 'integrity_reputation',
    text: 'Your reputation travels faster than your ship.',
    tags: ['integrity', 'reputation', 'ethics'],
    minCooldownSeconds: 240,
  ),
  WisdomEntry(
    id: 'integrity_fairness',
    text: 'Fair trade builds stronger networks than quick profit.',
    tags: ['integrity', 'fairness', 'ethics', 'trade'],
    minCooldownSeconds: 240,
  ),

  // Resource Management
  WisdomEntry(
    id: 'resource_conservation',
    text: 'What you save today funds tomorrow\'s opportunity.',
    tags: ['resource', 'conservation', 'planning'],
    minCooldownSeconds: 200,
  ),
  WisdomEntry(
    id: 'resource_efficiency',
    text: 'Efficiency matters more than speed.',
    tags: ['resource', 'efficiency', 'optimization'],
    minCooldownSeconds: 200,
  ),
  WisdomEntry(
    id: 'resource_allocation',
    text: 'Allocate carefully—resources spent unwisely cannot return.',
    tags: ['resource', 'allocation', 'discipline'],
    minCooldownSeconds: 200,
  ),

  // Trade / Commerce
  WisdomEntry(
    id: 'trade_value',
    text: 'Value lies in what people need, not what you have.',
    tags: ['trade', 'commerce', 'markets', 'demand'],
    minCooldownSeconds: 210,
  ),
  WisdomEntry(
    id: 'trade_timing',
    text: 'Buy low, sell high—but timing requires knowledge.',
    tags: ['trade', 'commerce', 'timing', 'knowledge'],
    minCooldownSeconds: 210,
  ),
  WisdomEntry(
    id: 'trade_consistency',
    text: 'Consistent trades build stronger wealth than singular gambles.',
    tags: ['trade', 'commerce', 'consistency', 'patience'],
    minCooldownSeconds: 210,
  ),

  // Learning / Knowledge
  WisdomEntry(
    id: 'learning_experience',
    text: 'Every trip teaches—even unsuccessful ones.',
    tags: ['learning', 'knowledge', 'experience'],
    minCooldownSeconds: 230,
  ),
  WisdomEntry(
    id: 'learning_observation',
    text: 'Observe patterns. Patterns reveal opportunity.',
    tags: ['learning', 'knowledge', 'observation'],
    minCooldownSeconds: 230,
  ),
  WisdomEntry(
    id: 'learning_adaptation',
    text: 'Adapt what you learn, or learning stays knowledge—not skill.',
    tags: ['learning', 'knowledge', 'adaptation'],
    minCooldownSeconds: 230,
  ),
];
