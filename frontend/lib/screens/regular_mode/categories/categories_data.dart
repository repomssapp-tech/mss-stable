import 'package:flutter/material.dart';

class CategoryItem {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const CategoryItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}

// Full 23 categories for the "View All" bottom sheet
const List<CategoryItem> allCategoriesList = [
  CategoryItem(
    title: 'Business & MSME',
    description:
        'Subsidized loans, credit guarantees, and setup support for micro, small & medium businesses',
    icon: Icons.domain,
    iconColor: Color(0xFF00796B),
    backgroundColor: Color(0xFFE0F2F1),
  ),
  CategoryItem(
    title: 'Startup & Incubation',
    description:
        'Seed funding, grants, incubation, and equity assistance programs',
    icon: Icons.rocket_launch,
    iconColor: Color(0xFF7B1FA2),
    backgroundColor: Color(0xFFF3E5F5),
  ),
  CategoryItem(
    title: 'Loans & Credit Support',
    description:
        'Collateral-free loans, interest subvention, and institutional credit schemes',
    icon: Icons.monetization_on,
    iconColor: Color(0xFF2563EB),
    backgroundColor: Color(0xFFE0F2FE),
  ),
  CategoryItem(
    title: 'Women Entrepreneurship',
    description:
        'Specialized finance, capital subsidies, and resources for women-owned businesses',
    icon: Icons.person,
    iconColor: Color(0xFFD81B60),
    backgroundColor: Color(0xFFFCE4EC),
  ),
  CategoryItem(
    title: 'Finance & Banking',
    description:
        'Banking linkages, financial inclusion, and formal credit access schemes',
    icon: Icons.account_balance,
    iconColor: Color(0xFF1E88E5),
    backgroundColor: Color(0xFFE3F2FD),
  ),
  CategoryItem(
    title: 'Skill Development',
    description:
        'Free vocational training, certification, and skill upgradation programs',
    icon: Icons.trending_up,
    iconColor: Color(0xFF43A047),
    backgroundColor: Color(0xFFE8F5E9),
  ),
  CategoryItem(
    title: 'Artisan & Craftsmen',
    description:
        'Toolkits distribution, market linkages, and exhibitions for traditional craftspeople',
    icon: Icons.brush,
    iconColor: Color(0xFF6D4C41),
    backgroundColor: Color(0xFFEFEBE9),
  ),
  CategoryItem(
    title: 'Digital India & Tech',
    description:
        'Digital enablement, technology adoption, and e-commerce onboardings',
    icon: Icons.desktop_windows,
    iconColor: Color(0xFF0288D1),
    backgroundColor: Color(0xFFE1F5FE),
  ),
  CategoryItem(
    title: 'Student & Youth Startups',
    description:
        'Student entrepreneurship, innovation challenges, and campus incubations',
    icon: Icons.school_outlined,
    iconColor: Color(0xFF5E35B1),
    backgroundColor: Color(0xFFEDE7F6),
  ),
  CategoryItem(
    title: 'Manufacturing & Industry',
    description:
        'Capital subsidies, Lean manufacturing, and modern tooling assistance',
    icon: Icons.precision_manufacturing,
    iconColor: Color(0xFF3949AB),
    backgroundColor: Color(0xFFE8EAF6),
  ),
  CategoryItem(
    title: 'Export & Trade Promotion',
    description:
        'International exhibitions, export freight support, and global market access',
    icon: Icons.local_shipping,
    iconColor: Color(0xFF00897B),
    backgroundColor: Color(0xFFE0F2F1),
  ),
  CategoryItem(
    title: 'Agriculture & Allied',
    description:
        'Agri-tech, post-harvest infrastructure, and farmer producer support',
    icon: Icons.agriculture,
    iconColor: Color(0xFF2E7D32),
    backgroundColor: Color(0xFFE8F5E9),
  ),
  CategoryItem(
    title: 'Rural Development & SHG',
    description:
        'Self-help groups, community enterprises, and rural livelihood missions',
    icon: Icons.groups,
    iconColor: Color(0xFFE65100),
    backgroundColor: Color(0xFFFFF3E0),
  ),
  CategoryItem(
    title: 'Technology & Innovation',
    description:
        'R&D grants, patent filing reimbursements, and tech transfer support',
    icon: Icons.biotech,
    iconColor: Color(0xFF6A1B9A),
    backgroundColor: Color(0xFFF3E5F5),
  ),
  CategoryItem(
    title: 'Khadi & Village Industries',
    description:
        'PMEGP, honey mission, pottery, and rural khadi industry promotion',
    icon: Icons.store,
    iconColor: Color(0xFF8D6E63),
    backgroundColor: Color(0xFFD7CCC8),
  ),
  CategoryItem(
    title: 'SC / ST & Minority',
    description:
        'Concessional credit, capacity building, and preferential procurement',
    icon: Icons.diversity_3,
    iconColor: Color(0xFF00838F),
    backgroundColor: Color(0xFFE0F7FA),
  ),
  CategoryItem(
    title: 'Green Energy & Environment',
    description:
        'Cleaner tech adoption, energy conservation audits, and solar subsidies',
    icon: Icons.eco,
    iconColor: Color(0xFF558B2F),
    backgroundColor: Color(0xFFF1F8E9),
  ),
  CategoryItem(
    title: 'Health & Healthcare',
    description:
        'Ayushman Bharat, medical enterprise support, and wellness initiatives',
    icon: Icons.local_hospital,
    iconColor: Color(0xFFC2185B),
    backgroundColor: Color(0xFFFCE4EC),
  ),
  CategoryItem(
    title: 'Food Processing',
    description:
        'PMFME micro food enterprises, cold chain, and food safety certifications',
    icon: Icons.restaurant,
    iconColor: Color(0xFFD84315),
    backgroundColor: Color(0xFFFBE9E7),
  ),
  CategoryItem(
    title: 'Education & Fellowship',
    description:
        'Higher education grants, women researcher fellowships, and skill certs',
    icon: Icons.menu_book,
    iconColor: Color(0xFF1565C0),
    backgroundColor: Color(0xFFE3F2FD),
  ),
  CategoryItem(
    title: 'Infrastructure & Logistics',
    description:
        'Industrial park relocation, cluster development, and logistics support',
    icon: Icons.apartment,
    iconColor: Color(0xFF455A64),
    backgroundColor: Color(0xFFECEFF1),
  ),
  CategoryItem(
    title: 'Social Welfare & Support',
    description:
        'Maternity relief, rehabilitation, and social security assistances',
    icon: Icons.volunteer_activism,
    iconColor: Color(0xFFAD1457),
    backgroundColor: Color(0xFFFCE4EC),
  ),
  CategoryItem(
    title: 'Renewable & Energy Efficiency',
    description:
        'Solar power units, power backup subsidies, and green energy loans',
    icon: Icons.solar_power,
    iconColor: Color(0xFFF57F17),
    backgroundColor: Color(0xFFFFFDE7),
  ),
];

// Core curated horizontal collections matching mockup
const List<Map<String, dynamic>> displayCategories = [
  {
    'title': 'Business & MSME',
    'icon': Icons.domain,
    'color': Color(0xFF2563EB),
  },
  {
    'title': 'Startup & Incubation',
    'icon': Icons.rocket_launch,
    'color': Color(0xFF2563EB),
  },
  {
    'title': 'Loans & Credit Support',
    'icon': Icons.monetization_on,
    'color': Color(0xFF2563EB),
  },
  {
    'title': 'Women Entrepreneurship',
    'icon': Icons.person,
    'color': Color(0xFF2563EB),
  },
];

const List<Map<String, dynamic>> displayMinistries = [
  {'title': 'Ministry of MSME'},
  {'title': 'Ministry of Finance'},
  {'title': 'Ministry of Rural Development'},
];

const List<Map<String, dynamic>> displayStates = [
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

const List<String> allStatesList = [
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
