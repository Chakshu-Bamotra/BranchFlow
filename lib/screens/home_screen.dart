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
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabTapped,
              backgroundColor: AppColors.surface,
              indicatorColor: const Color(0xFFEEF2FF),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
                  label: 'Dashboard',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.library_books_outlined),
                  selectedIcon: Icon(Icons.library_books, color: AppColors.primary),
                  label: 'Catalog',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: _repo.activeLoansCount > 0,
                    label: Text('${_repo.activeLoansCount}'),
                    child: const Icon(Icons.qr_code_scanner_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _repo.activeLoansCount > 0,
                    label: Text('${_repo.activeLoansCount}'),
                    child: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  ),
                  label: 'Return Desk',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: _repo.transitCount > 0,
                    backgroundColor: AppColors.warning,
                    label: Text('${_repo.transitCount}'),
                    child: const Icon(Icons.local_shipping_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _repo.transitCount > 0,
                    backgroundColor: AppColors.warning,
                    label: Text('${_repo.transitCount}'),
                    child: const Icon(Icons.local_shipping, color: AppColors.primary),
                  ),
                  label: 'Transit Hub',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppColors.primary),
                  label: 'My Loans',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
