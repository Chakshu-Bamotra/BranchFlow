# Mock UX & Wireframe Design Document

## Project: BranchFlow — Cross-Branch Library Network
**Module:** SR 3.8 Mock UX: Design the Experience Before You Build It  
**Design Philosophy:** Workflow-First & Decision-Driven (Summary before detail · Alert before list · KPI before chart)  

---

## 1. User Modes Supported

BranchFlow serves users operating in five distinct modes:
1. **Monitor Mode (2-minute daily check):** Branch librarians check the 4 KPI cards above the fold on the Dashboard: Active Loans, Cross-Branch Returns, Books in Transit, and Penalties Saved.
2. **Filter Mode:** Members narrow down the multi-branch catalog by selecting their preferred branch location and availability state (`Available`, `Checked Out`, `In Holding`, `In Transit`).
3. **Explore Mode:** Members browse titles across all 4 community library collections without physical branch boundaries.
4. **Investigate Mode:** Librarians inspect cross-branch return discrepancies, tracking which drop-off branch received the book and its current courier transit status.
5. **Compare Mode:** Staff compare inventory holdings across Central Downtown, Westside, Oakridge, and Northgate branches.

---

## 2. Information Architecture & Navigation

```
                       [ App Entry / AuthWrapper ]
                                    │
                  ┌─────────────────┴─────────────────┐
                  ▼                                   ▼
          [ Auth Screen ]                   [ Email Verification ]
          • Sign In / Sign Up               • Resend Link (30s Cooldown)
          • Forgot Password Modal           • "I've Verified" Confirmation
                  │
                  ▼ (Authenticated Stream)
           [ Home Screen — Persistent NavigationBar (5 Tabs) ]
     ┌────────────┬─────────────┬──────────────┬─────────────┬────────────┐
     ▼            ▼             ▼              ▼             ▼            ▼
[Dashboard]   [Catalog]   [Return Desk]  [Transit Hub]  [My Loans]   [Receipt Modal]
Tab 0         Tab 1       Tab 2          Tab 3          Tab 4        (Triggered)
```

---

## 3. Screen Wireframes & Layout Hierarchy

### Screen 1: Dashboard (`DashboardScreen`)
*Goal: Provide instant network health in a 5-second scan without scrolling.*

```
+-----------------------------------------------------------------+
| [LOGO] BranchFlow                    [Role: Staff v] [Logout]   |
+-----------------------------------------------------------------+
| +-------------------------------------------------------------+ |
| | ZERO CATALOG SILOS                                    (i)   | |
| | Instant Cross-Branch Clearance                              | |
| | Returning books at any branch immediately discharges member | |
| | liability, freezes late fees, and queues courier transit.   | |
| | [ Return Desk / Scan ]        [ Transit Hub ]               | |
| +-------------------------------------------------------------+ |
|                                                                 |
| [ ACTIVE LOANS: 2 ]              [ CROSS RETURNS: 1 ]           |
| Across 4 branches                Zero delay clearance           |
|                                                                 |
| [ IN TRANSIT: 1 ]                [ PENALTIES SAVED: $25 ]       |
| Returning to home branch         False holds prevented          |
|                                                                 |
| Connected Network Branches                                      |
| [Branch CDL-01: Central Downtown (14.2k books)               ]  |
| [Branch WCL-02: Westside Community (Active Desk)             ]  |
|                                                                 |
| Live Synchronization Ledger                                     |
| [*] Clean Code       Returned at WCL · Verified    [Receipt]    |
| [*] Pragmatic Prog   Borrowed from CDL             (Due Soon)   |
+-----------------------------------------------------------------+
| [Dashboard]  [Catalog]  [Return Desk]  [Transit Hub]  [My Loans]|
+-----------------------------------------------------------------+
```

---

### Screen 2: Cross-Branch Return Desk (`ScannerScreen`)
*Goal: Rapid 1-tap check-in discharging member liability.*

