import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../services/location_lock/location_lock.dart';

class CategoryItem {
  final String title;
  final String description;
  final IconData icon;

  const CategoryItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

// Full 23 categories for the "View All" bottom sheet
const List<CategoryItem> allCategoriesList = [
  CategoryItem(
    title: 'Business & MSME',
    description:
        'Subsidized loans, credit guarantees, and setup support for micro, small & medium businesses',
    icon: Icons.domain,
  ),
  CategoryItem(
    title: 'Startup & Incubation',
    description:
        'Seed funding, grants, incubation, and equity assistance programs',
    icon: Icons.lightbulb_outline_rounded,
  ),
  CategoryItem(
    title: 'Loans & Credit Support',
    description:
        'Collateral-free loans, interest subvention, and institutional credit schemes',
    icon: Icons.monetization_on,
  ),
  CategoryItem(
    title: 'Women Entrepreneurship',
    description:
        'Specialized finance, capital subsidies, and resources for women-owned businesses',
    icon: Icons.person,
  ),
  CategoryItem(
    title: 'Finance & Banking',
    description:
        'Banking linkages, financial inclusion, and formal credit access schemes',
    icon: Icons.account_balance,
  ),
  CategoryItem(
    title: 'Skill Development',
    description:
        'Free vocational training, certification, and skill upgradation programs',
    icon: Icons.trending_up,
  ),
  CategoryItem(
    title: 'Artisan & Craftsmen',
    description:
        'Toolkits distribution, market linkages, and exhibitions for traditional craftspeople',
    icon: Icons.brush,
  ),
  CategoryItem(
    title: 'Digital India & Tech',
    description:
        'Digital enablement, technology adoption, and e-commerce onboardings',
    icon: Icons.desktop_windows,
  ),
  CategoryItem(
    title: 'Student & Youth Startups',
    description:
        'Student entrepreneurship, innovation challenges, and campus incubations',
    icon: Icons.school_outlined,
  ),
  CategoryItem(
    title: 'Manufacturing & Industry',
    description:
        'Capital subsidies, Lean manufacturing, and modern tooling assistance',
    icon: Icons.precision_manufacturing,
  ),
  CategoryItem(
    title: 'Export & Trade Promotion',
    description:
        'International exhibitions, export freight support, and global market access',
    icon: Icons.local_shipping,
  ),
  CategoryItem(
    title: 'Agriculture & Allied',
    description:
        'Agri-tech, post-harvest infrastructure, and farmer producer support',
    icon: Icons.agriculture,
  ),
  CategoryItem(
    title: 'Rural Development & SHG',
    description:
        'Self-help groups, community enterprises, and rural livelihood missions',
    icon: Icons.groups,
  ),
  CategoryItem(
    title: 'Technology & Innovation',
    description:
        'R&D grants, patent filing reimbursements, and tech transfer support',
    icon: Icons.biotech,
  ),
  CategoryItem(
    title: 'Khadi & Village Industries',
    description:
        'PMEGP, honey mission, pottery, and rural khadi industry promotion',
    icon: Icons.store,
  ),
  CategoryItem(
    title: 'SC / ST & Minority',
    description:
        'Concessional credit, capacity building, and preferential procurement',
    icon: Icons.diversity_3,
  ),
  CategoryItem(
    title: 'Green Energy & Environment',
    description:
        'Cleaner tech adoption, energy conservation audits, and solar subsidies',
    icon: Icons.eco,
  ),
  CategoryItem(
    title: 'Health & Healthcare',
    description:
        'Ayushman Bharat, medical enterprise support, and wellness initiatives',
    icon: Icons.local_hospital,
  ),
  CategoryItem(
    title: 'Food Processing',
    description:
        'PMFME micro food enterprises, cold chain, and food safety certifications',
    icon: Icons.restaurant,
  ),
  CategoryItem(
    title: 'Education & Fellowship',
    description:
        'Higher education grants, women researcher fellowships, and skill certs',
    icon: Icons.menu_book,
  ),
  CategoryItem(
    title: 'Infrastructure & Logistics',
    description:
        'Industrial park relocation, cluster development, and logistics support',
    icon: Icons.apartment,
  ),
  CategoryItem(
    title: 'Social Welfare & Support',
    description:
        'Maternity relief, rehabilitation, and social security assistances',
    icon: Icons.volunteer_activism,
  ),
  CategoryItem(
    title: 'Renewable & Energy Efficiency',
    description:
        'Solar power units, power backup subsidies, and green energy loans',
    icon: Icons.solar_power,
  ),
];

// Core curated horizontal collections matching mockup
const List<Map<String, dynamic>> displayCategories = [
  {
    'title': 'Business & MSME',
    'icon': Icons.domain,
    'color': AppColors.primary,
  },
  {
    'title': 'Startup & Incubation',
    'icon': Icons.lightbulb_outline_rounded,
    'color': AppColors.primary,
  },
  {
    'title': 'Loans & Credit Support',
    'icon': Icons.monetization_on,
    'color': AppColors.primary,
  },
  {
    'title': 'Women Entrepreneurship',
    'icon': Icons.person,
    'color': AppColors.primary,
  },
];

const List<Map<String, dynamic>> displayMinistries = [
  {'title': 'Ministry of MSME'},
  {'title': 'Ministry of Finance'},
  {'title': 'Ministry of Rural Development'},
];

/// The Discover state tiles; only the GPS state under the location lock.
List<Map<String, dynamic>> get displayStates {
  final state = LocationScope.stateName;
  if (state == null) return _displayStates;
  return [
    {'title': state},
  ];
}

const List<Map<String, dynamic>> _displayStates = [
  {'title': 'Tamil Nadu'},
  {'title': 'Maharashtra'},
  {'title': 'Uttar Pradesh'},
  {'title': 'Karnataka'},
  {'title': 'Gujarat'},
];

const List<String> allMinistriesList = [
  'Ministry of MSME',
  'Ministry of Education',
  'Ministry of Finance',
  'Ministry of Agriculture',
  'Ministry of Rural Development',
  'Ministry of Skill Development',
  'Ministry of Social Justice',
  'Ministry of Housing',
];

/// Every state for the "view all" sheets; only the GPS state under the
/// location lock.
List<String> get allStatesList => LocationScope.restrictStates(_allStatesList);

const List<String> _allStatesList = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Delhi',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jammu & Kashmir',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Ladakh',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Puducherry',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];

