import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../l10n/l10n.dart';
import '../utils/app_spacing.dart';

class FilterPanel extends StatefulWidget {
  final VoidCallback? onApplied;
  const FilterPanel({super.key, this.onApplied});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  // State variables for all filters in the mockup
  late String _state;
  late String _district;
  late String _ministry;
  late String _department;
  late String _category;

  late String _income;
  late String _gender;
  late String _age;
  late String _community;
  late String _occupation;
  late String _education;
  late bool _firstGen;
  late String _disability;

  late String _schemeStatus;
  late String _onlineOffline;
  late String _schemeType;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Initialize state from existing provider filters or defaults
    _state = provider.filters['state'] ?? '';
    if (_state == 'All') _state = '';
    _district = provider.filters['district'] ?? '';
    if (_district == 'All') _district = '';
    _ministry = provider.filters['ministry'] ?? '';
    if (_ministry == 'All') _ministry = '';
    _department = provider.filters['department'] ?? '';
    if (_department == 'All') _department = '';
    _category = provider.filters['category'] ?? '';
    if (_category == 'All') _category = '';

    _income = provider.filters['income'] ?? '';
    if (_income == 'All') _income = '';
    _gender = provider.filters['gender'] ?? '';
    if (_gender == 'All') _gender = '';
    _age = provider.filters['age'] ?? '';
    if (_age == 'All') _age = '';
    _community = provider.filters['community'] ?? '';
    if (_community == 'All') _community = '';
    _occupation = provider.filters['occupation'] ?? '';
    if (_occupation == 'All') _occupation = '';
    _education = provider.filters['education'] ?? '';
    if (_education == 'All') _education = '';
    _firstGen = provider.filters['firstGen'] == true;
    _disability = provider.filters['disability'] ?? '';
    if (_disability == 'All') _disability = '';

    // Auto-select 'No Income' for students if income is not already chosen
    final userOccupation = _occupation.isNotEmpty
        ? _occupation
        : provider.profile.employmentStatus;
    if (userOccupation.toLowerCase() == 'student' && _income.isEmpty) {
      _income = 'No Income';
    }

