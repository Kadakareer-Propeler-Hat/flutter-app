# HorizonAI App – Feature & System Documentation

## Technologies Used
- **Dart**
- **Flutter**
- **Firebase**
- **Supabase**
- **Gemini 3.0 (LLM)**
- **Google Cloud**
- **PayPal Sandbox**
- **Google ML Kit (Text Recognition v2)**
- **Google Maps**
- **HDX Bank Dataset (data.humdata)**
- **GitHub Actions CI/CD**

## 1. Authentication Module

### 1.1 Login
- Email + Password login (Firebase Auth)
- Secure session handling using Firebase tokens
- Failed-attempt lockout logic
- Error-safe UI messages

### 1.2 Signup
- Email + Password registration
- Account verification email
- Profile starter data stored in Firestore/Supabase
- Optional referral code input
- Auto-login after signup

### 1.3 Additional Account Features
- Logout
- Password reset via email
- Session persistence

---

## 2. LLM-Powered Features (Gemini 3.0)

These features rely on Gemini 3.0 for natural-language reasoning, predictions, and summarization.

### 2.1 Loan Coach (AI-Driven)
- Personalized loan guidance based on spending + credit behavior
- LLM interprets financial activity and provides insights
- Simulates different loan scenarios
- Predicts repayment capability
- Provides warnings to avoid over-borrowing

### 2.2 Smart Repayment (AI-Enhanced)
- LLM analyzes due dates + spending habits
- Suggests optimal payment schedule
- Automatic reminders with smart predictions
- Prevents late payments with proactive tips

### 2.3 Ask Horizon (AI Chat Assistant)
- Financial Q&A
- Explains loan terms simply
- Helps with payments, rewards, disputes
- Reads receipts using OCR + summarizes expenses
- Auto-tags spending categories

### 2.4 Fraud Detection (LLM-Supported)
- Detects suspicious transaction patterns
- Suggests corrective actions
- Behavioral analysis combining Firestore + Supabase data

### 2.5 Credit Line Advisor
- Predicts best amount to borrow
- Recommends ideal credit utilization
- Smart tips to maintain a healthy credit score

---

## 3. Quick Actions Module
Instant-access shortcuts for frequently-used tasks:
- Pay Bills
- Repay Loan
- Check Credit Line
- Ask Horizon
- View Rewards
- Scan Receipts
- Smart Repayment Menu

---

## 4. Credit Line Management
- Displays credit limit
- Shows used vs remaining credit
- LLM suggestions for healthier utilization
- Auto-calculation of ideal repayment
- Credit limit increase request system

---

## 5. Payment & Billing System

### 5.1 Payments
- PayPal Sandbox integration
- Loan repayment
- Bills payment
- Installments
- Transaction logs

### 5.2 Bills Payment
- Supports utilities, insurance, subscriptions
- Smart reminders
- Auto-categorization using bill metadata

### 5.3 Receipts & OCR (ML Kit v2)
- Scan receipts using camera
- Auto-read text
- Stores extracted data in Supabase
- LLM summary of spending
- Category tagging

---

## 6. Rewards & Loyalty Program

### 6.1 Points System
Earn points for:
- On-time payments
- Daily streaks
- Challenges
- Quick Actions usage

Tier levels:
- Bronze → Silver → Gold → Platinum

### 6.2 Rewards Redemption
Redeem for:
- Discounts
- Cashbacks
- Fee waivers
- Gift vouchers

---

## 7. Dispute Resolver System
- Create and track disputes
- Upload receipts/images
- AI summarizes evidence
- Backend admin review panel

---

## 8. Fraud Detection System
- Monitors transactions
- Flags unusual behavior
- Risk scoring
- AI explanation of anomalies
- Auto-lock for suspicious activity

---

## 9. Navigator System
Uses Google Maps + HDX bank dataset:
- View nearby banks/payment centers
- Directions, contact info, hours
- Filters:
    - Bank
    - ATM
    - Loan Center

---

## 10. System Modules & Developer Tools

### 10.1 Firebase
- Authentication
- Firestore
- Cloud Functions
- Push Notifications
- Crashlytics

### 10.2 Supabase
- SQL database
- Stores receipts, logs, user insights
- Faster analytics

### 10.3 Google Cloud
- Backend hosting
- LLM processing
- Cloud Run / Functions

### 10.4 GitHub Actions
- CI/CD pipeline
- Auto-build APK/AAB
- Dart linting & testing

---

## 11. System-Level Functions
- Hybrid database (Firestore + Supabase)
- RBAC (user/admin)
- Token-secured requests
- Encrypted storage (Hive/SecureStorage)
- Error monitoring and crash handling

---

## 12. Flutter App Features
- Custom maroon app bar
- Smooth navigation
- Material 3 UI
- Responsive layout
- Dark mode

