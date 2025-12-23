# Complete App Store Connect Setup Guide
## For "Sometimes Poetry" - December 2025

**Updated with verified information from official Apple Developer documentation.**

---

## ✅ PREREQUISITES COMPLETED

- [x] Privacy Policy Live: https://oddyblue.github.io/Sometimes-Poetry-App/
- [x] Bundle ID: com.sometimes.app
- [x] Version: 1.0 (Build 1)
- [x] Privacy Manifest: PrivacyInfo.xcprivacy ✓
- [x] In-App Purchases: Code ready for 3 tiers

---

# PART 1: CREATE APP RECORD

## Step 1.1: Create New App

**URL:** https://appstoreconnect.apple.com

1. Click **"My Apps"** at the top
2. Click the **"+"** button (top left of Apps page)
3. Select **"New App"** from the dropdown

### Fill the New App Dialog:

| Field | Value | Notes |
|-------|-------|-------|
| **Platforms** | ☑ iOS | Check iOS only |
| **App Name** | `Sometimes Poetry` | 2-30 characters. Can change until submission |
| **Primary Language** | English (U.S.) | Can be changed later |
| **Bundle ID** | `com.sometimes.app` | Select from dropdown. CANNOT change after build upload |
| **SKU** | `sometimes-poetry-001` | Internal only. Cannot change after creation |
| **User Access** | ○ Full Access | Keep default (all users can access) |

**Then:** Click **"Create"**

Your app will now appear with status: **"Prepare for Submission"**

---

## Step 1.2: Complete App Information

After creating the app, you'll be in the App Information section. Complete these required fields:

**Navigate to:** Apps → Sometimes Poetry → App Information (left sidebar under "General")

### Primary Category (Required)

- **Primary Category:** Books
- **Secondary Category:** (Optional - can leave blank or choose Lifestyle)

### Content Rights (Required)

**Question:** "Does your app contain, show, or access third-party content?"

- **Answer:** ○ Yes, it contains, shows, or accesses third-party content, and I have the necessary rights

**Note:** The 151 poems in your app are public domain classics, so you have the legal right to use them.

### Age Rating (Required)

1. Click **"Edit"** next to Age Rating
2. You'll see a questionnaire with categories like:
   - Cartoon or Fantasy Violence
   - Realistic Violence
   - Sexual Content or Nudity
   - Profanity or Crude Humor
   - etc.
3. Answer **"None"** or **"No"** to all questions (poetry has no mature content)
4. Click **"Done"**
5. **Result:** Age Rating will be **4+**

**Then:** Click **"Save"** (top right)

---

# PART 2: IN-APP PURCHASES

## Navigate to In-App Purchases

**Path:** Apps → Sometimes Poetry → In-App Purchases (left sidebar under "Monetization")

## Step 2.1: Create Product 1 - Coffee

1. Click the **"+"** button
2. In the Type selector, choose **"Consumable"**
3. Fill in:
   - **Reference Name:** `Coffee` (internal only)
   - **Product ID:** `com.sometimes.app.support.small` ⚠️ CRITICAL: Cannot change after creation
4. Click **"Create"**

### After Creation - Add Metadata:

You'll now be on the product detail page. Complete:

**App Store Information:**
- **Display Name:** `Coffee` (visible to users)
- **Description:** `Support Sometimes` (visible to users)

**Pricing:**
- Click **"Set Starting Price"** or go to Pricing section
- Select your pricing tier (for $2.99, this is typically Tier 2)
- Confirm pricing

**Review Screenshot:** (Optional - can skip for consumables)

Click **"Save"**

## Step 2.2: Create Product 2 - Nice Lunch

Repeat the process:
1. Click **"+"** → Select **"Consumable"**
2. **Reference Name:** `Nice Lunch`
3. **Product ID:** `com.sometimes.app.support.medium`
4. Click **"Create"**
5. **Display Name:** `Nice Lunch`
6. **Description:** `Support Sometimes`
7. **Price:** Tier 4 ($4.99)
8. Click **"Save"**

## Step 2.3: Create Product 3 - Generous Support

Repeat the process:
1. Click **"+"** → Select **"Consumable"**
2. **Reference Name:** `Generous Support`
3. **Product ID:** `com.sometimes.app.support.large`
4. Click **"Create"**
5. **Display Name:** `Generous Support`
6. **Description:** `Support Sometimes`
7. **Price:** Tier 9 ($9.99)
8. Click **"Save"**

