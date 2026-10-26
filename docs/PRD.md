# Product Requirement Document (PRD)

## Project: BranchFlow — Cross-Branch Library Network Return & Transit System
**Version:** 1.0.0  
**Target Platform:** Flutter Mobile (Android & iOS) + Web & Desktop  
**Backend:** Firebase Auth, Cloud Firestore, Firebase Storage  
**Document Status:** Ready for Review  

---

## 1. Business Problem Statement

Across a network of community libraries spanning 4 regional branches (*Central Downtown, Westside, Oakridge, and Northgate*), members are allowed to borrow books from any branch. However, each branch historically maintains its catalog independently. 

When a member returns a book to a branch different from where it was checked out (a cross-branch return):
- The book disappears from active borrowing records for an average of **4 to 7 business days** while awaiting manual physical batching and courier transport.
- During this latency period, automated overdue penalty algorithms assess late fees of **\$2.50/day** against members who have already physically relinquished the item.
- Over **32% of active community members** have faced borrowing account holds or disputes for items already returned, resulting in over **\$18,500/month** in contested fines across the network and severe member friction.

**The Solution:**  
**BranchFlow** provides real-time cross-branch synchronization by decoupling member loan liability from physical book logistics. Upon barcode/QR scan at *any* branch, member liability is instantly discharged, late fees are permanently frozen at \$0.00, an immutable digital return certificate is generated, and the book is automatically transitioned into an inter-branch transit queue until restocked at its home branch.

---

## 2. Stakeholders & Ownership

| Stakeholder Category | Role & Representative | Responsibility & Impact |
|---|---|---|
| **Primary Users** | Community Library Members (~12,500 registered borrowers) | Check out books, return at whichever branch is closest, view live loan receipts and zero-liability certificates. |
| **Primary Users** | Branch Librarians & Desk Staff (32 desk staff across 4 branches) | Scan drop-offs from other branches, issue instant clearances, stage courier transit batches, and verify restocked inventory. |
| **Secondary Users** | Inter-Branch Couriers & Logistics Leads (3 regional drivers) | Pickup staged boxes from drop-off branches, transport across town, and hand off to home branch. |
| **Data Owners** | Central Library Consortium Data Team | Owns Firestore collections (`branches`, `books`, `loans`, `transit_items`, `users`). |
| **Approvers** | Head of Community Library Consortium & IT Systems Director | Final sign-off on PRD, security rules, and production deployment. |

---

## 3. Business Impact Justification

1. **Operational Impact:**
   - Replaces manual phone calls and end-of-week spreadsheet reconciliations between branch librarians with instant digital check-ins. Reduces librarian cross-branch reconciliation time from **9 hours/week per branch to ≤20 minutes/week**.
2. **Financial & Penalty Impact:**
   - Completely eliminates false late fee penalties (projected **\$18,500/month saved** across members) by immutably timestamping returns down to the second.
3. **User Experience Impact:**
   - Members regain 100% confidence in returning books anywhere without worrying about automated borrowing holds or account locks.

---

## 4. Dataset & Data Source Documentation

### Confirmed Production Collections (Cloud Firestore):

#### A. `branches`
- `id` (String, PK): e.g. `branch_central`, `branch_westside`.
- `name` (String): Official branch name.
- `code` (String): e.g. `CDL-01`, `WCL-02`.
- `address` (String): Physical location.
- `totalInventory` (Integer): Total catalogued books.

#### B. `books`
- `id` (String, PK): Asset identifier.
- `isbn` (String): 13-digit standard ISBN.
- `barcode` (String, Indexed): Scannable barcode (e.g. `BF-BAR-1001`).
- `title` (String): Book title.
- `author` (String): Author names.
- `homeBranchId` (String, FK): Owning branch catalog.
- `currentBranchId` (String, FK): Present physical location.
- `status` (String Enum): `available`, `borrowed`, `in_holding`, `in_transit`.
- `coverUrl` (String, Nullable): Firebase Storage URL.

#### C. `loans`
- `id` (String, PK): Unique loan agreement code.
- `bookId` (String, FK): Referenced book.
- `bookBarcode` (String): Scanned identifier.
- `memberId` (String, FK): Borrowing user UID.
- `borrowedFromBranchId` (String, FK): Home checkout branch.
- `borrowedAt` (Timestamp UTC): Checkout date.
- `dueDate` (Timestamp UTC): Calculated 14-day limit.
- `returnedAt` (Timestamp UTC, Nullable): Drop-off scan timestamp.
- `returnedToBranchId` (String, FK, Nullable): Branch where physical return occurred.
- `returnReceiptCode` (String, Nullable): Verifiable receipt code.
- `receivedByStaff` (String, Nullable): Staff identifier.
- `status` (String Enum): `active`, `returned`, `overdue`.
- `penaltyAvoided` (Double): Dollar value of late fee prevented.

#### D. `transit_items`
- `id` (String, PK): Transit tracking code.
- `bookId` (String, FK): Book in transit.
- `originBranchId` (String, FK): Return drop-off location.
- `destinationBranchId` (String, FK): Book's home location.
- `stage` (String Enum): `awaiting_dispatch`, `in_transit`, `restocked`.
- `courierBatchId` (String): Grouping identifier for courier van delivery.

