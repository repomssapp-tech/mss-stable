/// EmblemHelper — Centralized emblem asset resolver for state and central government schemes.
class EmblemHelper {
  EmblemHelper._();

  static String getEmblemAsset({
    required String governmentLevel,
    required String state,
    required String schemeCode,
    required String sponsoringBody,
    required String name,
  }) {
    final govLevel = governmentLevel.toLowerCase().trim();
    final st = state.toLowerCase().trim();
    final code = schemeCode.toLowerCase().trim();
    final sponsor = sponsoringBody.toLowerCase().trim();

    // 1. Central / All India / National schemes default to the Indian Emblem
    if (govLevel == 'central' ||
        st == 'all india' ||
        st == 'central' ||
        st == 'india' ||
        st == 'national' ||
        st.isEmpty) {
      // Unless a specific state is explicitly named in the state field
      if (st.isEmpty ||
          st == 'all india' ||
          st == 'central' ||
          st == 'india' ||
          st == 'national') {
        return 'assets/images/States assets/Indian emblem.webp';
      }
    }

    // 2. Explicit State Matching (based on state name, sponsoring body, or exact state prefix like "tn_")
    if (st.contains('tamil nadu') ||
        code.startsWith('tn_') ||
        sponsor.contains('tamil nadu')) {
      return 'assets/images/States assets/State Emblem/Tamil Nadu.webp';
    }
    if (st.contains('andhra') ||
        code.startsWith('ap_') ||
        sponsor.contains('andhra')) {
      return 'assets/images/States assets/State Emblem/Andhra Pradesh.webp';
    }
    if (st.contains('arunachal') ||
        code.startsWith('ar_') ||
        sponsor.contains('arunachal')) {
      return 'assets/images/States assets/State Emblem/Arunachal Pradesh.webp';
    }
    if (st.contains('assam') ||
        code.startsWith('as_') ||
        sponsor.contains('assam')) {
      return 'assets/images/States assets/State Emblem/Assam.webp';
    }
    if (st.contains('bihar') ||
        code.startsWith('br_') ||
        sponsor.contains('bihar')) {
      return 'assets/images/States assets/State Emblem/Bihar.webp';
    }
    if (st.contains('chhattisgarh') ||
        st.contains('chhatisgarh') ||
        code.startsWith('cg_') ||
        sponsor.contains('chhattisgarh')) {
      return 'assets/images/States assets/State Emblem/Chhatisgarh.webp';
    }
    if (st.contains('goa') ||
        code.startsWith('ga_') ||
        sponsor.contains('goa')) {
      return 'assets/images/States assets/State Emblem/Goa.webp';
    }
    if (st.contains('gujarat') ||
        code.startsWith('gj_') ||
        sponsor.contains('gujarat')) {
      return 'assets/images/States assets/State Emblem/Gujarat.webp';
    }
    if (st.contains('haryana') ||
        code.startsWith('hr_') ||
        sponsor.contains('haryana')) {
      return 'assets/images/States assets/State Emblem/Haryana.webp';
    }
    if (st.contains('himachal') ||
        code.startsWith('hp_') ||
        sponsor.contains('himachal')) {
      return 'assets/images/States assets/State Emblem/Himachal Pradesh.webp';
    }
    if (st.contains('jharkhand') ||
        code.startsWith('jh_') ||
        sponsor.contains('jharkhand')) {
      return 'assets/images/States assets/State Emblem/Jharkhand.webp';
    }
    if (st.contains('karnataka') ||
        code.startsWith('ka_') ||
        sponsor.contains('karnataka')) {
      return 'assets/images/States assets/State Emblem/Karnataka.webp';
    }
    if (st.contains('kerala') ||
        code.startsWith('kl_') ||
        sponsor.contains('kerala')) {
      return 'assets/images/States assets/State Emblem/kerala.webp';
    }
    if (st.contains('madhya pradesh') ||
        code.startsWith('mp_') ||
        sponsor.contains('madhya pradesh')) {
      return 'assets/images/States assets/State Emblem/Madhya Pradesh.webp';
    }
    if (st.contains('maharashtra') ||
        code.startsWith('mh_') ||
        sponsor.contains('maharashtra')) {
      return 'assets/images/States assets/State Emblem/Maharashtra.webp';
    }
    if (st.contains('manipur') ||
        code.startsWith('mn_') ||
        sponsor.contains('manipur')) {
      return 'assets/images/States assets/State Emblem/Manipur.webp';
    }
    if (st.contains('meghalaya') ||
        st.contains('maghalaya') ||
        code.startsWith('ml_') ||
        sponsor.contains('meghalaya')) {
      return 'assets/images/States assets/State Emblem/Maghalaya.webp';
    }
    if (st.contains('mizoram') ||
        code.startsWith('mz_') ||
        sponsor.contains('mizoram')) {
      return 'assets/images/States assets/State Emblem/Mizoram.webp';
    }
    if (st.contains('nagaland') ||
        code.startsWith('nl_') ||
        sponsor.contains('nagaland')) {
      return 'assets/images/States assets/State Emblem/Nagaland.webp';
    }
    if (st.contains('odisha') ||
        st.contains('orissa') ||
        code.startsWith('od_') ||
        code.startsWith('or_') ||
        sponsor.contains('odisha')) {
      return 'assets/images/States assets/State Emblem/Odisha.webp';
    }
    if (st.contains('punjab') ||
        code.startsWith('pb_') ||
        sponsor.contains('punjab')) {
      return 'assets/images/States assets/State Emblem/Punjab.webp';
    }
    if (st.contains('rajasthan') ||
        code.startsWith('rj_') ||
        sponsor.contains('rajasthan')) {
      return 'assets/images/States assets/State Emblem/Rajasthan.webp';
    }
    if (st.contains('sikkim') ||
        code.startsWith('sk_') ||
        sponsor.contains('sikkim')) {
      return 'assets/images/States assets/State Emblem/Sikkim.webp';
    }
    if (st.contains('telangana') ||
        st.contains('telagana') ||
        code.startsWith('tg_') ||
        sponsor.contains('telangana')) {
      return 'assets/images/States assets/State Emblem/Telagana.webp';
    }
    if (st.contains('tripura') ||
        code.startsWith('tr_') ||
        sponsor.contains('tripura')) {
      return 'assets/images/States assets/State Emblem/Tripura.webp';
    }
    if (st.contains('uttar pradesh') ||
        code.startsWith('up_') ||
        sponsor.contains('uttar pradesh')) {
      return 'assets/images/States assets/State Emblem/Uttar Pradesh.webp';
    }
    if (st.contains('uttarakhand') ||
        st.contains('uttarkhand') ||
        code.startsWith('uk_') ||
        code.startsWith('ua_') ||
        sponsor.contains('uttarakhand')) {
      return 'assets/images/States assets/State Emblem/Uttarakhand.webp';
    }
    if (st.contains('west bengal') ||
        code.startsWith('wb_') ||
        sponsor.contains('west bengal')) {
      return 'assets/images/States assets/State Emblem/West Bengal.webp';
    }

    // 3. Fallback to Indian Emblem
    return 'assets/images/States assets/Indian emblem.webp';
  }
}