    _schemeStatus = provider.filters['schemeStatus'] ?? '';
    if (_schemeStatus == 'All') _schemeStatus = '';
    _onlineOffline = provider.filters['onlineOffline'] ?? '';
    if (_onlineOffline == 'All') _onlineOffline = '';
    _schemeType = provider.filters['schemeType'] ?? '';
    if (_schemeType == 'All') _schemeType = '';
  }

  void _applyFilters() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.updateFilter('state', _state);
    provider.updateFilter('district', _district);
    provider.updateFilter('ministry', _ministry);
    provider.updateFilter('department', _department);
    provider.updateFilter('category', _category);

    provider.updateFilter('income', _income);
    provider.updateFilter('gender', _gender);
    provider.updateFilter('age', _age);
    provider.updateFilter('community', _community);
    provider.updateFilter('occupation', _occupation);
    provider.updateFilter('education', _education);
    provider.updateFilter('firstGen', _firstGen);
    provider.updateFilter('disability', _disability);

    provider.updateFilter('schemeStatus', _schemeStatus);
    provider.updateFilter('onlineOffline', _onlineOffline);
    provider.updateFilter('schemeType', _schemeType);

    Navigator.pop(context);
    if (widget.onApplied != null) {
      widget.onApplied!();
    }
  }

  void _resetFilters() {
    setState(() {
      _state = '';
      _district = '';
      _ministry = '';
      _department = '';
      _category = '';

      _income = '';
      _gender = '';
      _age = '';
      _community = '';
      _occupation = '';
      _education = '';
      _firstGen = false;
      _disability = '';

      _schemeStatus = '';
      _onlineOffline = '';
      _schemeType = '';
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_state.isNotEmpty && _state != 'All') count++;
    if (_district.isNotEmpty && _district != 'All') count++;
    if (_ministry.isNotEmpty && _ministry != 'All') count++;
    if (_department.isNotEmpty && _department != 'All') count++;
    if (_category.isNotEmpty && _category != 'All') count++;

    if (_income.isNotEmpty && _income != 'All') count++;
    if (_gender.isNotEmpty && _gender != 'All') count++;
    if (_age.isNotEmpty && _age != 'All') count++;
    if (_community.isNotEmpty && _community != 'All') count++;
    if (_occupation.isNotEmpty && _occupation != 'All') count++;
    if (_education.isNotEmpty && _education != 'All') count++;
    if (_firstGen) count++;
    if (_disability.isNotEmpty && _disability != 'All') count++;

    if (_schemeStatus.isNotEmpty && _schemeStatus != 'All') count++;
    if (_onlineOffline.isNotEmpty && _onlineOffline != 'All') count++;
    if (_schemeType.isNotEmpty && _schemeType != 'All') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _getActiveFilterCount();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        gradient: AppConstants.blueGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Filter Schemes',
                    softWrap: true,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: GestureDetector(
                    onTap: _resetFilters,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FitOneLine(
                            child: Text(
                              context.l10n.filterClearAll,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.refresh,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Filter Form Fields
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Location Section
                  _buildSectionHeader('Location'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDropdownCell(
                            icon: Icons.location_on_outlined,
                            iconColor: const Color(0xFF2563EB),
                            iconBgColor: const Color(0xFFEFF6FF),
                            label: context.l10n.filterState,
                            value: _state,
                            items: [
                              'Tamil Nadu',
                              'Karnataka',
                              'Kerala',
                              'Maharashtra',
                              'Delhi',
                            ],
                            onChanged: (val) =>
                                setState(() => _state = val ?? ''),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildDropdownCell(
                            icon: Icons.apartment_outlined,
                            iconColor: const Color(0xFF2563EB),
                            iconBgColor: const Color(0xFFEFF6FF),
                            label: context.l10n.filterDistrict,
                            value: _district,
                            items: [
                              'Chennai',
                              'Bangalore',
                              'Cochin',
                              'Mumbai',
                              'New Delhi',
                            ],
                            onChanged: (val) =>
                                setState(() => _district = val ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Organization Section
                  _buildSectionHeader('Organization'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDropdownCell(
                            icon: Icons.account_balance_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            iconBgColor: const Color(0xFFF5F3FF),
                            label: context.l10n.filterMinistry,
                            value: _ministry,
                            items: [
                              'Ministry of MSME',
                              'Ministry of Agriculture',
                              'Ministry of Finance',
                              'Ministry of Education',
                            ],
                            onChanged: (val) =>
                                setState(() => _ministry = val ?? ''),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildDropdownCell(
                            icon: Icons.folder_open_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            iconBgColor: const Color(0xFFF5F3FF),
                            label: context.l10n.filterDepartment,
                            value: _department,
                            items: [
                              'Dept of MSME Development',
                              'Dept of Agriculture Cooperation',
                              'Dept of Higher Education',
                            ],
                            onChanged: (val) =>
                                setState(() => _department = val ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.grid_view_outlined,
                          iconColor: const Color(0xFF16A34A),
                          iconBgColor: const Color(0xFFF0FDF4),
                          label: context.l10n.filterCategory,
                          value: _category,
                          items: [
                            'Business & MSME',
                            'Startup',
                            'Finance',
                            'Women & Child Welfare',
                            'Artisan',
                          ],
                          onChanged: (val) =>
                              setState(() => _category = val ?? ''),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: SizedBox(),
                        ), // Push to left, take exactly half width
                      ],
                    ),
                  ),

                  // 3. Personal Details Section
                  _buildSectionHeader('Personal Details'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.wallet_outlined,
                          iconColor: const Color(0xFFEA580C),
                          iconBgColor: const Color(0xFFFFF7ED),
                          label: context.l10n.labelAnnualIncome,
                          value: _income,
                          items: [
                            'No Income',
                            'Under ₹1 Lakh',
                            'Under ₹5 Lakhs',
                            'Under ₹10 Lakhs',
                            'Under ₹50 Lakhs',
                          ],
                          onChanged: (val) =>
                              setState(() => _income = val ?? ''),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDropdownCell(
                            icon: Icons.person_outline,
                            iconColor: const Color(0xFFDB2777),
                            iconBgColor: const Color(0xFFFDF2F8),
                            label: context.l10n.labelGender,
                            value: _gender,
                            items: ['Female', 'Male', 'Transgender'],
                            onChanged: (val) =>
                                setState(() => _gender = val ?? ''),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildDropdownCell(
                            icon: Icons.calendar_month_outlined,
                            iconColor: const Color(0xFF0D9488),
                            iconBgColor: const Color(0xFFF0FDFA),
                            label: context.l10n.labelAge,
                            value: _age,
                            items: [
                              'Under 18',
                              '18 - 35',
                              '36 - 60',
                              'Above 60',
                            ],
                            onChanged: (val) =>
                                setState(() => _age = val ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDropdownCell(
                            icon: Icons.people_outline,
                            iconColor: const Color(0xFF7C3AED),
                            iconBgColor: const Color(0xFFF5F3FF),
                            label: context.l10n.labelCommunity,
                            value: _community,
                            items: ['General', 'OBC', 'EWS', 'SC', 'ST'],
                            onChanged: (val) =>
                                setState(() => _community = val ?? ''),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildDropdownCell(
                            icon: Icons.business_center_outlined,
                            iconColor: const Color(0xFF2563EB),
                            iconBgColor: const Color(0xFFEFF6FF),
                            label: context.l10n.labelOccupation,
                            value: _occupation,
                            items: [
                              'Unemployed',
                              'Student',
                              'Farmer',
                              'Self Employed / Business',
                              'Salaried',
                              'Artisan / Craftsman',
                            ],
                            onChanged: (val) => setState(() {
                              _occupation = val ?? '';
                              if (_occupation == 'Student' &&
                                  _income.isEmpty) {
                                _income = 'No Income';
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDropdownCell(
                            icon: Icons.school_outlined,
                            iconColor: const Color(0xFF16A34A),
                            iconBgColor: const Color(0xFFF0FDF4),
                            label: context.l10n.labelEducation,
                            value: _education,
                            items: [
                              'Under 10th',
                              '12th Pass',
                              'Graduate',
                              'Post Graduate',
                            ],
                            onChanged: (val) =>
                                setState(() => _education = val ?? ''),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildSwitchCell(
                            icon: Icons.workspace_premium_outlined,
                            iconColor: const Color(0xFFEA580C),
                            iconBgColor: const Color(0xFFFFF7ED),
                            label: context.l10n.labelFirstGenGraduate,
                            value: _firstGen,
                            onChanged: (val) => setState(() => _firstGen = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.accessible_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          iconBgColor: const Color(0xFFF5F3FF),
                          label: context.l10n.labelDisability,
                          value: _disability,
                          items: [
                            'None',
                            'Locomotor',
                            'Visual',
                            'Hearing',
                            'Other',
                          ],
                          onChanged: (val) =>
                              setState(() => _disability = val ?? ''),
                        ),
                      ],
                    ),
                  ),
                  // 4. Scheme Preferences Section
                  _buildSectionHeader('Scheme Preferences'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDropdownCell(
                            icon: Icons.check_circle_outline,
                            iconColor: const Color(0xFF2563EB),
                            iconBgColor: const Color(0xFFEFF6FF),
                            label: context.l10n.filterSchemeStatus,
                            value: _schemeStatus,
                            items: ['Active', 'Closed'],
                            onChanged: (val) =>
                                setState(() => _schemeStatus = val ?? ''),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildDropdownCell(
                            icon: Icons.language_outlined,
                            iconColor: const Color(0xFF16A34A),
                            iconBgColor: const Color(0xFFF0FDF4),
                            label: context.l10n.filterOnlineOffline,
                            value: _onlineOffline,
                            items: [
                              'Online Application',
                              'Offline Application',
                            ],
                            onChanged: (val) =>
                                setState(() => _onlineOffline = val ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.account_balance_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          iconBgColor: const Color(0xFFF5F3FF),
                          label: context.l10n.filterCentralStateScheme,
                          value: _schemeType,
                          items: [
                            'Central Government',
                            'State Government',
                          ],
                          onChanged: (val) =>
                              setState(() => _schemeType = val ?? ''),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),

          // Fixed Action Footer
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _resetFilters,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFEFF6FF,
                        ), // Light blue 50
                        foregroundColor: const Color(0xFF2563EB), // Royal Blue
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB), // Royal Blue
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Apply Filters ($activeCount)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E3A8A), // Deep Royal Navy
        ),
      ),
    );
  }

  Widget _buildDropdownCell({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isUnset = value.isEmpty || value == 'All';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.hairline),
                      Text(
                        isUnset ? 'Select $label' : value,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isUnset ? FontWeight.w500 : FontWeight.bold,
                          color: isUnset
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.0,
                child: DropdownButton<String>(
                  value: items.contains(value) ? value : null,
                  hint: Text(
                    'Select $label',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  icon: const SizedBox.shrink(),
                  underline: const SizedBox.shrink(),
                  items: items.map((String item) {
                    final isSelected = item == value;
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: Color(0xFF2563EB),
                              size: 14,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCell({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    value ? 'Yes' : 'Select Option',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.7,
              alignment: Alignment.centerRight,
              child: Switch(
                value: value,
                activeThumbColor: const Color(0xFF2563EB),
                activeTrackColor: const Color(0xFF2563EB).withAlpha(76),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
