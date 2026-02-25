// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Reusable End Run Summary component that displays session statistics.
/// Used in End Run Screen, Logbook, and Teacher Mode.
class EndRunSummary extends StatelessWidget {
  final int? startingCredits;
  final int? finalCredits;
  final int? totalFuelUsed;
  final int? totalCreditsSpentOnFuel;
  final int? totalCreditsSpentOnGoods;
  final int? totalCreditsSpentOnUpgrades;
  final int? totalCreditsEarned;

  const EndRunSummary({
    super.key,
    this.startingCredits,
    this.finalCredits,
    this.totalFuelUsed,
    this.totalCreditsSpentOnFuel,
    this.totalCreditsSpentOnGoods,
    this.totalCreditsSpentOnUpgrades,
    this.totalCreditsEarned,
  });

  /// Check if any summary data is available
  bool get hasSummaryData {
    return startingCredits != null ||
        finalCredits != null ||
        totalFuelUsed != null ||
        totalCreditsSpentOnFuel != null ||
        totalCreditsSpentOnGoods != null ||
        totalCreditsSpentOnUpgrades != null ||
        totalCreditsEarned != null;
  }

  /// Calculate net result if both starting and final credits are available
  int? get netResult {
    if (startingCredits != null && finalCredits != null) {
      return finalCredits! - startingCredits!;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasSummaryData) {
      return const SizedBox.shrink();
    }

    final actualNetResult =
        netResult ?? (finalCredits != null ? finalCredits! - 1000 : null);

    return _buildSummaryCard(
      'RUN SUMMARY',
      [
        if (startingCredits != null)
          _SummaryRow('Starting Credits', '$startingCredits')
        else
          const _SummaryRow('Starting Credits', '1000'),
        if (finalCredits != null)
          _SummaryRow('Final Credits', '$finalCredits')
        else
          const _SummaryRow('Final Credits', 'N/A'),
        if (actualNetResult != null)
          _SummaryRow('Net Result', '$actualNetResult',
              highlight: actualNetResult >= 0)
        else
          const _SummaryRow('Net Result', 'N/A'),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.phosphorGreenDim.withValues(alpha: 0.6),
          ),
        ),
        if (totalFuelUsed != null)
          _SummaryRow('Total Fuel Used', '$totalFuelUsed')
        else
          const _SummaryRow('Total Fuel Used', 'N/A'),
        if (totalCreditsSpentOnFuel != null)
          _SummaryRow('Credits Spent on Fuel', '$totalCreditsSpentOnFuel')
        else
          const _SummaryRow('Credits Spent on Fuel', 'N/A'),
        if (totalCreditsSpentOnGoods != null)
          _SummaryRow('Credits Spent on Goods', '$totalCreditsSpentOnGoods')
        else
          const _SummaryRow('Credits Spent on Goods', 'N/A'),
        if (totalCreditsSpentOnUpgrades != null)
          _SummaryRow(
              'Credits Spent on Upgrades', '$totalCreditsSpentOnUpgrades')
        else
          const _SummaryRow('Credits Spent on Upgrades', 'N/A'),
        if (totalCreditsEarned != null)
          _SummaryRow('Credits Earned', '$totalCreditsEarned')
        else
          const _SummaryRow('Credits Earned', 'N/A'),
      ],
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.phosphorGreenDim.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.phosphorGreen.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.phosphorGreen.withValues(alpha: 0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.terminalBody.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.amber : AppTheme.phosphorGreenBright,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