```
+-----------------------------------------------------------------+
| <-- Cross-Branch Return Desk                    [Camera Toggle] |
+-----------------------------------------------------------------+
| [Storefront Icon] Receiving Drop-off Branch:                    |
| Westside Community Library                         [Change v]   |
+-----------------------------------------------------------------+
| ( Optional Live Camera Viewport - mobile_scanner )              |
| +-------------------------------------------------------------+ |
| |                     [ SCAN VIEWFINDER ]                     | |
| +-------------------------------------------------------------+ |
|                                                                 |
| Scan or Enter Book Barcode / ISBN                               |
| [ e.g. BF-BAR-1001                             ] [ Check In ]   |
|                                                                 |
| Currently Borrowed Books (Quick Return Test Simulator)          |
| +-------------------------------------------------------------+ |
| | Clean Code: Agile Software Craftsmanship  [⚡ Cross-Branch] | |
| | Borrower: Priya Sharma (MEM-4021)                           | |
| | [Home: Central Downtown]  Barcode: BF-BAR-1001              | |
| | [ Instant Return at Westside Community Library (1-Tap) ]   | |
| +-------------------------------------------------------------+ |
+-----------------------------------------------------------------+
```

---

### Screen 3: Verifiable Digital Return Certificate (`ReturnReceiptScreen`)
*Goal: Indisputable proof of return clearing member liability.*

```
+-----------------------------------------------------------------+
|                             [===]                               |
|                     ( Shield Checkmark Icon )                   |
|                    Official Return Receipt                      |
|       Member liability discharged. Holds permanently cleared.   |
|                                                                 |
| +-------------------------------------------------------------+ |
| | Receipt Verification ID:      BF-RTN-9842-WCL               | |
| | Book Title:                   Clean Code                    | |
| | Asset Barcode:                BF-BAR-1001                   | |
| | Borrower:                     Priya Sharma (MEM-4021)       | |
| | Checkout Branch (Home):       Central Downtown Library      | |
| | Drop-Off Branch (Return):     Westside Community Library    | |
| | Returned At:                  Oct 26, 2026 · 6:35:12 PM     | |
| | Received By Staff:            Desk Staff (Westside)         | |
| | Late Penalty Prevented:       $15.00 (Zero Liability)       | |
| +-------------------------------------------------------------+ |
| [                          Done / Dismiss                     ] |
+-----------------------------------------------------------------+
```

---

### Screen 4: Inter-Branch Transit Hub (`TransitScreen`)
*Goal: Visual courier batching and home-branch restock pipeline.*

```
+-----------------------------------------------------------------+
| Inter-Branch Transit Hub                                        |
| [ Holding Staging (1) ]  [ In Transit (0) ]  [ Restocked (1) ]  |
+-----------------------------------------------------------------+
| (i) Eliminates Catalog Vanishing: Books returned to foreign     |
|     branches are tracked until safely re-shelved.               |
|                                                                 |
| BATCH-WCL-CDL-01                             [Holding Staging]  |
| The Pragmatic Programmer: Your Journey to Mastery               |
| Barcode: BF-BAR-1002                                            |
|                                                                 |
| [Drop-off: Westside] --------> [Home: Central Downtown]         |
| Logged: Oct 26, 2:30 PM                                         |
|                                                                 |
| [ Dispatch with Courier Batch                                ]  |
+-----------------------------------------------------------------+
```

---

## 4. Edge Cases: Empty & Error State Specifications

| State Type | Trigger Scenario | Screen Component Rendered | User Recovery Action |
|---|---|---|---|
| **Empty State: Catalog Filter** | Member searches for a title that doesn't exist. | Search icon + *"No books match your criteria."* | Tap **"Reset filters"** button to clear search input. |
| **Empty State: Transit Queue** | All cross-branch books have been restocked. | Staging box icon + *"No books currently awaiting courier pickup."* | Explanatory label indicating network is 100% reconciled. |
| **Error State: Invalid Barcode** | Barcode entered does not exist in network catalog. | Floating Red SnackBar: *"No book found matching barcode: [X]"*. | Prompts staff to double-check asset label or enter ISBN. |
| **Gated State: Unverified Email** | User creates account but has not verified email link. | Full-screen `EmailVerificationScreen` showing email and resend cooldown. | Tap **"Resend Verification"** (30s countdown) or **"I've Verified"**. |