**Note:** It may take up to 1 hour for in-app purchase metadata to appear in sandbox.

---

# PART 3: APP PRIVACY

## Navigate to App Privacy

**Path:** Apps → Sometimes Poetry → App Privacy (left sidebar)

### Privacy Questionnaire

Click **"Get Started"** if this is your first time, or **"Edit"** if updating.

### Answer These Questions:

**Q1: "Do you or your third-party partners collect data from this app?"**
- **Answer:** ○ No

**Q2: "Do you use data for tracking purposes?"**
- **Answer:** ○ No

**Note:** Apple defines "tracking" as linking user data to third-party data for advertising or data broker purposes. Your app doesn't do this.

### Publish

Click **"Publish"** when done.

**Result:** Your app's privacy label will show "This app does not collect any data"

---

# PART 4: PRICING & AVAILABILITY

**Navigate to:** Apps → Sometimes Poetry → Pricing and Availability (left sidebar under "General")

### Set Price

- **Price:** Select **"0"** (Free)
- **Availability:** Leave as "All Territories" (default)

Click **"Save"**

---

# PART 5: VERSION 1.0 - PREPARE FOR SUBMISSION

## Navigate to Version

**Path:** Apps → Sometimes Poetry → iOS App (left sidebar) → 1.0 Prepare for Submission

You'll see several sections to complete. Here's what's required:

---

## Section 1: App Information

These fields are auto-filled from your App Information:

- **Name:** Sometimes Poetry
- **Subtitle:** (Optional, max 30 chars) `Poetry at meaningful moments`

**Note:** Name and subtitle are edited in the App Information section, not here.

---

## Section 2: Screenshots and App Previews (REQUIRED)

### Requirements (December 2025):

You **MUST** upload screenshots for:

#### iPhone
- **6.9" Display (Required)**
  - Size: **1260 x 2736 pixels** (portrait) or 2736 x 1260 (landscape)
  - OR: **6.5" Display** if you don't provide 6.9"
  - Size: **1284 x 2778 pixels** (portrait)

#### iPad (if your app runs on iPad)
- **13" Display (Required)**
  - Size: **2064 x 2752 pixels** (portrait) or 2752 x 2064 (landscape)

**Important:** Apple auto-scales these to all other device sizes.

### How to Create Screenshots:

#### Option A: Using Simulator (Recommended)

