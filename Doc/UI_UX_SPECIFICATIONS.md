# Market Hub - UI/UX Specifications

## 1. DESIGN SYSTEM

### 1.1 Color Palette

```dart
// lib/core/constants/color_constants.dart
import 'package:flutter/material.dart';

class ColorConstants {
  // Primary Colors
  static const Color primaryColor = Color(0xFF1918BC);
  static const Color primaryLight = Color(0xFF4847E0);
  static const Color primaryDark = Color(0xFF0F0E8A);
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF646464);
  static const Color textHint = Color(0xFF9E9E9E);
  
  // Market Colors
  static const Color positiveGreen = Color(0xFF00C853);
  static const Color negativeRed = Color(0xFFFF1744);
  
  // UI Element Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color inputBackground = Color(0x24808080);
  static const Color navBarBackground = Color(0x14808080);
}
```

---

## 2. SCREEN LAYOUTS

### 2.1 Splash Screen
```
┌─────────────────────────────┐
│                             │
│                             │
│                             │
│        ┌─────────┐          │
│        │  LOGO   │          │
│        │  (GIF)  │          │
│        └─────────┘          │
│                             │
│        Market Hub           │
│                             │
│                             │
│       [Loading...]          │
│                             │
└─────────────────────────────┘
```

### 2.2 Registration Screen
```
┌─────────────────────────────┐
│  ← Back                     │
├─────────────────────────────┤
│      Hello there,           │
│   Register Account          │
│                             │
│  ┌───────────────────────┐  │
│  │ Full Name             │  │
│  └───────────────────────┘  │
│                             │
│  ┌───┐ ┌─────────────────┐  │
│  │+91│ │ WhatsApp Number │  │
│  └───┘ └─────────────────┘  │
│                             │
│  ┌───┐ ┌─────────────────┐  │
│  │+91│ │ Phone Number    │  │
│  └───┘ └─────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ Email Address         │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ Pincode               │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ Visiting Card      📤 │  │
│  └───────────────────────┘  │
│                             │
│  ☑ I accept Terms & Policy  │
│                             │
│  ┌───────────────────────┐  │
│  │      REGISTER         │  │
│  └───────────────────────┘  │
│                             │
│  ─────── OR ────────        │
│                             │
│  Already have account?      │
│         Log In              │
└─────────────────────────────┘
```

### 2.3 Email Verification Screen
```
┌─────────────────────────────┐
│  ← Back                     │
├─────────────────────────────┤
│                             │
│        ┌───────┐            │
│        │  📧   │            │
│        └───────┘            │
│                             │
│      Verify Email           │
│                             │
│   Enter OTP sent to:        │
│   user@email.com            │
│                             │
│   ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│   │   │ │   │ │   │ │   │   │
│   └───┘ └───┘ └───┘ └───┘   │
│                             │
│  ┌───────────────────────┐  │
│  │     VERIFY OTP        │  │
│  └───────────────────────┘  │
│                             │
│     Resend OTP (30s)        │
│                             │
│     Change Email            │
│                             │
└─────────────────────────────┘
```

### 2.4 PIN Setup Screen
```
┌─────────────────────────────┐
│                             │
├─────────────────────────────┤
│                             │
│        ┌───────┐            │
│        │  🔒   │            │
│        └───────┘            │
│                             │
│      Set Your PIN           │
│                             │
│   Create a 4-digit PIN      │
│                             │
│   ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│   │ • │ │ • │ │ • │ │ • │   │
│   └───┘ └───┘ └───┘ └───┘   │
│                             │
│   Confirm PIN               │
│                             │
│   ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│   │ • │ │ • │ │   │ │   │   │
│   └───┘ └───┘ └───┘ └───┘   │
│                             │
│  ┌───────────────────────┐  │
│  │    SET PIN & CONTINUE │  │
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
```

### 2.5 Plan Selection Screen
```
┌─────────────────────────────┐
│                             │
│      Choose Your Plan       │
│                             │
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │      BASIC PLAN         │ │
│ │                         │ │
│ │   ₹999 / month          │ │
│ │                         │ │
│ │   ✓ Feature 1           │ │
│ │   ✓ Feature 2           │ │
│ │   ✓ Feature 3           │ │
│ │                         │ │
│ │   [ SELECT ]            │ │
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│       ● ○ ○                 │
│    (Page indicators)        │
│                             │
│  ← Swipe to see more →      │
│                             │
└─────────────────────────────┘
```

### 2.6 Login Screen
```
┌─────────────────────────────┐
│                             │
│        ┌─────────┐          │
│        │  LOGO   │          │
│        └─────────┘          │
│                             │
│      Welcome Back           │
│                             │
│        ┌───────┐            │
│        │  🔒   │            │
│        └───────┘            │
│                             │
│   Enter your 4 Digit PIN    │
│                             │
│   ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│   │   │ │   │ │   │ │   │   │
│   └───┘ └───┘ └───┘ └───┘   │
│                             │
│                             │
│  New User? Register Now     │
│                             │
│       Forget PIN            │
│                             │
└─────────────────────────────┘
```

