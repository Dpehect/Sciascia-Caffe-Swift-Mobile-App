# Sciascia Caffè 1919 - Swift Mobile App

Sciascia Caffè 1919 is a premium iOS application designed as a modern mobile companion for the historic Sciascia Caffè located in Rome, Italy. The application bridges the gap between traditional Italian coffee culture and modern mobile technologies, offering customers and staff an immersive digital experience.

## Project Overview and Purpose

The primary objective of this project is to capture the essence of a historic Roman cafe and translate it into a digital companion. Rather than building a generic order-management tool, this app focuses on enhancing user engagement through interactive elements. 

At the center of this experience is the Augmented Reality (AR) Menu. By pointing their device camera at a table or flat surface, users can preview drinks and pastries in 3D. This helps visualize the authentic presentation of Italian specialties—such as the double-shot espresso topped with cocoa powder—before placing an order. 

For cafe operations, the app provides staff with inventory dashboards, analytics, and table tracking tools, ensuring that baristas can manage daily operations with minimal friction.

## Key Features

### Immersive AR Menu
The AR Menu detects horizontal surfaces in the room and anchors virtual models of popular menu items directly onto the table. Customers can inspect, rotate, and scale 3D representations of Espresso Classics, Italian Pastries, and Classic Desserts. The interface displays floating names, pricing, expandable ingredient lists, caffeine levels, calorie counts, and allergen disclosures. Orders can be placed directly from this interactive AR viewport.

### Home Dashboard
Upon launching the application, users are greeted with a customized dashboard displaying historic Sciascia Caffè styling, the current calendar date, and active loyalty statistics. It includes a quick reordering section that lists recent adisyon codes, enabling users to duplicate and place previous orders with a single tap.

### Loyalty Stamp Program
The loyalty program replicates a physical stamp card. When a registered customer is assigned to an order, the stamp card displays a grid of ten circular slots. Completed purchases populate these slots with golden-accented coffee cup icons, utilizing spring transition animations. Every drink order increments the card count, resetting once ten stamps are accumulated.

### Biometric Security Access
The Staff Mode dashboard, which controls inventory levels and stock adjustments, is secured using Local Authentication. Baristas must verify their identity via Face ID or Touch ID before modifying SKU quantities, protecting critical operational parameters from unauthorized access.

### Real-Time Order Management
Staff can track current adisyon lists ordered by table number or takeaway status. Active orders can be filtered by preparation status (Preparing, Ready, Served, Cancelled). Swipe actions let baristas mark items as Served or Cancelled in real time.

### Analytics & Financial Reporting
An analytical dashboard displays daily and weekly sales trends using Swift Charts. It calculates gross revenue, operational cost, net margins, and category sales distributions. An integrated circular gauge visualizes net profit margin performance.

## Technical Stack

- **User Interface:** SwiftUI utilizing advanced transitions, matched geometry effects, spring animations, and particle confetti effects.
- **Augmented Reality:** RealityKit and ARKit for horizontal plane detection, scene anchor coordination, and 3D rendering.
- **Database Engine:** SwiftData for offline-first schema operations and local relationship persistence.
- **Security:** LocalAuthentication for native biometric (Face ID / Touch ID) credentials verification.
- **Shortcuts & Tips:** AppIntents for Siri Shortcut integrations, and TipKit for inline barista instruction notifications.
- **Charts:** Swift Charts for categorical and chronological data visualizations.
- **Widgets & Lock Screen:** WidgetKit and Live Activities for real-time order tracking on the device lock screen.

## Architecture and Design Decisions

The application follows an offline-first architecture to ensure reliability inside busy cafe environments where network connections may be unstable. SwiftData manages the object model graphs for Products, Customers, Orders, and OrderItems, persisting changes locally before attempting any cloud synchronizations.

### Design System and Color Palette
The user interface is designed using a bright, warm, and high-contrast color scheme inspired by Roman cafe interiors. Koyu tema (dark mode) is disabled to maintain a clean, classic aesthetic:
- **Backgrounds:** Warm Cream (#F8F4ED) and Soft Beige (#F5EDE4) provide a clean, warm background.
- **Typography:** Deep Brown (#2C2118) for primary headings and Dark Gray (#44403C) for body text ensure high readability.
- **Brand Colors:** Rich Espresso (#3C2A20) and Vibrant Orange (#FF6B00) serve as primary highlights.
- **Status Badges:** High-contrast amber, green, blue, and red tones communicate preparing, ready, served, and cancelled states clearly.

## AR Menu Implementation Details

The AR tracking loop is implemented using RealityKit's standard `ARView`. It boots an `ARWorldTrackingConfiguration` session with horizontal plane detection enabled. 

Once a horizontal plane is detected, the app generates a virtual anchor point. The interface overlays floating text meshes and spherical geometries representing cup orientations relative to the anchor coordinates in 3D space.

To maintain perfect compatibility and compile-safety across Apple platforms, all RealityKit dependencies are wrapped in conditional compilation checks:

```swift
#if os(iOS)
import ARKit
import RealityKit
#endif
```

On macOS build destinations, the application automatically switches to a 3D Simulation Mode. This mode uses standard SwiftUI 3D rotation structures to render and spin the coffee cup geometries on a virtual tabletop, enabling full feature validation and testing without active camera hardware.

## Platform Compatibility

- **iOS 17.0+ (Full Support):** Runs the full camera stream, AR plane tracking, biometric authentication, and haptic feedback profiles.
- **macOS 14.0+ (Simulation Mode):** Bypasses camera checks to show the interactive 3D simulation scene, using simulated passcode fallbacks for local security tests.

## How to Run the Project

1. Open Xcode 15 or higher.
2. Select the `followorder.xcodeproj` project file.
3. Ensure the active target is set to `followorder` with an iOS Simulator or connected iOS Device.
4. Press `Cmd + R` to build and run the application.

### Running Unit Tests
To run the database validation and order duplication test suite:
1. Open the Test navigator (`Cmd + 6`) in Xcode.
2. Select and run `testOrderCalculationsAndStockRestoration`.
3. Alternatively, you can run tests from the command line:
   ```bash
   xcodebuild -project followorder.xcodeproj -scheme followorder -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -only-testing:followorderTests test
   ```

## Walkthrough Video

A complete screen recording of the application is embedded below, showing the initial launch screen, HomeView dashboard navigation, the full interactive AR Menu experience (placing items, 3D rotation, ingredient expansions, calorie and allergen reviews, and checkout), the OrderListView queue management, and the Analytics dashboard.

![Walkthrough Demo](walkthrough_demo.mp4)

## Screenshots

Below are visual placeholders representing the key screens of the application:

### Home Dashboard and Menu List
*(Placeholder for Home and Menu layouts)*

### Interactive RealityKit AR View
*(Placeholder for 3D espresso projection with nutritional overlays)*

### Biometric Staff Inventory and Analytics
*(Placeholder for Face ID lock screen and Swift Charts performance graphs)*
