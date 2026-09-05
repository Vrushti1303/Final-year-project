# 📑 Real Estate Legal AI Assistant — Project Roadmap & Progress Tracker

> **Final Year Project Countdown:** ~4 Weeks Left  
> **Repository:** [Final-year-project](https://github.com/Vrushti1303/Final-year-project)  
> **Last Updated:** September 5, 2026

---

## 🎯 Project Core Pillars & Status Overview

| Pillar | Feature | Status | Priority |
| :--- | :--- | :---: | :---: |
| **1. OCR & Extraction** | Upload PDF / Scan Image & Extract Text | ✅ Completed | High |
| **2. Risk Analysis** | RERA/Legal AI Risk Evaluation, Score & Breakdown | ✅ Completed | High |
| **3. Tap-to-Explain** | Interactive clause-by-clause plain language breakdown | 🟡 In Progress | High |
| **4. Checklists** | Interactive Property Transaction Checklists & AI generator | ✅ Completed | High |
| **5. AI Legal Chatbot** | Real estate legal Q&A assistant with quick prompts | ✅ Completed | High |
| **6. Agreement Drafting** | Step-by-step wizard for Rent/Sale agreements with AI | ⏳ Planned | High |
| **7. Live Legal News** | Live Google News RSS feed for RERA & Property law | ✅ Completed | Medium |
| **8. UI & Theming** | Modern Dark/Light theme toggle & Glassmorphism design | ✅ Completed | Medium |
| **9. Document History** | User saved documents, reports & download capability | 🟡 In Progress | Medium |
| **10. Documentation** | Final Year Report, Architecture Diagrams & PPT | ⏳ Planned | Critical |

---

## 📅 4-Week Sprint Schedule

### 🏁 Week 1: Core Feature Completion & Tap-to-Explain
- [ ] **Tap-to-Explain Integration**:
  - [ ] Allow users to tap individual clauses on the scanned document preview.
  - [ ] Show a lightweight popup/bottom sheet with a 2-3 sentence layman explanation + legal advice.
- [ ] **Document History & Persistence**:
  - [ ] Ensure all scanned documents and generated reports are stored with user ID in MongoDB.
  - [ ] Add PDF export/share functionality for analysis reports.
- [ ] **End of Week 1 Review & Git Tag (`v1.1-features`)**

---

### 📝 Week 2: AI Agreement Drafting Wizard
- [ ] **Drafting Module UI**:
  - [ ] Form wizard for Rental Agreement, Sale Agreement, Commercial Lease.
  - [ ] Inputs for Landlord, Tenant, Property details, Rent, Deposit, Lock-in period, Maintenance.
- [ ] **Backend AI Generator**:
  - [ ] AI prompt template to generate legally compliant, RERA-aligned agreement drafts.
  - [ ] Download / copy generated agreement as `.pdf` or `.docx`.
- [ ] **More Preloaded Checklists**:
  - [ ] Under-Construction Flat (RERA Verification)
  - [ ] Commercial Lease Due Diligence
  - [ ] Agricultural Land Purchase
- [ ] **End of Week 2 Review & Git Tag (`v1.2-drafting`)**

---

### 🧪 Week 3: Testing, Edge Cases, Performance & UI Polish
- [ ] **Error Handling & Offline State**:
  - [ ] Graceful fallback for rate limits / network dropouts.
  - [ ] Input validation for large PDFs / blurry images.
- [ ] **Cross-Platform Verification**:
  - [ ] Web responsiveness & Mobile layout audit.
  - [ ] Animation smoothing and loading state enhancements.
- [ ] **User Feedback & Trial Runs**:
  - [ ] Test with sample real-world rental agreements and sale deeds.
- [ ] **End of Week 3 Review & Git Tag (`v1.3-stable`)**

---

### 🎓 Week 4: Final Project Report, Presentation & Viva Prep
- [ ] **Final Project Report & Documentation**:
  - [ ] Chapter 1: Introduction & Problem Statement
  - [ ] Chapter 2: Literature Survey & Existing Systems comparison
  - [ ] Chapter 3: System Architecture, Data Flow Diagrams & UML
  - [ ] Chapter 4: Implementation Details (Flutter + Node.js + Gemini AI)
  - [ ] Chapter 5: Results, Testing & Performance Analysis
  - [ ] Chapter 6: Conclusion & Future Scope
- [ ] **Presentation & Demo Video**:
  - [ ] 10-12 Slide Presentation (Problem, Solution, Tech Stack, Demo, Impact).
  - [ ] Recorded 2-minute video walkthrough of full user journey.
- [ ] **Final Submission & Viva Defense Prep**

---

## 📋 Feature Checklist Matrix

### ✅ Completed Features
- [x] Flutter client setup with Riverpod state management
- [x] Express.js REST API with MongoDB & Mongoose schemas
- [x] JWT Authentication (Login, Register, Token persistence)
- [x] OCR & Document Text Extraction (PDF / Image parsing)
- [x] AI Risk Assessment engine with severity classification (Red/Yellow/Green)
- [x] Interactive Property Transaction Checklists with progress bars
- [x] AI Custom Checklist Item Generator based on property specifics
- [x] Real Estate Legal Chatbot with markdown streaming & prompt chips
- [x] Live Google News RSS feed integration for RERA and real estate updates
- [x] Light / Dark mode theme toggle across all screens
- [x] Seed script for initial document samples
- [x] Document History & Recent Scans on Home Screen
- [x] Professional Legal Risk Assessment PDF Report Export

### 🟡 In Progress / Enhancements
- [ ] Interactive clause tapping ("Tap-to-Explain") directly on document text

### ⏳ Pending Features
- [ ] Dedicated "Draft an Agreement" wizard
- [ ] Additional real estate transaction checklists
- [ ] Final project report & presentation slides

