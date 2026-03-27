import 'package:flutter/material.dart';

class InterestCategory {
  final String id;
  final String label;
  final IconData icon;
  final List<String> interests;

  const InterestCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.interests,
  });
}

const List<InterestCategory> interestCategories = [
  InterestCategory(
    id: 'food',
    label: 'Food & Drinks',
    icon: Icons.fastfood,
    interests: [
      'Snack break', 'French fries', 'Cocktails', 'Craft beer', 'Pani puri lover',
      'Wine and more wine', 'BBQ', 'Foodie', 'BBQ sauce', 'Cheese',
      'Chai connoisseur', 'Magic Maggie maker', 'Caffeine', 'The more cheese the better',
      'Brunch', 'Pizza lover', 'Ramen', 'Chicken addict', 'Healthy 🥦',
      'Hummus is the new caviar', 'Pasta or nothing', 'Spicy food',
      'Chocolate addict', 'Street food', 'Alcohol-free'
    ],
  ),
  InterestCategory(
    id: 'home',
    label: 'At home',
    icon: Icons.home,
    interests: [
      'Marie Kondo', 'Serial Board gambler', 'Singing in the shower', 'Plant parent',
      'Making music', 'Afternoon nap', 'Cozy', 'Netflix & Chill', 'Gardening',
      'Ikea hacks', 'Couch potato', 'Ceramics', 'Spying on my neighbors',
      'Meditation', 'Fashion', 'House cat', 'Petting my cat', 'Creativity',
      'Sleeping in', 'Dyson addict', 'Board games', 'Cooking', 'Staying in a bathrobe'
    ],
  ),
  InterestCategory(
    id: 'music',
    label: 'Music',
    icon: Icons.music_note,
    interests: [
      'East Coast', 'Bad Bunny', 'The Weeknd', 'Reggae', 'Mellow pop-star',
      'West Coast', 'Arijit Singh\'s music', 'R&B', '90s bollywood fanatic',
      'Rock', 'Hip-hop', 'Taylor Swift', 'Movie soundtracks', 'Vinyls',
      'House', 'Techno, Techno, Techno', 'DJ', 'Podcasts', 'Punjabi party playlist',
      'Rap', 'Pop', 'Indie/Alternative', 'Metal', '90\'s'
    ],
  ),
  InterestCategory(
    id: 'travel',
    label: 'Travel',
    icon: Icons.flight,
    interests: [
      'Beach babe', 'Ecotourism', 'Mountain ranger', 'City trip',
      '1st in the boarding queue', 'Staycation', 'Lost luggage', 'Camping',
      'All-inclusive', 'Road trip', 'Mapping out adventures', 'Viva Italia',
      'Airport sprinter', 'Hardcore vacation planner', 'Heritage Backpacker',
      '5-star-hotel', 'Van life', 'Backpacking', 'Naturism', 'Hiking'
    ],
  ),
  InterestCategory(
    id: 'habits',
    label: 'Unspoken habits',
    icon: Icons.lightbulb,
    interests: [
      'Road rage', 'Uncontrollable cravings'
    ],
  ),
];