String getStateMapAsset(String stateName) {
  final rawPath = getStateMapAssetRaw(stateName);
  return rawPath.replaceAll(
    'assets/images/States and UTs/',
    'assets/images/States assets/',
  );
}

String getStateMapAssetRaw(String stateName) {
  switch (stateName.toLowerCase().trim()) {
    case 'tamil nadu':
      return 'assets/images/States and UTs/States/Tamil nadu.webp';
    case 'maharashtra':
      return 'assets/images/States and UTs/States/maharashtra.webp';
    case 'uttar pradesh':
      return 'assets/images/States and UTs/States/uttar_pradesh.webp';
    case 'karnataka':
      return 'assets/images/States and UTs/States/karnataka.webp';
    case 'gujarat':
      return 'assets/images/States and UTs/States/gujarat.webp';
    case 'arunachal pradesh':
      return 'assets/images/States and UTs/States/Anrunachal pradhesh.webp';
    case 'assam':
      return 'assets/images/States and UTs/States/Assam.webp';
    case 'bihar':
      return 'assets/images/States and UTs/States/Bihar.webp';
    case 'chhattisgarh':
      return 'assets/images/States and UTs/States/Chhatishgar.webp';
    case 'kerala':
      return 'assets/images/States and UTs/States/Kerala.webp';
    case 'andhra pradesh':
      return 'assets/images/States and UTs/States/andhra pradesh.webp';
    case 'goa':
      return 'assets/images/States and UTs/States/goa.webp';
    case 'haryana':
      return 'assets/images/States and UTs/States/haryana.webp';
    case 'himachal pradesh':
      return 'assets/images/States and UTs/States/himachal pradesh.webp';
    case 'jharkhand':
      return 'assets/images/States and UTs/States/jharkhand.webp';
    case 'madhya pradesh':
      return 'assets/images/States and UTs/States/madhya pradesh.webp';
    case 'manipur':
      return 'assets/images/States and UTs/States/manipur.webp';
    case 'meghalaya':
      return 'assets/images/States and UTs/States/meghalaya.webp';
    case 'mizoram':
      return 'assets/images/States and UTs/States/mizoram.webp';
    case 'nagaland':
      return 'assets/images/States and UTs/States/nagaland.webp';
    case 'odisha':
      return 'assets/images/States and UTs/States/odisha.webp';
    case 'punjab':
      return 'assets/images/States and UTs/States/punjab.webp';
    case 'rajasthan':
      return 'assets/images/States and UTs/States/rajasthan.webp';
    case 'sikkim':
      return 'assets/images/States and UTs/States/sikkim.webp';
    case 'telangana':
      return 'assets/images/States and UTs/States/telangana.webp';
    case 'tripura':
      return 'assets/images/States and UTs/States/tripura.webp';
    case 'uttarakhand':
    case 'uttarkhand':
      return 'assets/images/States and UTs/States/uttarkhand.webp';
    case 'west bengal':
      return 'assets/images/States and UTs/States/west bengal.webp';
    default:
      return 'assets/images/States and UTs/States/Tamil nadu.webp';
  }
}