### 2.7 Home Screen
```
┌─────────────────────────────┐
│  Hello, Prasham Mehta    👤 │
├─────────────────────────────┤
│                             │
│  UPDATES                    │
│                             │
│ ┌─────────────────────────┐ │
│ │ ┌───┐                   │ │
│ │ │IMG│  Update Title     │ │
│ │ └───┘                   │ │
│ │  Short description...   │ │
│ │                         │ │
│ │  📷 View Image  📄 PDF  │ │
│ │                   14:30 │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │  Another Update         │ │
│ │  Description text...    │ │
│ │                   12:00 │ │
│ └─────────────────────────┘ │
│                             │
│                             │
├─────────────────────────────┤
│ 🏠  📈  💹  📰  ⭐          │
│Home Future Spot Alert Watch │
└─────────────────────────────┘
```

### 2.8 Future Screen
```
┌─────────────────────────────┐
│  Future                     │
├─────────────────────────────┤
│ [Future] [Stock] [Settlement]│
├─────────────────────────────┤
│ [London][China][US][FX][Ref]│
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │ COPPER                ⭐ │ │
│ │                         │ │
│ │ Last: $9,245.00         │ │
│ │ High: $9,300   Low: $9,100│
│ │ Change: +45.00 (+0.49%) │ │
│ │ Time: 14:30:25          │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ALUMINIUM             ⭐ │ │
│ │                         │ │
│ │ Last: $2,456.00         │ │
│ │ High: $2,480   Low: $2,440│
│ │ Change: -12.00 (-0.49%) │ │
│ │ Time: 14:30:25          │ │
│ └─────────────────────────┘ │
│                             │
├─────────────────────────────┤
│ 🏠  📈  💹  📰  ⭐          │
└─────────────────────────────┘
```

### 2.9 Spot Price Screen
```
┌─────────────────────────────┐
│  Spot Price                 │
├─────────────────────────────┤
│ [Base Metal]       [BME]    │
├─────────────────────────────┤
│                             │
│ ┌───────┐  ┌───────┐        │
│ │ 🥉    │  │ 🥈    │        │
│ │Copper │  │Brass  │        │
│ └───────┘  └───────┘        │
│                             │
│ ┌───────┐  ┌───────┐        │
│ │ 🔫    │  │ ⚗️    │        │
│ │GunMetal│ │ Lead  │        │
│ └───────┘  └───────┘        │
│                             │
│ ┌───────┐  ┌───────┐        │
│ │ 🪙    │  │ 🥫    │        │
│ │Nickel │  │ Tin   │        │
│ └───────┘  └───────┘        │
│                             │
│ ┌───────┐  ┌───────┐        │
│ │ ⬜    │  │ 🔲    │        │
│ │ Zinc  │  │Aluminium│      │
│ └───────┘  └───────┘        │
│                             │
├─────────────────────────────┤
│ 🏠  📈  💹  📰  ⭐          │
└─────────────────────────────┘
```

### 2.10 Alert Screen
```
┌─────────────────────────────┐
│  Alert                      │
├─────────────────────────────┤
│                             │
│ [Live Feed] [News] [Hindi]  │
│ [Circular] [Calendar]       │
│                             │
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │ ┌───┐                   │ │
│ │ │IMG│ News Headline     │ │
│ │ └───┘                   │ │
│ │ Brief summary of the    │ │
│ │ news article...         │ │
│ │              2 hrs ago  │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Another News Item       │ │
│ │ Summary text here...    │ │
│ │              5 hrs ago  │ │
│ └─────────────────────────┘ │
│                             │
├─────────────────────────────┤
│ 🏠  📈  💹  📰  ⭐          │
└─────────────────────────────┘
```

### 2.11 Watchlist Screen
```
┌─────────────────────────────┐
│  Watchlist                  │
├─────────────────────────────┤
│ [Future]         [Spot]     │
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │ COPPER (LME)          🗑│ │
│ │                         │ │
│ │ Last: $9,245.00         │ │
│ │ Change: +45.00 (+0.49%) │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ USD/INR               🗑│ │
│ │                         │ │
│ │ Rate: 83.25             │ │
│ │ Change: -0.12 (-0.14%)  │ │
│ └─────────────────────────┘ │
│                             │
│                             │
│  ┌───────────────────────┐  │
│  │ Your watchlist is     │  │
│  │ empty! Add items from │  │
│  │ Future or Spot pages  │  │
│  └───────────────────────┘  │
│                             │
├─────────────────────────────┤
│ 🏠  📈  💹  📰  ⭐          │
└─────────────────────────────┘
```

### 2.12 Profile Screen
```
┌─────────────────────────────┐
│  ← Profile                  │
├─────────────────────────────┤
│                             │
│      ┌───────────┐          │
│      │   👤      │          │
│      │  Avatar   │          │
│      └───────────┘          │
│                             │
│      Prasham Mehta          │
│      Pro Plan               │
│      Valid till: 12 Feb 2026│
│                             │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐    │
│  │ ℹ️  About Us       →│    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 📞 Contact Us      →│    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 💬 Feedback        →│    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 📜 Terms & Cond.   →│    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 🔐 Change PIN      →│    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 🚪 Logout          →│    │
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘
```

