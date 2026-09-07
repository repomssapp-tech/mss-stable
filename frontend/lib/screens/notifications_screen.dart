import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/services/centralized_translator.dart';
import 'package:frontend/l10n/l10n.dart';
import 'package:frontend/utils/responsive.dart';
import 'package:frontend/widgets/app_toast.dart';
import 'regular_mode/basic_profile_screen.dart';
import '../utils/app_spacing.dart';

class NotificationsScreen extends StatefulWidget {
  final String? initialFilter;
  const NotificationsScreen({super.key, this.initialFilter});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late String _activeFilter;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? 'All';
  }

  final List<Map<String, dynamic>> _categories = [
    {'key': 'All', 'label': 'All', 'icon': Icons.notifications_none},
    {
      'key': 'new_schemes',
      'label': 'New Schemes',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'key': 'reminders',
      'label': 'Reminders',
      'icon': Icons.calendar_today_outlined,
    },
    {'key': 'updates', 'label': 'Updates', 'icon': Icons.campaign_outlined},
    {'key': 'profile', 'label': 'Profile', 'icon': Icons.person_outline},
  ];

  // Helper widget to build tags
  Widget _buildTag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          color: textCol,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Localization helpers for the (temporary) seed notifications ──────────
  // The provider builds `_notificationsList` without a BuildContext, so every
  // display string that needs translation is localized here, at render time.

  String _categoryLabel(BuildContext context, String key) {
    switch (key) {
      case 'All':
        return context.l10n.filterAll;
      case 'new_schemes':
        return context.l10n.notifCatNewSchemes;
      case 'reminders':
        return context.l10n.notifCatReminders;
      case 'updates':
        return context.l10n.notifCatUpdates;
      case 'profile':
        return context.l10n.notifCatProfile;
      default:
        return key;
    }
  }

  String _tagLabel(BuildContext context, dynamic raw) {
    switch (raw?.toString()) {
      case 'Education':
        return context.l10n.notifTagEducation;
      case 'Skill Development':
        return context.l10n.notifTagSkillDevelopment;
    }
    return raw?.toString() ?? '';
  }

  // Relative-time strings are stored on the seed/stream entries as a
  // `timeAgoCount` (int) + `timeAgoUnit` ('d' | 'h' | 'm' | 'now') pair and
  // formatted through parameterized ARB keys so the same text renders in ta.
  String _timeAgo(BuildContext context, Map<String, dynamic> item) {
    final count = item['timeAgoCount'];
    if (count is int) {
      switch (item['timeAgoUnit']) {
        case 'd':
          return context.l10n.timeAgoDays(count);
        case 'h':
          return context.l10n.timeAgoHours(count);
        case 'm':
          return context.l10n.timeAgoMinutes(count);
      }
    }
    final raw = item['time'];
    if (raw is String && raw.isNotEmpty && raw != 'Just now') return raw;
    return context.l10n.timeAgoJustNow;
  }

  String _daysLeft(BuildContext context, Map<String, dynamic> item) {
    final count = item['daysLeftCount'];
    if (count is int) return context.l10n.daysLeftFmt(count);
    return item['daysLeft']?.toString() ?? '';
  }

  // Deadline strings are stored as "DD Mon YYYY" (English month token); swap
  // the month for its localized abbreviation from `monthAbbrList`.
  String _deadline(BuildContext context, Map<String, dynamic> item) {
    final raw = item['deadline']?.toString() ?? '';
    final parts = raw.split(' ');
    if (parts.length != 3) return raw;
    const enMonths = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    final idx = enMonths.indexOf(
      parts[1].toLowerCase().substring(
            0,
            parts[1].length < 3 ? parts[1].length : 3,
          ),
    );
    if (idx < 0) return raw;
    final localized = context.l10n.monthAbbrList.split(',');
    if (localized.length != 12) return raw;
    return '${parts[0]} ${localized[idx]} ${parts[2]}';
  }

  // Best-effort translation of the seed scheme prose (real-scheme
  // communications). English data is kept intact for equality checks in the
  // provider stream / card builders; only the display value is swapped.
  String _seedText(BuildContext context, dynamic raw) {
    final s = raw?.toString() ?? '';
    final l = context.l10n;
    switch (s) {
      case 'Fisheries and Aquaculture Infra Development Fund Scheme Launched':
        return l.fallbackLatestUpdateTitle;
      case 'Government has launched the Fisheries and Aquaculture Infrastructure Development Fund to provide concessionary finance.':
        return l.notifSeed1Body;
      case 'PM Vidyalaxmi Education Loan Scheme':
        return l.notifSeed2Title;
      case 'A new scheme for students to provide collateral-free education loans for higher studies.':
        return l.notifSeed2Body;
      case 'PM Vishwakarma Yojana':
        return l.notifSeed3Title;
      case 'Financial support for traditional artisans and craftspeople to upgrade their skills and tools.':
        return l.notifSeed3Body;
      case 'Post Matric Scholarship Scheme':
        return l.notifSeed4Title;
      case 'Last date to apply is approaching':
        return l.notifSeed4Body;
      case 'PM Internship Scheme':
        return l.notifSeed5Title;
      case 'Application window will close soon':
        return l.notifSeed5Body;
      case 'New Update on Ayushman Bharat Yojana':
        return l.notifSeed6Title;
      case 'Changes in empanelment process for hospitals. Check full details.':
        return l.notifSeed6Body;
      case 'Income Limit Revised for Several Schemes':
        return l.notifSeed7Title;
      case 'Revised income criteria effective from 1st April 2024 for multiple schemes.':
        return l.notifSeed7Body;
      case 'Complete Your Profile':
        return l.completeYourProfile;
      case 'Add your income details to find schemes you are eligible for.':
        return l.notifSeed8Body;
    }
    return s;
  }

  // Filter Chips Row Builder
  Widget _buildFilterChips() {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _activeFilter == cat['key'];
          final activeBgColor = const Color(0xFFEFF6FF);
          final activeTextColor = const Color(0xFF2563EB);
          final inactiveBgColor = Colors.white;
          final inactiveTextColor = const Color(0xFF64748B);

          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = cat['key'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? activeBgColor : inactiveBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFDBEAFE)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                    size: 15,
                  ),
                  const SizedBox(width: AppSpacing.tight),
                  Text(
                    _categoryLabel(context, cat['key'] as String),
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? activeTextColor
                          : const Color(0xFF1E293B),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Section Builder Helper
  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData headerIcon,
    required Color headerIconBg,
    required Color headerIconColor,
    required List<Widget> cards,
    required VoidCallback onViewAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: headerIconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(headerIcon, color: headerIconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FitOneLine(
                        child: Text(
                          context.l10n.viewAll,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.hairline),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...cards,
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildNewSchemeCard(
    BuildContext context,
    Map<String, dynamic> item,
    AppProvider provider,
  ) {
    final id = item['id'] as String;
    final isSelected = _selectedIds.contains(id);
    final isRead = item['read'] as bool;
    final isEducation = item['tag'] == 'Education';
    final Color iconBg = isEducation
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final Color iconCol = isEducation
        ? const Color(0xFF16A34A)
        : const Color(0xFFEA580C);
    final IconData icon = isEducation
        ? Icons.school
        : Icons.store_mall_directory_outlined;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.tight),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(id);
              } else {
                _selectedIds.add(id);
              }
            });
          } else {
            provider.markNotificationRead(id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.md),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconCol, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _seedText(context, item['title']),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.tight),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.tight,
                            vertical: AppSpacing.hairline,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.l10n.notifBadgeNew,
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      _seedText(context, item['body']),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTag(_tagLabel(context, item['tag']), iconBg, iconCol),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _timeAgo(context, item),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(
    BuildContext context,
    Map<String, dynamic> item,
    AppProvider provider,
  ) {
    final id = item['id'] as String;
    final isSelected = _selectedIds.contains(id);
    final isRead = item['read'] as bool;
    final isPostMatric = item['title'] == 'Post Matric Scholarship Scheme';
    final IconData icon = isPostMatric
        ? Icons.calendar_today_outlined
        : Icons.access_time;
    final Color iconBg = isPostMatric
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFF3E5F5);
    final Color iconCol = isPostMatric
        ? const Color(0xFFD32F2F)
        : const Color(0xFF7B1FA2);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.tight),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(id);
              } else {
                _selectedIds.add(id);
              }
            });
          } else {
            provider.markNotificationRead(id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.md),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconCol, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _seedText(context, item['title']),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _seedText(context, item['body']),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.tight,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Color(0xFFE11D48),
                        ),
                        const SizedBox(width: AppSpacing.hairline),
                        Text(
                          _deadline(context, item),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFFE11D48),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '•',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _daysLeft(context, item),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFFE11D48),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _timeAgo(context, item),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGovtUpdateCard(
    BuildContext context,
    Map<String, dynamic> item,
    AppProvider provider,
  ) {
    final id = item['id'] as String;
    final isSelected = _selectedIds.contains(id);
    final isRead = item['read'] as bool;
    final IconData icon = item['iconType'] == 'emblem'
        ? Icons.gavel_outlined
        : Icons.account_balance_outlined;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.tight),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(id);
              } else {
                _selectedIds.add(id);
              }
            });
          } else {
            provider.markNotificationRead(id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: const Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _seedText(context, item['title']),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _seedText(context, item['body']),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FitOneLine(
                          child: Text(
                            _timeAgo(context, item),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileReminderCard(
    BuildContext context,
    Map<String, dynamic> item,
    AppProvider provider,
  ) {
    final id = item['id'] as String;
    final isSelected = _selectedIds.contains(id);
    final isRead = item['read'] as bool;
    final completion = provider.profileCompletionPercentage;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.tight),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(id);
              } else {
                _selectedIds.add(id);
              }
            });
          } else {
            provider.markNotificationRead(id);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BasicProfileScreen()),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.md),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E5F5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.edit_note_outlined,
                  color: Color(0xFF7B1FA2),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _seedText(context, item['title']),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _seedText(context, item['body']),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text(
                          context.l10n.notifProfileCompletionLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: completion / 100.0,
                              backgroundColor: const Color(0xFFF3E8FF),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C3AED),
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$completion%',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FitOneLine(
                          child: Text(
                            _timeAgo(context, item),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final list = provider.notifications;

    // Filtered lists for each section
    final newSchemes = list
        .where((n) => n['category'] == 'new_schemes')
        .toList();
    final reminders = list.where((n) => n['category'] == 'reminders').toList();
    final updates = list.where((n) => n['category'] == 'updates').toList();
    final profileAlerts = list
        .where((n) => n['category'] == 'profile')
        .toList();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: AppConstants.primaryText),
                tooltip: context.l10n.notifCancelSelectionTooltip,
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        title: Text(
          _isSelectionMode
              ? context.l10n.notifSelectedCount(_selectedIds.length)
              : context.l10n.notificationsGroupHeader,
          style: GoogleFonts.poppins(
            color: AppConstants.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.primaryText),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.done_all,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                  tooltip: context.l10n.notifTooltipMarkRead,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          provider.markNotificationsRead(_selectedIds.toList());
                          AppToast.showSuccess(
                            context,
                            CentralizedTranslator.instance.translate(
                              'Selected notifications marked as read',
                            ),
                          );
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                        },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                  tooltip: context.l10n.notifTooltipDeleteSelected,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          provider.deleteNotifications(_selectedIds.toList());
                          AppToast.showSuccess(
                            context,
                            CentralizedTranslator.instance.translate(
                              'Selected notifications deleted',
                            ),
                          );
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                        },
                ),
                const SizedBox(width: AppSpacing.sm),
              ]
            : [
                PopupMenuButton<String>(
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppConstants.primaryText,
                    size: 22,
                  ),
                  onSelected: (value) {
                    if (value == 'mark_all_read') {
                      provider.markAllNotificationsRead();
                      AppToast.showSuccess(
                        context,
                        CentralizedTranslator.instance.translate(
                          'All notifications marked as read',
                        ),
                      );
                    } else if (value == 'delete_all') {
                      provider.deleteAllNotifications();
                      AppToast.showSuccess(
                        context,
                        CentralizedTranslator.instance.translate(
                          'All notifications deleted',
                        ),
                      );
                    } else if (value == 'select') {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedIds.clear();
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.done_all,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.notifMarkAllAsRead,
                              softWrap: true,
                              style: GoogleFonts.inter(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_sweep_outlined,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.notifDeleteAll,
                              softWrap: true,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.checklist_rtl_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.select,
                              softWrap: true,
                              style: GoogleFonts.inter(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          // Filter Chips Horizontal list
          _buildFilterChips(),

          // Notifications List
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // 1. New Scheme Alerts Section
                  if ((_activeFilter == 'All' ||
                          _activeFilter == 'new_schemes') &&
                      newSchemes.isNotEmpty)
                    _buildSection(
                      title: context.l10n.notifNewSchemeAlertsTitle,
                      subtitle: context.l10n.notifNewSchemeAlertsSubtitle,
                      headerIcon: Icons.notifications_active_outlined,
                      headerIconBg: const Color(0xFFE8F5E9),
                      headerIconColor: const Color(0xFF16A34A),
                      cards: newSchemes
                          .map(
                            (item) =>
                                _buildNewSchemeCard(context, item, provider),
                          )
                          .toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'new_schemes';
                        });
                      },
                    ),

                  // 2. Deadline Reminders Section
                  if ((_activeFilter == 'All' ||
                          _activeFilter == 'reminders') &&
                      reminders.isNotEmpty)
                    _buildSection(
                      title: context.l10n.notifDeadlineRemindersTitle,
                      subtitle: context.l10n.notifDeadlineRemindersSubtitle,
                      headerIcon: Icons.calendar_today_outlined,
                      headerIconBg: const Color(0xFFFFEBEE),
                      headerIconColor: const Color(0xFFD32F2F),
                      cards: reminders
                          .map(
                            (item) =>
                                _buildDeadlineCard(context, item, provider),
                          )
                          .toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'reminders';
                        });
                      },
                    ),

                  // 3. Government Updates Section
                  if ((_activeFilter == 'All' || _activeFilter == 'updates') &&
                      updates.isNotEmpty)
                    _buildSection(
                      title: context.l10n.notifGovtUpdatesTitle,
                      subtitle: context.l10n.notifGovtUpdatesSubtitle,
                      headerIcon: Icons.campaign_outlined,
                      headerIconBg: const Color(0xFFEFF6FF),
                      headerIconColor: const Color(0xFF2563EB),
                      cards: updates
                          .map(
                            (item) =>
                                _buildGovtUpdateCard(context, item, provider),
                          )
                          .toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'updates';
                        });
                      },
                    ),

                  // 4. Profile Completion Reminders Section
                  if ((_activeFilter == 'All' || _activeFilter == 'profile') &&
                      profileAlerts.isNotEmpty)
                    _buildSection(
                      title: context.l10n.notifProfileRemindersTitle,
                      subtitle: context.l10n.notifProfileRemindersSubtitle,
                      headerIcon: Icons.person_outline,
                      headerIconBg: const Color(0xFFF3E5F5),
                      headerIconColor: const Color(0xFF7B1FA2),
                      cards: profileAlerts
                          .map(
                            (item) => _buildProfileReminderCard(
                              context,
                              item,
                              provider,
                            ),
                          )
                          .toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'profile';
                        });
                      },
                    ),

                  // Empty State if no notifications match filter
                  if ((_activeFilter == 'new_schemes' && newSchemes.isEmpty) ||
                      (_activeFilter == 'reminders' && reminders.isEmpty) ||
                      (_activeFilter == 'updates' && updates.isEmpty) ||
                      (_activeFilter == 'profile' && profileAlerts.isEmpty) ||
                      list.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_off_outlined,
                              size: 60,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              context.l10n.notifNoMatchingAlerts,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
