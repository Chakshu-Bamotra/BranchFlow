# BranchFlow 📚⚡

> **A real-time cross-branch return and inventory transit app for community library networks.**

---

## 🎯 Problem Statement
A network of community libraries allows members to borrow books from any branch, but each branch maintains its own catalog independently. A book returned to a different branch disappears from the borrowing record for days, and members face holds or penalties for items they have already returned.

---

## 💡 Solution Overview
**BranchFlow** bridges catalog silos by introducing a unified real-time ledger on Cloud Firestore and camera-driven barcode/QR check-ins:
1. **Instant Loan Discharge:** When a book is returned to *any* branch, scanning it immediately marks the member's loan as returned at that exact timestamp, instantly freezing penalties and clearing borrowing holds.
2. **Decoupled Transit Pipeline:** Physical book relocation is tracked via an inter-branch transit queue (`Holding at Drop-off Branch` ➔ `In-Transit with Courier` ➔ `Re-shelved at Home Branch`) without penalizing the borrower.
3. **Digital Return Receipt:** Issues immediate in-app proof of return with branch ID, timestamp, and staff verification.

---

## 👥 Target Users
1. **Library Members:** Borrowers who want the flexibility to return books at whichever branch is closest to them without risking wrongful fines, delayed clearances, or blocked accounts.
2. **Branch Librarians & Desk Staff:** Staff receiving drop-offs belonging to other branches who need instant scan-to-return capability and an organized transit staging dispatch.
3. **Inter-Branch Couriers & Network Admins:** Personnel responsible for moving batches of cross-branch books between locations and reconciling inter-branch inventory.

---

## 🛠️ Tech Stack & Architecture
- **Framework:** Flutter (Android / iOS / Web)
- **Backend & Database:** Firebase Cloud Firestore (Real-time synchronization across branch nodes)
- **Authentication:** Firebase Auth (Role-based access: Member vs. Staff/Admin)
- **Scanning Engine:** `mobile_scanner` (Fast ISBN & Library Asset Barcode/QR scanning)
- **Storage:** Firebase Storage (Book covers and digital signed return receipts)

---

## 📋 Team Charter

| Role / Category | Details |
|---|---|
| **App Name** | **BranchFlow** |
| **Team Name** | BranchFlow Core Team |
| **Project Admin** | Sujal Rana (`@sujal-rana58`) |
| **Team Members & Responsibilities** | • **Project Admin / State & Routing:** Architecture, GitHub PRs, Navigation<br>• **Frontend / Mobile UI:** Screens (Dashboard, Scanner, Receipts, Loan History)<br>• **Backend / Firebase:** Firestore Collections, Auth, Security Rules, Real-Time Streams<br>• **Logistics & QA:** Mobile Scanner integration, transit state machine, emulator testing |
| **Core Working Agreements** | • Daily Standup: 10:00 AM<br>• PR Submission Deadline: Daily by 6:00 PM<br>• Code Review SLA: Review within 2 hours of PR opening<br>• Definition of Done: Code runs on mobile emulator/device + no lint errors + tested against Firestore |
| **Communication Channel** | Slack / Discord / WhatsApp group |
| **Branching Strategy** | `main` (Protected) ➔ Feature branches (`feature/auth`, `feature/scanner`, `feature/transit`) ➔ PR Review ➔ Merge |

---

## 🗺️ 5-Week Sprint Roadmap

- **Week 1 (Discovery & Setup):** PRD, Firestore System Design & Schema approval, Flutter skeleton initialization.
- **Week 2 (Core Auth & Catalog):** Multi-branch authentication (Member vs. Staff), branch catalog browsing, and basic checkout tracking.
- **Week 3 (Cross-Branch Return & Scanner):** `mobile_scanner` integration, instant loan discharge logic, penalty freeze timestamping.
- **Week 4 (Transit & Reconciliation Hub):** Dispatch queue, courier transit batching, home-branch restocking verification, and digital receipt generation.
- **Week 5 (Security Rules, Polish & Showcase):** Firestore Security Rules enforcement, offline persistence, UI polishing, and final demo showcase.

---

## 📖 Sprint 2 Deliverables & Documentation Links

Every requirement for the **Sprint 2 Final Submission** is documented and version-controlled:

- 📋 **[Product Requirements Document (PRD)](docs/PRD.md):** 10-section comprehensive PRD detailing problem statement, user personas, screen flows, Firestore schema, out-of-scope boundaries, and definition of done.
- 🎨 **[Mock UX & Wireframes (MOCK_UX.md)](docs/MOCK_UX.md):** Detailed wireframe layouts, 5 user modes, transition states, and edge/empty/error cases.
- 🏗️ **[Architecture & Concepts Guide](docs/ARCHITECTURE_AND_CONCEPTS.md):** Deep-dive technical explanations for all 40 Sprint concepts (Stateful vs Stateless, Auth Streams, Storage, CRUD, Server Timestamps, Security Rules).
- 🔒 **[Firestore Security Rules](firestore.rules):** Enforces role-based permissions (`request.auth.uid`, `isLibrarian()`, loan immutability).
- 🗄️ **[Storage Security Rules](storage.rules):** Restricts receipt proof and book cover uploads (`5MB max`, `image/*` MIME check).

---

## 🚀 Getting Started & How to Run

### 1. Prerequisites
- Flutter SDK (v3.22.0 or higher)
- Dart SDK (v3.4.0 or higher)

### 2. Installation
```bash
git clone https://github.com/sujal-rana58/BranchFlow.git
cd BranchFlow
flutter pub get
```

### 3. Run the App
BranchFlow features an intelligent dual-mode architecture: it connects to Firebase if credentials exist, and automatically falls back to an in-memory reactive state with 4 seeded branches and real catalog books.
```bash
# Run on Windows Desktop
flutter run -d windows

# Run on Chrome Web
flutter run -d chrome

# Run on Android / iOS
flutter run
```

### 4. Running Automated Tests & Analyzer
```bash
# Run all unit and widget tests (7/7 passing)
flutter test

# Run static code analysis (0 errors, 0 warnings)
flutter analyze
```

---

## 🏆 Final Submission Checklist (SR 3.49)

- [x] **10+ PRs / Distributed Commits:** Scoped commits across features (Auth, Firestore CRUD, Mobile Scanner, Transit Hub, UI Polish).
- [x] **PRD Present:** Available in [`docs/PRD.md`](docs/PRD.md).
- [x] **Mock UX Present:** Available in [`docs/MOCK_UX.md`](docs/MOCK_UX.md).
- [x] **README Maintained:** Clear problem description, setup steps, test execution, and architecture overview.
