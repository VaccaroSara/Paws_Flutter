import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import 'home/home_tab.dart';
import 'add_puppy/add_puppy_tab.dart';
import 'favorites/favorites_tab.dart';
import 'profile/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(key: _homeTabKey),
      const AddPuppyTab(),
      const FavoritesTab(),
      const ProfileTab(),
    ];
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      if (index == 0) {
        _homeTabKey.currentState?.resetSearch();
      }
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              svgPath: 'assets/icons/HomeHome.svg',
              selectedSvgPath: 'assets/icons/HomeHomeSelected.svg',
            ),
            _buildNavItem(
              index: 1,
              svgPath: 'assets/icons/HomePlus.svg',
              selectedSvgPath: 'assets/icons/HomePlus.svg',
              isPlus: true,
            ),
            _buildNavItem(
              index: 2,
              svgPath: 'assets/icons/HomeHeart.svg',
              selectedSvgPath: 'assets/icons/HomeHeartSelected.svg',
            ),
            _buildNavItem(
              index: 3,
              svgPath: 'assets/icons/HomeProfile.svg',
              selectedSvgPath: 'assets/icons/HomeProfileSelected.svg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String svgPath,
    required String selectedSvgPath,
    bool isPlus = false,
  }) {
    final isSelected = _currentIndex == index;

    if (isPlus) {
      return GestureDetector(
        onTap: () => _onTabTapped(index),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryOrange : AppColors.inputBackground,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: SvgPicture.asset(
            svgPath,
            colorFilter: ColorFilter.mode(
              isSelected ? Colors.white : AppColors.iconDark,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SvgPicture.asset(
          isSelected ? selectedSvgPath : svgPath,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            isSelected ? AppColors.primaryOrange : AppColors.iconDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
