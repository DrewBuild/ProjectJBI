# ☕ JustBeanIt

**Discover coffee worth sharing.**

JustBeanIt is a social coffee discovery platform built with **SwiftUI** and **Supabase** that helps coffee lovers find, rate, save, and share their favorite coffee experiences.

Unlike traditional review platforms, JustBeanIt focuses on recommendations from people you know and trust. Follow friends, discover new coffee shops, save places to visit, track your coffee journey, and become a trusted coffee source within your community.

---

## Features

### 📍 Coffee Discovery

* Discover local coffee shops
* Explore coffee shops on an interactive map
* Search by coffee shop or city
* View global coffee rankings
* View coffee shops visited by friends

### ☕ Coffee Posts

* Create coffee reviews
* Upload up to 3 photos per post
* Rate:

  * Service
  * Taste
  * Aesthetic
* Track drinks you've tried
* Save notes about coffee shops
* View detailed drink information

### 👥 Social Features

* Follow friends
* Private and public profiles
* Friends-only feed
* Global community feed
* Save posts for later
* Favorite personal coffee experiences
* Bean It interactions
* User mentions and tagging

### 🗺️ Explore

* Global coffee shop discovery
* Friends' favorite spots
* Coffee shop detail pages
* Top-rated locations
* Save places to visit later

### 📊 Personal Statistics

* Average rating tracking
* Weekly coffee activity
* Coffee shop history
* City and state tracking
* Visit streaks
* Coffee experience level progression

### 🔔 Notifications

* New followers
* Mentions
* Saved posts
* Bean It activity
* Push notification support

### 🔒 Privacy & Safety

* Private accounts
* User blocking
* User reporting
* Content moderation
* Secure authentication
* Email verification
* Sign in with Apple

---

## Technology Stack

### Frontend

* SwiftUI
* Combine
* MapKit
* PhotosUI
* UserNotifications

### Backend

* Supabase
* PostgreSQL
* Supabase Auth
* Supabase Storage
* Realtime Subscriptions

### Infrastructure

* Vercel
* GitHub
* Apple Developer Program

---

## Project Structure

```text
JustBeanIt
├── Authentication
├── Feed
├── Discover
├── Create Post
├── Profile
├── Stats
├── Notifications
├── Services
├── Models
├── Components
├── Supabase
├── Assets
└── Utilities
```

---

## Core App Sections

### Feed

View coffee experiences from friends or the global community.

### Discover

Find new coffee shops through maps, search, rankings, and recommendations.

### Post

Share drinks, coffee shops, ratings, and photos.

### Stats

Track your personal coffee journey and activity.

### Profile

Manage your profile, saved posts, favorites, and coffee history.

---

## Authentication

Supported authentication methods:

* Email & Password
* Username & Password
* Sign in with Apple

Features:

* Email verification
* Password reset
* Secure account management

---

## Roadmap

### Current Focus

* Feed improvements
* Discover enhancements
* Notification system
* Profile customization
* Performance optimization

### Future Features

* Official JustBeanIt account
* Coffee shop partnerships
* Featured coffee shops
* Community challenges
* Coffee events
* Business profiles
* Loyalty integrations

---

## Development Setup

### Requirements

* Xcode 16+
* iOS 18+
* Swift 6+
* Supabase Project

### Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/JustBeanIt.git
cd JustBeanIt
```

### Configure Environment

Create your configuration file and add:

```text
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

### Run

```bash
Open JustBeanIt.xcodeproj
Build and Run
```

---

## Database

Main tables:

```text
profiles
posts
coffee_shops
follows
saved_posts
favorites
bean_its
notifications
notification_preferences
post_mentions
blocked_users
reports
user_push_tokens
```

Storage Buckets:

```text
avatars
post-images
```

---

## Mission

JustBeanIt exists to make discovering great coffee more personal.

Instead of relying solely on anonymous reviews, users can explore coffee recommendations from friends and trusted coffee enthusiasts, helping them find experiences worth sharing.

---

## Status

🚧 Active Development

JustBeanIt is currently under active development and continuously evolving as new features, improvements, and community feedback are incorporated.

---

## License

All Rights Reserved.

This project and its source code may not be copied, modified, distributed, or used without explicit permission from the owner.

© JustBeanIt
