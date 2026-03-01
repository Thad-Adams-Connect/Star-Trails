// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../data/wisdom_entries.dart';

/// Non-intrusive wisdom panel that slides in from right, displays briefly, then auto-dismisses.
/// Premium premium aesthetic with elegant animations and typography.
class CaptainTransmissionPanel extends StatefulWidget {
  final WisdomEntry wisdom;
  final VoidCallback onSaveToLogbook;
  final VoidCallback onDismiss;
  final int autoDismissSeconds;

  const CaptainTransmissionPanel({
    super.key,
    required this.wisdom,
    required this.onSaveToLogbook,
    required this.onDismiss,
    this.autoDismissSeconds = 6,
  });

  @override
  State<CaptainTransmissionPanel> createState() =>
      _CaptainTransmissionPanelState();
}

class _CaptainTransmissionPanelState extends State<CaptainTransmissionPanel>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _saveButtonHovered = false;
  bool _dismissButtonHovered = false;
  bool _closeButtonHovered = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideController.forward();
    _fadeController.forward();

    // Auto-dismiss after specified duration
    Future.delayed(Duration(seconds: widget.autoDismissSeconds), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await Future.wait([
      _slideController.reverse(),
      _fadeController.reverse(),
    ]);
    if (mounted) {
      widget.onDismiss();
    }
  }

  void _saveAndDismiss() async {
    widget.onSaveToLogbook();
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      top: 80,
      width: 380,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.phosphorGreen.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.phosphorGreen.withValues(alpha: 0.15),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Decorative line + header
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.phosphorGreen,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WORDS OF WISDOM',
                                style: AppTheme.terminalBody.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 2.0,
                                  color: AppTheme.phosphorGreen.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: 1,
                                width: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.phosphorGreen,
                                      AppTheme.phosphorGreen.withValues(
                                        alpha: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        MouseRegion(
                          onEnter: (_) => setState(() => _closeButtonHovered = true),
                          onExit: (_) => setState(() => _closeButtonHovered = false),
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _dismiss,
                            child: Icon(
                              Icons.close,
                              color: AppTheme.phosphorGreen.withValues(
                                alpha: _closeButtonHovered ? 0.9 : 0.5,
                              ),
                              size: _closeButtonHovered ? 22 : 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Wisdom text - premium typography
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        widget.wisdom.text,
                        style: AppTheme.terminalBody.copyWith(
                          fontSize: 15,
                          height: 1.7,
                          letterSpacing: 0.3,
                          color: AppTheme.phosphorGreen,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Button row with improved styling
                    Row(
                      children: [
                        // Save button - primary action
                        Expanded(
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _saveButtonHovered = true),
                            onExit: (_) => setState(() => _saveButtonHovered = false),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _saveAndDismiss,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _saveButtonHovered
                                      ? AppTheme.phosphorGreen.withValues(
                                          alpha: 0.25,
                                        )
                                      : AppTheme.phosphorGreen.withValues(
                                          alpha: 0.15,
                                        ),
                                  border: Border.all(
                                    color: _saveButtonHovered
                                        ? AppTheme.phosphorGreen.withValues(
                                            alpha: 1,
                                          )
                                        : AppTheme.phosphorGreen,
                                    width: _saveButtonHovered ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bookmark_border,
                                      size: 16,
                                      color: _saveButtonHovered
                                          ? AppTheme.phosphorGreen.withValues(
                                              alpha: 1,
                                            )
                                          : AppTheme.phosphorGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SAVE',
                                      style: AppTheme.terminalBody.copyWith(
                                        fontSize: 12,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w500,
                                        color: _saveButtonHovered
                                            ? AppTheme.phosphorGreen.withValues(
                                                alpha: 1,
                                              )
                                            : AppTheme.phosphorGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Dismiss button - secondary action
                        Expanded(
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _dismissButtonHovered = true),
                            onExit: (_) => setState(() => _dismissButtonHovered = false),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _dismiss,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _dismissButtonHovered
                                      ? Colors.black.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _dismissButtonHovered
                                        ? AppTheme.phosphorGreen.withValues(
                                            alpha: 0.6,
                                          )
                                        : AppTheme.phosphorGreen.withValues(
                                            alpha: 0.3,
                                          ),
                                    width: _dismissButtonHovered ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    'DISMISS',
                                    style: AppTheme.terminalBody.copyWith(
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                      fontWeight: FontWeight.w500,
                                      color: _dismissButtonHovered
                                          ? AppTheme.phosphorGreen.withValues(
                                              alpha: 0.9,
                                            )
                                          : AppTheme.phosphorGreen.withValues(
                                              alpha: 0.6,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay manager for showing Captain Transmissions
class CaptainTransmissionOverlay {
  static OverlayEntry? _currentEntry;

  /// Show a Captain Transmission panel
  static void show(
    BuildContext context, {
    required WisdomEntry wisdom,
    required VoidCallback onSaveToLogbook,
  }) {
    // Don't show if already displaying
    if (_currentEntry != null) return;

    _currentEntry = OverlayEntry(
      builder: (context) => CaptainTransmissionPanel(
        wisdom: wisdom,
        onSaveToLogbook: () {
          onSaveToLogbook();
          dismiss();
        },
        onDismiss: dismiss,
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  /// Dismiss current transmission
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Check if transmission is currently showing
  static bool get isShowing => _currentEntry != null;
}
