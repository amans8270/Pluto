/// Hardcoded Demo Profiles for Onboarding
/// These profiles rotate and teach users how to use Pluto.

const List<Map<String, dynamic>> demoProfiles = [
  {
    'id': 'demo_swipe',
    'display_name': 'Pluto Guide: Swiping',
    'age': 20,
    'bio': 'Welcome to Pluto! 🚀\n\nSwipe RIGHT if you like someone.\nSwipe LEFT to pass.\nTry swiping me right to continue!',
    'gender': 'OTHER',
    'occupation': 'System Guide',
    'photos': [
      {'id': 'ph_demo1', 'gcs_url': 'assets/images/demo/swipe_guide.png', 'display_order': 0}
    ],
    'interests': ['Swiping', 'Tutorial'],
    'dist_km': 0.0,
    'is_demo': true,
    'demo_feature': 'swipe',
  },
  {
    'id': 'demo_chat',
    'display_name': 'Pluto Guide: Matching',
    'age': 20,
    'bio': 'Matching is easy! 💬\n\nWhen you both swipe right on each other, it\'s a MATCH! You can then start chatting instantly.',
    'gender': 'OTHER',
    'occupation': 'System Guide',
    'photos': [
      {'id': 'ph_demo2', 'gcs_url': 'assets/images/demo/chat_guide.png', 'display_order': 0}
    ],
    'interests': ['Chatting', 'Connections'],
    'dist_km': 0.0,
    'is_demo': true,
    'demo_feature': 'match_chat',
  },
  {
    'id': 'demo_travel',
    'display_name': 'Pluto Guide: Travel',
    'age': 20,
    'bio': 'Explore the world! 🌍\n\nSwitch to "Travel Buddy" mode to find people to explore new cities with. Perfect for your next trip!',
    'gender': 'OTHER',
    'occupation': 'System Guide',
    'photos': [
      {'id': 'ph_demo3', 'gcs_url': 'assets/images/demo/travel_guide.png', 'display_order': 0}
    ],
    'interests': ['Travel', 'Adventure'],
    'dist_km': 0.0,
    'is_demo': true,
    'demo_feature': 'travel_buddy',
  },
  {
    'id': 'demo_profile',
    'display_name': 'Pluto Guide: Profile',
    'age': 20,
    'bio': 'Stand out! ✨\n\nComplete your profile with great photos and a fun bio to get 3x more matches. Don\'t forget to add your interests!',
    'gender': 'OTHER',
    'occupation': 'System Guide',
    'photos': [
      {'id': 'ph_demo4', 'gcs_url': 'assets/images/demo/profile_guide.png', 'display_order': 0}
    ],
    'interests': ['Self Expression', 'Photos'],
    'dist_km': 0.0,
    'is_demo': true,
    'demo_feature': 'profile_customization',
  },
  {
    'id': 'demo_safety',
    'display_name': 'Pluto Guide: Safety',
    'age': 20,
    'bio': 'Stay safe! 🛡️\n\nYour safety is our priority. You can block or report anyone from their profile or chat. Always meet in public places!',
    'gender': 'OTHER',
    'occupation': 'System Guide',
    'photos': [
      {'id': 'ph_demo5', 'gcs_url': 'assets/images/demo/safety_guide.png', 'display_order': 0}
    ],
    'interests': ['Safety', 'Respect'],
    'dist_km': 0.0,
    'is_demo': true,
    'demo_feature': 'safety',
  },
];