---

## 3. COMPONENT SPECIFICATIONS

### 3.1 Market Data Card

```dart
// Real-time update card for future/spot data
Widget MarketDataCard({
  required String name,
  required double price,
  required double change,
  required double high,
  required double low,
  required DateTime lastUpdate,
  required bool isInWatchlist,
  required VoidCallback onWatchlistToggle,
}) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyles.h4),
            IconButton(
              icon: Icon(
                isInWatchlist ? Icons.star : Icons.star_border,
                color: isInWatchlist ? Colors.amber : Colors.grey,
              ),
              onPressed: onWatchlistToggle,
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: TextStyles.priceText,
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Text(
              'High: \$${high.toStringAsFixed(2)}',
              style: TextStyles.labelMedium,
            ),
            SizedBox(width: 16),
            Text(
              'Low: \$${low.toStringAsFixed(2)}',
              style: TextStyles.labelMedium,
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: change >= 0 
                  ? ColorConstants.positiveGreen.withOpacity(0.1)
                  : ColorConstants.negativeRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}',
                style: change >= 0 
                  ? TextStyles.changePositive 
                  : TextStyles.changeNegative,
              ),
            ),
            Text(
              DateFormat('HH:mm:ss').format(lastUpdate),
              style: TextStyles.labelSmall,
            ),
          ],
        ),
      ],
    ),
  );
}
```

### 3.2 News Card

```dart
Widget NewsCard({
  required String title,
  required String summary,
  String? imageUrl,
  required DateTime publishedAt,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    summary,
                    style: TextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(publishedAt),
                    style: TextStyles.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 3.3 Tab Bar Style

```dart
// Standard tab bar for the app
TabBar(
  controller: tabController,
  isScrollable: true,
  labelColor: ColorConstants.primaryColor,
  unselectedLabelColor: ColorConstants.textSecondary,
  labelStyle: TextStyles.labelLarge,
  unselectedLabelStyle: TextStyles.labelMedium,
  indicator: BoxDecoration(
    border: Border(
      bottom: BorderSide(
        color: ColorConstants.primaryColor,
        width: 2,
      ),
    ),
  ),
  tabs: [
    Tab(text: 'Tab 1'),
    Tab(text: 'Tab 2'),
    Tab(text: 'Tab 3'),
  ],
)
```

---

## 4. ANIMATION SPECIFICATIONS

### 4.1 Page Transitions
- **Type:** Cupertino (iOS-style slide)
- **Duration:** 300ms
- **Curve:** Curves.easeInOut

### 4.2 Loading States
- **Shimmer:** For list items while loading
- **Circular Progress:** For button loading states
- **Skeleton:** For cards while fetching data

### 4.3 Price Change Animation
```dart
// When price updates, briefly flash the background
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  color: hasJustChanged 
    ? (isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))
    : Colors.transparent,
  child: PriceWidget(),
)
```

### 4.4 Watchlist Star Animation
```dart
// Scale animation when adding to watchlist
AnimatedScale(
  scale: isAnimating ? 1.2 : 1.0,
  duration: Duration(milliseconds: 200),
  child: Icon(
    isInWatchlist ? Icons.star : Icons.star_border,
    color: isInWatchlist ? Colors.amber : Colors.grey,
  ),
)
```

---

## 5. RESPONSIVE DESIGN

### 5.1 Breakpoints
- Small phone: < 360dp
- Regular phone: 360-400dp
- Large phone: > 400dp
- Tablet: > 600dp

### 5.2 Grid Layouts
- Spot Price metals: 2 columns on phone, 4 on tablet
- Plan cards: 1 visible on phone, 2 on tablet
- News grid: 1 column on phone, 2 on tablet

---

## 6. ACCESSIBILITY

- Minimum touch target: 48x48dp
- Text scaling support up to 1.5x
- Semantic labels for icons
- High contrast text (4.5:1 ratio minimum)
- Screen reader support for market data

---

## 7. ERROR STATES

### 7.1 Network Error
```
┌─────────────────────────────┐
│         📡                  │
│                             │
│   No Internet Connection    │
│                             │
│   Please check your         │
│   network and try again     │
│                             │
│     [ RETRY ]               │
│                             │
└─────────────────────────────┘
```

### 7.2 Empty State
```
┌─────────────────────────────┐
│         📭                  │
│                             │
│   No items found            │
│                             │
│   Your watchlist is empty.  │
│   Add items from Future or  │
│   Spot Price sections.      │
│                             │
└─────────────────────────────┘
```

### 7.3 Loading State
```
┌─────────────────────────────┐
│ ┌─────────────────────────┐ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ │ (Shimmer)
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓           │ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓        │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓           │ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓        │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

This document provides the complete UI/UX specifications for the Market Hub application.