---

## 5. KPIs & Measurable Success Metrics

| KPI Metric Name | Measurement Method | Target Goal | Target Timeline |
|---|---|---|---|
| **KPI-01: Discrepancy Elimination Rate** | Audit of member accounts with false holds or disputed fines. | **100% elimination** of false late penalties for cross-branch drop-offs. | Within 30 days of launch |
| **KPI-02: Loan Discharge Speed** | Time elapsed between book barcode scan and Firestore `status: returned` write. | **P95 latency ≤ 1.5 seconds**. | Verified at launch |
| **KPI-03: Transit Pipeline Visibility** | Percentage of books returned cross-branch actively tracked in transit hub. | **100% visibility** (0 lost or uncatalogued books). | Ongoing post-launch |
| **KPI-04: Librarian Adoption** | Daily Active Desk Staff performing returns via mobile scan. | **≥ 90% DAU** across all 4 branch desks. | Within 45 days |

---

## 6. User Stories (Role + Action + Business Benefit)

- **US-01:** *As a library member*, I want to return a book to whatever branch is closest to my workplace, *so that* my borrowing record is immediately cleared and I never incur false late fees.
- **US-02:** *As a library member*, I want an instant verifiable digital return receipt on my phone with the drop-off branch name and timestamp, *so that* I have indisputable proof of return if any dispute arises.
- **US-03:** *As a branch desk librarian*, I want to scan any book dropped off at our counter—even if it belongs to another branch—with our camera scanner, *so that* I can check it in and clear member liability in one tap.
- **US-04:** *As a branch desk librarian*, I want returned foreign-branch books to automatically queue into an "Awaiting Dispatch" transit list, *so that* our staff can hand courier batches over without manual paperwork.
- **US-05:** *As a home-branch librarian*, I want to receive incoming courier batches and scan them back to "Available" shelf status with one tap, *so that* our local branch catalog is instantly up to date.

---

## 7. Product Scope: In-Scope vs. Out-of-Scope (v1.0)

### ✅ IN SCOPE — v1.0
1. **Multi-Branch Authentication & Roles:** Firebase Auth with email/password, forgot password reset links, email verification gating, and role separation (Member vs. Staff).
2. **Real-time Cross-Branch Clearance Engine:** Immediate discharge of member loan liability upon barcode/QR scan at any branch.
3. **Official Digital Return Receipt Modal:** Cryptographic verification code, timestamp, receiving branch, staff ID, and penalty savings.
4. **Inter-Branch Transit Hub:** 3-stage logistics tracking (`Holding Staging` ➔ `In Transit` ➔ `Restocked at Home Branch`).
5. **Unified Multi-Branch Catalog:** Search and filter books across all 4 branches with real-time availability badges.
6. **In-App Borrowing Checkout:** Instant checkout for testing loan lifecycles.
7. **Storage Media Integration:** Storage Security Rules and upload service for condition photos and book covers.

### ❌ OUT OF SCOPE — v1.0 (Deferred to v2 Backlog)
1. GPS-based live courier van tracking (v2).
2. Automated SMS text notification alerts (v2).
3. RFID antenna gate integration (v2).
4. Inter-branch courier route optimization algorithms (v2).

---

## 8. Technical Architecture & Data Workflow

```
[Camera / Barcode Scanner Desk]
               │ (Scans ISBN / Barcode)
               ▼
[BranchFlow Mobile App (Flutter)]
               │
               ├─────────────────────────────────────────────┐
               │ 1. Atomic Firestore Batch Write             │ 2. Storage Upload (Optional)
               ▼                                             ▼
[Cloud Firestore Database]                     [Firebase Storage]
 ├── /loans/{id}      -> 'returned'             └── /receipts/{id}/proof.jpg
 ├── /books/{id}      -> 'in_holding'
 └── /transit_items/  -> 'awaiting_dispatch'
               │
               ▼ (Live snapshots() Stream)
[Reactive StreamBuilder / App State]
               │
               ├─────────────────────────────────────────────┐
               ▼                                             ▼
[Member App: Liability Cleared & Receipt]     [Home Branch Desk: In-Transit Alert]
```

---

## 9. Risk & Assumption Matrix

| Identified Risk | Likelihood | Impact | Mitigation Strategy |
|---|---|---|---|
| **R-01: Network drop-off at library counter with offline connectivity** | Medium | High | Firestore offline persistence enables local queuing; writes auto-sync once device reconnects. |
| **R-02: Barcode damaged or unreadable by camera scanner** | Medium | Medium | Integrated manual barcode/ISBN keyboard input with instant 1-tap book simulator for desk staff. |
| **R-03: Member attempts to forge return status via client API** | Low | High | Enforced in `firestore.rules`: updates to `status: returned` require librarian authentication. |
| **R-04: Courier delays book transport past 3 days** | Medium | Low | Member liability is already cleared on Day 1; delay only affects physical inventory restocking, not borrower fines. |
