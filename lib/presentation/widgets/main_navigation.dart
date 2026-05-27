import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../screens/arcade/arcade_screen.dart';
import '../screens/score/score_screen.dart';
import '../screens/store/store_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ArcadeScreen(),
    ScoreScreen(),
    StoreScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navigationItems = [
    const BottomNavigationBarItem(
      icon: Icon(AppIcons.arcade),
      label: AppStrings.arcadeLabel,
      tooltip: AppStrings.arcadeSemantic,
    ),
    const BottomNavigationBarItem(
      icon: Icon(AppIcons.score),
      label: AppStrings.scoreLabel,
      tooltip: AppStrings.scoreSemantic,
    ),
    const BottomNavigationBarItem(
      icon: Icon(AppIcons.store),
      label: AppStrings.storeLabel,
      tooltip: AppStrings.storeSemantic,
    ),
    const BottomNavigationBarItem(
      icon: Icon(AppIcons.friends),
      label: AppStrings.friendsLabel,
      tooltip: AppStrings.friendsSemantic,
    ),
    const BottomNavigationBarItem(
      icon: Icon(AppIcons.profile),
      label: AppStrings.profileLabel,
      tooltip: AppStrings.profileSemantic,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Semantics(
        label: 'Navigation principale',
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          items: _navigationItems,
          enableFeedback: true,
        ),
      ),
    );
  }
}