1. Open Xcode
2. Select **iPhone 16 Pro Max** simulator (6.9" display)
3. Run your app (⌘ + R)
4. Navigate to different screens:
   - Poem display
   - Welcome/onboarding
   - Archive
   - Settings
5. Press **⌘ + S** to save screenshot (saves to Desktop)
6. Take 4-10 screenshots

For iPad:
1. Select **iPad Pro 13-inch (M4)** simulator
2. Repeat the process

#### Option B: Physical Device

1. Run app on your iPhone/iPad
2. Take screenshots (Side button + Volume Up)
3. AirDrop to Mac

### Screenshot Guidelines:

**Format:** .jpeg, .jpg, or .png
**Quantity:** 1-10 screenshots per device type

**Requirements:**
- ✅ Show actual app UI
- ✅ Use real content (actual poems)
- ✅ Clean, professional appearance
- ❌ No phone frames/bezels
- ❌ No text overlays or marketing graphics
- ❌ No personal information in status bar

### Upload Screenshots:

1. In the version page, find "Screenshots and App Previews"
2. Click on the device size (e.g., "6.9" Display")
3. Drag and drop your screenshots or click to browse
4. Arrange in the order you want (first screenshot is most important)

**Recommended order:**
1. Poem Display (main feature)
2. Welcome Screen
3. Archive
4. Settings
5. Another Poem (variety)

---

## Section 3: Promotional Text (Optional)

Max 170 characters. This appears at the top of your description and can be updated anytime.

```
FREE APP • NO ADS • NO SUBSCRIPTIONS

Sometimes Poetry is completely free. Optional tips available to support development.
```

---

## Section 4: Description (REQUIRED)

Max 4000 characters. Plain text only (no HTML).

```
Sometimes Poetry delivers classic poems at meaningful moments.

Experience carefully selected poetry that arrives when it's meant to—matched to the time of day, season, weather, and special occasions.

FEATURES

• Smart Delivery
Poems arrive at random times within your chosen hours, influenced by context like weather, season, and special dates.

• Beautiful Design
A minimal, elegant interface that puts the poetry first.

• Your Archive
Every poem is saved with favorites and delivery context.

• Complete Control
Choose delivery frequency (1-7 poems per week), set active hours, or pause anytime.

• No Ads, Ever
Sometimes Poetry is completely free with no advertisements.

SUPPORT THE APP

Optional tips available: Coffee, Nice Lunch, or Generous Support.

POETRY COLLECTION

151 classic poems from beloved poets, carefully selected for different moments and moods.

Sometimes Poetry is made with care for people who appreciate poetry.
```

---

## Section 5: Keywords (REQUIRED)

Max 100 bytes (approximately 100 characters). Separated by commas. Each keyword must be >2 characters.

```
poetry,poems,daily,literature,verse,reading,mindfulness,classic,moment,poet,book
```

**Note:** Don't duplicate your app name or company name in keywords.

---

## Section 6: Support URL (REQUIRED)

Must include protocol (http:// or https://) and lead to actual contact information.

```
https://github.com/oddyblue/Sometimes-Poetry-App
```

---

## Section 7: Marketing URL (Optional)

Leave blank or add a website about your app.

```
(leave blank)
```

---

## Section 8: Privacy Policy URL (REQUIRED for iOS)

Must be a working URL that displays your privacy policy.

```
https://oddyblue.github.io/Sometimes-Poetry-App/
```

---

## Section 9: Build (REQUIRED)

You'll select your uploaded build here. See PART 6 for upload instructions.

After uploading, click the **"+"** next to Build, select your build, and click **"Done"**.

---

## Section 10: Version Information

- **Version Number:** (Auto-filled from build) `1.0`
- **Copyright:** (Required) `2025 Mert Özel` (© symbol added automatically)

---

## Section 11: What's New in This Version

**For version 1.0, this field is OPTIONAL** (only required for updates).

But it's good to fill it anyway:

```
Initial release of Sometimes Poetry—classic poems delivered at meaningful moments.

• 151 classic poems
• Smart delivery based on time, season, and weather
• Beautiful minimal design
• Archive with favorites
• No ads, completely free
• Optional support tips available

Enjoy the poetry.
```

---

## Section 12: App Review Information (REQUIRED)

This information is **not visible to customers**—only for App Review team.

### Contact Information:

| Field | Value |
|-------|-------|
| **First Name** | Mert |
| **Last Name** | Özel |
| **Phone** | [Your phone number] |
| **Email** | [Your email] |

### Sign-in Information:

If your app requires login, provide demo credentials. Otherwise, leave blank.

- ☐ Sign-in required: No (leave unchecked)

### Notes (Optional but Recommended):

Max 4000 bytes. Help reviewers test your app:

```
TESTING INSTRUCTIONS:

1. Poem Delivery:
   - Poems are scheduled randomly within active hours
   - Default: 8 AM - 12 PM, daily
   - To test immediately: Settings → "Send Now"

2. In-App Purchases:
   - Three optional tips: Coffee ($2.99), Nice Lunch ($4.99), Generous Support ($9.99)
   - All are consumable (can be purchased multiple times)
   - Located in: Settings → "Support Sometimes"

3. Key Features to Test:
   - Settings → Send Now (test notification)
   - Settings → Frequency (change delivery rate)
   - Settings → Pause Delivery
   - Archive → Toggle favorites

Thank you for reviewing Sometimes Poetry!
```

---

## Section 13: Export Compliance (REQUIRED)

**Question:** "Is your app designed to use cryptography or does it contain or incorporate cryptography?"

- **Answer:** ○ No

**Explanation:** Your app uses standard HTTPS provided by iOS, which is exempt from export compliance documentation requirements.

---

# PART 6: UPLOAD BUILD FROM XCODE

Before you can submit, you need to upload a build.

## Step 6.1: Archive Your App

1. Open your project in Xcode
2. Select **Any iOS Device (arm64)** from the device menu (not a simulator)
3. Go to **Product → Archive**
4. Wait for the archive process to complete
5. The Organizer window will open automatically

## Step 6.2: Distribute to App Store Connect

1. In the Organizer, your archive will be selected
2. Click **"Distribute App"**
3. Select **"App Store Connect"**
4. Click **"Next"**
5. Select **"Upload"**
6. Click **"Next"**
7. Select **"Automatically manage signing"** (recommended)
8. Click **"Next"**
9. Review the app information
10. Click **"Upload"**

## Step 6.3: Wait for Processing

- Upload completes in 1-5 minutes
- Processing takes 5-15 minutes
- You'll receive an email when the build is ready
- Build status will change from "Processing" to "Ready to Submit"

## Step 6.4: Select Build in App Store Connect

1. Go back to App Store Connect
2. Navigate to: Apps → Sometimes Poetry → iOS App → 1.0 Prepare for Submission
3. Scroll to **"Build"** section
4. Click the **"+"** button
5. Select your uploaded build (version 1.0, build 1)
6. Click **"Done"**

---

# PART 7: FINAL REVIEW & SUBMIT

## Pre-Submission Checklist:

Go through each section and verify you see a **green checkmark** ✓ or completed status:

- [ ] **App Information** - Category, Content Rights, Age Rating filled
- [ ] **Pricing and Availability** - Price set to Free
- [ ] **App Privacy** - Privacy questionnaire completed
- [ ] **Screenshots** - Uploaded for required device sizes
- [ ] **Description** - Filled (under 4000 chars)
- [ ] **Keywords** - Filled (under 100 bytes)
- [ ] **Support URL** - Valid URL entered
- [ ] **Privacy Policy URL** - Valid URL entered
- [ ] **Build** - Build selected and showing as "Ready to Submit"
- [ ] **App Review Information** - Contact info and notes added
- [ ] **Export Compliance** - Answered "No" to cryptography question
- [ ] **Copyright** - Filled
- [ ] **In-App Purchases** - All 3 products created and ready

## Submit for Review:

1. In the version page (1.0 Prepare for Submission), scroll to the top
2. Look for the **"Add for Review"** or **"Submit for Review"** button (top right)
3. If you see errors, they'll be listed—fix them first
4. Click **"Add for Review"**
5. Review the summary page
6. Click **"Submit to App Review"**

**Status will change to:** "Waiting for Review"

---

# EXPECTED TIMELINE

| Stage | Duration |
|-------|----------|
| **Build Processing** | 5-15 minutes |
| **Waiting for Review** | 1-3 days |
| **In Review** | 1-2 days |
| **Total** | Usually 2-5 days |

---

# COMMON REJECTION REASONS (YOU'RE SAFE)

✅ **Your app is well-prepared:**

1. ✅ Privacy policy is live and accessible
2. ✅ In-app purchases are properly implemented and disclosed
3. ✅ No location permissions requested (using IP geolocation instead)
4. ✅ No placeholder content
5. ✅ Privacy manifest included (PrivacyInfo.xcprivacy)
6. ✅ All poems are public domain
7. ✅ App has real functionality and purpose
8. ✅ Export compliance correctly answered

---

# QUICK REFERENCE VALUES

**Copy-paste these as needed:**

```
App Name: Sometimes Poetry
Subtitle: Poetry at meaningful moments
Bundle ID: com.sometimes.app
Version: 1.0
SKU: sometimes-poetry-001

Privacy URL: https://oddyblue.github.io/Sometimes-Poetry-App/
Support URL: https://github.com/oddyblue/Sometimes-Poetry-App

Coffee: com.sometimes.app.support.small ($2.99)
Nice Lunch: com.sometimes.app.support.medium ($4.99)
Generous Support: com.sometimes.app.support.large ($9.99)

Copyright: 2025 Mert Özel
Category: Books
Age Rating: 4+
Price: Free
```

---

# AFTER APPROVAL

Once approved (status: "Ready for Sale"):

- Your app will appear on the App Store within 24 hours
- You'll receive an email notification
- App will be searchable by name and keywords
- Users can download immediately

---

**Sources:**
- [App Store Connect - Add a New App (Official Apple)](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
- [App Information Reference (Official Apple)](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
- [Screenshot Specifications (Official Apple)](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Platform Version Information (Official Apple)](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
- [Create Consumable In-App Purchases (Official Apple)](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/)
- [App Store Screenshot Requirements 2025 (SplitMetrics)](https://splitmetrics.com/blog/app-store-screenshots-aso-guide/)

**This guide is verified with official Apple documentation for December 2025.**
