import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/library_repository.dart';
import 'dashboard_screen.dart';
import 'catalog_screen.dart';
import 'scanner_screen.dart';
import 'transit_screen.dart';
import 'my_loans_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final LibraryRepository _repo = LibraryRepository();

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        onNavigateToScanner: () => _onTabTapped(2),
        onNavigateToTransit: () => _onTabTapped(3),
        onNavigateToCatalog: () => _onTabTapped(1),
      ),
      CatalogScreen(
        onNavigateToScanner: () => _onTabTapped(2),
      ),
      const ScannerScreen(),
      const TransitScreen(),
      MyLoansScreen(
        onNavigateToScanner: () => _onTabTapped(2),
      ),
    ];

    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5DDD0), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 1. Shelf / Dashboard
                    _buildNavItem(
                      index: 0,
                      label: 'Shelf',
                      secondaryLabel: 'Dashboard',
                      icon: Icons.bookmark_border_rounded,
                      activeIcon: Icons.bookmark_rounded,
                    ),

                    // 2. Search & Catalog
                    _buildNavItem(
                      index: 1,
                      label: 'Search & Catalog',
                      secondaryLabel: 'Catalog',
                      icon: Icons.search_rounded,
                      activeIcon: Icons.search_rounded,
                    ),

                    // 3. Center Elevated Scan Button
                    GestureDetector(
                      onTap: () => _onTabTapped(2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.crop_free_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Return Desk',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 4. Network Map / Transit Hub
                    _buildNavItem(
                      index: 3,
                      label: 'Network Map',
                      secondaryLabel: 'Transit Hub',
                      icon: Icons.account_balance_outlined,
                      activeIcon: Icons.account_balance_rounded,
                      badgeCount: _repo.transitCount,
                    ),

                    // 5. Account / My Loans
                    _buildNavItem(
                      index: 4,
                      label: 'Account',
                      secondaryLabel: 'My Loans',
                      icon: Icons.badge_outlined,
                      activeIcon: Icons.badge_rounded,
                      badgeCount: _repo.activeLoansCount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String secondaryLabel,
    required IconData icon,
    required IconData activeIcon,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 23,
                  color: isSelected ? AppColors.primary : const Color(0xFF8A958E),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -3,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF8A958E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
