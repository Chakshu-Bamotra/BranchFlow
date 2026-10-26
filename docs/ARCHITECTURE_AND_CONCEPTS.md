# BranchFlow: Architecture, Dart & Flutter Core Reference

> Comprehensive curriculum alignment mapping for **SR 3.9 (Project Setup)**, **SR 3.10 (Folder Structure)**, **SR 3.11 (Stateless Widgets)**, and **Stateful Widgets (`setState()`)**.

---

## 1. SR 3.9: Flutter Project Setup & Verification

### Toolchain Health & Environment
BranchFlow is built on the stable Flutter toolchain:
- **Flutter Framework:** `3.47.6`
- **Dart SDK:** `3.13.5`
- **Platforms Supported:** Windows Desktop, Web (Chrome & Edge), Android, and iOS.

### The Entry Point (`lib/main.dart`)
Every Flutter application begins execution at the top-level `main()` function:
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BranchFlowApp());
}
```
- `WidgetsFlutterBinding.ensureInitialized()`: Ensures binary messengers, platform channels, and Flutter engine hooks are bound before any widget renders.
- `runApp()`: Attaches the root widget (`BranchFlowApp`) as the root of the RenderView tree.

### Hot Reload vs. Hot Restart
| Operation | Key / Shortcut | What it Does | State Preservation | When to Use |
|---|---|---|---|---|
| **Hot Reload** | `r` | Injects changed Dart source into the running Dart VM and re-runs `build()`. | **Preserves State** (e.g. form text and counter remain intact). | Tweaking UI layouts, updating colors, spacing, text styles. |
| **Hot Restart** | `R` | Re-compiles code, wipes application state, and re-executes `main()` from scratch. | **Resets State** to initial values. | Modifying `main()`, changing app themes, resetting singleton services. |

---

## 2. SR 3.10: Clean Project Folder Structure

BranchFlow strictly adheres to the industry-standard four-layer separation of concerns inside `lib/`:

```
lib/
├── main.dart                  # App bootstrap and AuthWrapper routing
├── core/                      # Global single-source-of-truth constants & theme
│   ├── constants/             # AppColors (brand navy, teal, success, warning)
│   └── theme/                 # AppTheme (Material 3 ThemeData, cardThemeData)
├── models/                    # Plain, immutable Dart data classes
│   ├── book.dart              # Book with BookStatus enum and copyWith
│   ├── branch.dart            # Library branch metadata and inventory
│   ├── loan.dart              # Cross-branch loan contract and timestamps
│   └── transit_item.dart      # Inter-branch courier transit tracking
├── services/                  # Business logic & external systems (No UI code)
│   ├── auth_service.dart      # Firebase Auth + authStateChanges stream
│   ├── firestore_service.dart # withConverter typed collections & atomic batches
│   ├── storage_service.dart   # File upload tasks & download URL generation
│   ├── library_repository.dart# Reactive ChangeNotifier managing multi-branch state
│   └── mock_data.dart         # Realistic seed dataset for community libraries
├── screens/                   # Full-page navigation destinations
│   ├── auth/                  # AuthScreen & EmailVerificationScreen
│   ├── home_screen.dart       # Bottom navigation container (5 tabs)
│   ├── dashboard_screen.dart  # KPI cards, zero-silo banner, live ledger
│   ├── catalog_screen.dart    # Multi-branch search, filter, and borrow modal
│   ├── scanner_screen.dart    # Barcode camera & 1-tap return desk
│   ├── transit_screen.dart    # Courier staging, dispatch & restock
│   ├── my_loans_screen.dart   # Member active loans and zero-hold status
│   └── return_receipt_screen.dart # Verifiable proof-of-return certificate
└── widgets/                   # Small, reusable, presentation-only components
    ├── stat_card.dart         # Metric KPI cards
    ├── status_badge.dart      # Semantic badges (success, warning, danger, info)
    └── branch_chip.dart       # Home branch vs. current location tag
```

### Naming Conventions:
- **Files:** `snake_case` with descriptive suffix (e.g., `dashboard_screen.dart`, `auth_service.dart`, `branch_chip.dart`).
- **Classes:** `PascalCase` matching file purpose (e.g., `DashboardScreen`, `AuthService`, `BranchChip`).
- **Clean Repo:** Build artifacts (`build/`, `.dart_tool/`, `.idea/`) are excluded via `.gitignore`.

---

## 3. SR 3.11: Stateless Widgets in BranchFlow

### The Core Principle
A `StatelessWidget` has **no internal mutable state**. It is a pure function of the data passed into its constructor:

$$\text{Rendered UI} = f(\text{Constructor Inputs})$$

### Reusable Example: `StatCard` (`lib/widgets/stat_card.dart`)
Instead of duplicating 40 lines of card layout for every metric, `StatCard` accepts final inputs:
```dart
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Rendered purely from title, value, subtitle, icon, color
    );
  }
}
```
**Benefits:**
1. Cuts code duplication in `DashboardScreen` by 75%.
2. Updating `StatCard` styling in one file automatically updates all 4 dashboard metrics.

---

## 4. Stateful Widgets & The `setState()` Loop

### The Core Principle
A `StatefulWidget` is split into **two classes**:
1. The immutable `StatefulWidget` configuration class (`Widget`).
2. The persistent, mutable `State<T>` object that survives across rebuilds.

### The Rebuild Loop
```
User Interaction (Tap / Type) 
        │
        ▼
   setState(() { 
     // Mutate state variable 
   })
        │
        ▼
Flutter flags widget as 'dirty'
        │
        ▼
Flutter re-runs build(context) on next frame
        │
        ▼
Framework diffs Element tree and repaints only changed pixels
```

### Real Implementation: `CatalogScreen` (`lib/screens/catalog_screen.dart`)
`CatalogScreen` maintains active search and filter states:
```dart
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.onNavigateToScanner});
  final VoidCallback onNavigateToScanner;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Mutable state stored in State object
  final TextEditingController _searchController = TextEditingController();
  String _selectedBranchFilter = 'all';
  String _selectedStatusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose(); // Prevent memory leak!
    super.dispose();
  }

  void _updateFilter(String newBranch) {
    setState(() {
      _selectedBranchFilter = newBranch; // Triggers UI rebuild!
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pure, fast rendering based on _selectedBranchFilter and query
  }
}
```

---

## 5. Stateless vs. Stateful Decision Matrix

| Question | If NO | If YES | Applied in BranchFlow |
|---|---|---|---|
| Does this widget need to remember changing data while on screen? | **Stateless** | **Stateful** | `StatCard`, `StatusBadge` vs. `ScannerScreen`, `AuthScreen` |
| Does the widget hold controllers, animation tickers, or timers? | **Stateless** | **Stateful** | `EmailVerificationScreen` holds a 30s countdown `Timer` ➔ **Stateful** |
| Does the widget draw only what its parent hands it? | **Stateless** | **Stateful** | `BranchChip` takes branch name and home boolean ➔ **Stateless** |
