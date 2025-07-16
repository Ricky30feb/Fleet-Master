<div align="center">

<img src="https://readme-typing-svg.herokuapp.com?font=Orbitron&size=40&duration=3000&pause=1000&color=2E86AB&center=true&vCenter=true&width=600&lines=🚛+FLEET+MASTER+🚛;Advanced+Fleet+Management;iOS+Application" alt="Fleet Master" />

<svg width="100%" height="200" viewBox="0 0 800 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .truck {
        animation: drive 4s ease-in-out infinite;
      }
      .wheel {
        animation: rotate 1s linear infinite;
        transform-origin: center;
      }
      .road {
        stroke-dasharray: 20 10;
        animation: roadMove 2s linear infinite;
      }
      .cloud {
        animation: float 6s ease-in-out infinite;
      }
      .title-text {
        font-family: 'Arial', sans-serif;
        font-weight: bold;
        animation: glow 2s ease-in-out infinite alternate;
      }
      
      @keyframes drive {
        0%, 100% { transform: translateX(0px) translateY(0px); }
        25% { transform: translateX(100px) translateY(-2px); }
        50% { transform: translateX(200px) translateY(0px); }
        75% { transform: translateX(300px) translateY(-2px); }
      }
      
      @keyframes rotate {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
      }
      
      @keyframes roadMove {
        from { stroke-dashoffset: 0; }
        to { stroke-dashoffset: 30; }
      }
      
      @keyframes float {
        0%, 100% { transform: translateY(0px); }
        50% { transform: translateY(-10px); }
      }
      
      @keyframes glow {
        from { fill: #2E86AB; }
        to { fill: #A23B72; }
      }
    </style>
  </defs>
  
  <!-- Sky gradient -->
  <defs>
    <linearGradient id="skyGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#87CEEB;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#E0F6FF;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="100%" height="100%" fill="url(#skyGradient)" />
  
  <!-- Clouds -->
  <g class="cloud">
    <ellipse cx="100" cy="30" rx="20" ry="12" fill="white" opacity="0.8"/>
    <ellipse cx="110" cy="30" rx="25" ry="15" fill="white" opacity="0.8"/>
    <ellipse cx="120" cy="30" rx="20" ry="12" fill="white" opacity="0.8"/>
  </g>
  
  <g class="cloud" style="animation-delay: -2s;">
    <ellipse cx="300" cy="25" rx="15" ry="10" fill="white" opacity="0.7"/>
    <ellipse cx="310" cy="25" rx="20" ry="12" fill="white" opacity="0.7"/>
    <ellipse cx="320" cy="25" rx="15" ry="10" fill="white" opacity="0.7"/>
  </g>
  
  <!-- Road -->
  <rect x="0" y="150" width="100%" height="50" fill="#404040"/>
  <line class="road" x1="0" y1="175" x2="100%" y2="175" stroke="white" stroke-width="3"/>
  
  <!-- Truck -->
  <g class="truck">
    <!-- Truck body -->
    <rect x="50" y="120" width="80" height="30" fill="#2E86AB" rx="5"/>
    <!-- Truck cab -->
    <rect x="120" y="110" width="30" height="40" fill="#1F5F79" rx="3"/>
    <!-- Windows -->
    <rect x="125" y="115" width="20" height="15" fill="#87CEEB" rx="2"/>
    <!-- Wheels -->
    <circle class="wheel" cx="70" cy="155" r="8" fill="#333"/>
    <circle class="wheel" cx="110" cy="155" r="8" fill="#333"/>
    <circle class="wheel" cx="135" cy="155" r="8" fill="#333"/>
    <!-- Wheel centers -->
    <circle cx="70" cy="155" r="3" fill="#666"/>
    <circle cx="110" cy="155" r="3" fill="#666"/>
    <circle cx="135" cy="155" r="3" fill="#666"/>
  </g>
  
  <!-- Title -->
  <text x="400" y="80" class="title-text" font-size="24" text-anchor="middle" fill="#2E86AB">
    Fleet Management System
  </text>
</svg>

![iOS](https://img.shields.io/badge/iOS-15.0+-blue?style=for-the-badge&logo=ios&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.5+-orange?style=for-the-badge&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-blue?style=for-the-badge&logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-14.0+-blue?style=for-the-badge&logo=xcode&logoColor=white)

<p align="center">
  <strong>🚀 Next-Generation Fleet Management Solution for iOS 🚀</strong>
</p>

<p align="center">
  A powerful, intuitive, and feature-rich iOS application designed to revolutionize fleet management operations.
</p>

</div>

---

## 🌟 Features

<div align="center">

<svg width="100%" height="300" viewBox="0 0 800 300" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .feature-icon {
        animation: pulse 2s ease-in-out infinite;
      }
      .feature-text {
        font-family: 'Arial', sans-serif;
        font-size: 14px;
        fill: #333;
      }
      .feature-card {
        animation: slideIn 1s ease-out;
        filter: drop-shadow(0 4px 8px rgba(0,0,0,0.1));
      }
      .gps-signal {
        animation: ripple 2s ease-out infinite;
      }
      
      @keyframes pulse {
        0%, 100% { transform: scale(1); opacity: 1; }
        50% { transform: scale(1.1); opacity: 0.8; }
      }
      
      @keyframes slideIn {
        from { transform: translateY(50px); opacity: 0; }
        to { transform: translateY(0); opacity: 1; }
      }
      
      @keyframes ripple {
        0% { r: 5; opacity: 1; }
        100% { r: 20; opacity: 0; }
      }
    </style>
  </defs>
  
  <!-- Feature Cards -->
  <g class="feature-card">
    <rect x="50" y="50" width="150" height="80" fill="#E3F2FD" rx="10"/>
    <g class="feature-icon">
      <path d="M110 70 L130 85 L130 95 L110 110 L90 95 L90 85 Z" fill="#2196F3"/>
    </g>
    <text x="125" y="125" class="feature-text" text-anchor="middle">Real-time Tracking</text>
  </g>
  
  <g class="feature-card" style="animation-delay: 0.2s;">
    <rect x="250" y="50" width="150" height="80" fill="#E8F5E8" rx="10"/>
    <g class="feature-icon">
      <rect x="310" y="75" width="30" height="20" fill="#4CAF50" rx="3"/>
      <rect x="315" y="80" width="20" height="10" fill="#2E7D32" rx="1"/>
    </g>
    <text x="325" y="125" class="feature-text" text-anchor="middle">Fuel Management</text>
  </g>
  
  <g class="feature-card" style="animation-delay: 0.4s;">
    <rect x="450" y="50" width="150" height="80" fill="#FFF3E0" rx="10"/>
    <g class="feature-icon">
      <circle cx="525" cy="85" r="15" fill="#FF9800"/>
      <rect x="520" y="80" width="10" height="10" fill="#F57C00"/>
    </g>
    <text x="525" y="125" class="feature-text" text-anchor="middle">Maintenance</text>
  </g>
  
  <g class="feature-card" style="animation-delay: 0.6s;">
    <rect x="150" y="180" width="150" height="80" fill="#F3E5F5" rx="10"/>
    <g class="feature-icon">
      <rect x="210" y="205" width="30" height="20" fill="#9C27B0" rx="3"/>
      <circle cx="225" cy="210" r="3" fill="#FFFFFF"/>
    </g>
    <text x="225" y="255" class="feature-text" text-anchor="middle">Driver Analytics</text>
  </g>
  
  <g class="feature-card" style="animation-delay: 0.8s;">
    <rect x="350" y="180" width="150" height="80" fill="#FFEBEE" rx="10"/>
    <g class="feature-icon">
      <polygon points="425,205 435,215 425,225 415,215" fill="#F44336"/>
      <circle class="gps-signal" cx="425" cy="215" r="5" fill="none" stroke="#F44336" stroke-width="2"/>
    </g>
    <text x="425" y="255" class="feature-text" text-anchor="middle">Route Optimization</text>
  </g>
</svg>

</div>

### ✨ Key Capabilities

- 🛰️ **Real-time GPS Tracking** - Monitor your fleet's location and status in real-time
- ⛽ **Fuel Management** - Track fuel consumption and optimize costs
- 🔧 **Maintenance Scheduling** - Automated maintenance reminders and scheduling
- 📊 **Driver Analytics** - Comprehensive driver performance metrics
- 🗺️ **Route Optimization** - AI-powered route planning for maximum efficiency
- 📱 **Native iOS Experience** - Built with SwiftUI for seamless performance
- 🔔 **Smart Notifications** - Real-time alerts for critical fleet events
- 📈 **Business Intelligence** - Advanced reporting and analytics dashboard

---

## 🛠️ Technology Stack

<div align="center">

<svg width="100%" height="150" viewBox="0 0 600 150" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .tech-item {
        animation: techFloat 3s ease-in-out infinite;
      }
      .swift-logo {
        animation: swiftSpin 4s linear infinite;
      }
      .ios-logo {
        animation: iosPulse 2s ease-in-out infinite;
      }
      
      @keyframes techFloat {
        0%, 100% { transform: translateY(0px); }
        50% { transform: translateY(-5px); }
      }
      
      @keyframes swiftSpin {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
      }
      
      @keyframes iosPulse {
        0%, 100% { transform: scale(1); }
        50% { transform: scale(1.1); }
      }
    </style>
  </defs>
  
  <!-- Swift -->
  <g class="tech-item swift-logo">
    <circle cx="100" cy="75" r="30" fill="#FA7343"/>
    <text x="100" y="80" text-anchor="middle" fill="white" font-size="12" font-weight="bold">Swift</text>
  </g>
  
  <!-- SwiftUI -->
  <g class="tech-item" style="animation-delay: -1s;">
    <circle cx="200" cy="75" r="30" fill="#007AFF"/>
    <text x="200" y="80" text-anchor="middle" fill="white" font-size="10" font-weight="bold">SwiftUI</text>
  </g>
  
  <!-- iOS -->
  <g class="tech-item ios-logo" style="animation-delay: -2s;">
    <circle cx="300" cy="75" r="30" fill="#000000"/>
    <text x="300" y="80" text-anchor="middle" fill="white" font-size="12" font-weight="bold">iOS</text>
  </g>
  
  <!-- Xcode -->
  <g class="tech-item" style="animation-delay: -0.5s;">
    <circle cx="400" cy="75" r="30" fill="#1575F9"/>
    <text x="400" y="80" text-anchor="middle" fill="white" font-size="11" font-weight="bold">Xcode</text>
  </g>
  
  <!-- Core Data -->
  <g class="tech-item" style="animation-delay: -1.5s;">
    <circle cx="500" cy="75" r="30" fill="#34C759"/>
    <text x="500" y="75" text-anchor="middle" fill="white" font-size="9" font-weight="bold">Core</text>
    <text x="500" y="85" text-anchor="middle" fill="white" font-size="9" font-weight="bold">Data</text>
  </g>
</svg>

</div>

- **iOS 15.0+** - Targeting modern iOS devices
- **Swift 5.5+** - Latest Swift language features
- **SwiftUI** - Declarative UI framework
- **Core Data** - Local data persistence
- **MapKit** - Native mapping and location services
- **CoreLocation** - GPS and location tracking
- **UserNotifications** - Push notifications and alerts
- **Combine** - Reactive programming framework

---

## 🚀 Getting Started

### Prerequisites

<div align="center">

```bash
# Check your development environment
xcode-select --version
swift --version
```

</div>

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/Fleet-Master1.git
   cd Fleet-Master1
   ```

2. **Open in Xcode**
   ```bash
   open "Fleet Master.xcodeproj"
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `⌘ + R` to build and run

### Configuration

1. **Location Permissions** - The app requires location access for GPS tracking
2. **Notification Permissions** - Enable notifications for real-time alerts
3. **Network Access** - Ensure internet connectivity for real-time features

---

## 📱 Screenshots

<div align="center">

<svg width="100%" height="200" viewBox="0 0 800 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .phone {
        animation: phoneFloat 4s ease-in-out infinite;
      }
      .screen {
        animation: screenGlow 3s ease-in-out infinite;
      }
      .app-icon {
        animation: iconBounce 2s ease-in-out infinite;
      }
      
      @keyframes phoneFloat {
        0%, 100% { transform: translateY(0px) rotate(0deg); }
        50% { transform: translateY(-10px) rotate(2deg); }
      }
      
      @keyframes screenGlow {
        0%, 100% { opacity: 0.9; }
        50% { opacity: 1; }
      }
      
      @keyframes iconBounce {
        0%, 100% { transform: scale(1); }
        50% { transform: scale(1.1); }
      }
    </style>
  </defs>
  
  <!-- Phone mockup -->
  <g class="phone">
    <rect x="350" y="20" width="100" height="160" fill="#000" rx="15"/>
    <rect x="355" y="25" width="90" height="150" fill="#1E1E1E" rx="10"/>
    <rect class="screen" x="360" y="35" width="80" height="130" fill="#007AFF" rx="5"/>
    
    <!-- App interface mockup -->
    <rect x="365" y="40" width="70" height="20" fill="#FFFFFF" rx="3"/>
    <text x="400" y="52" text-anchor="middle" fill="#007AFF" font-size="8" font-weight="bold">Fleet Master</text>
    
    <!-- Map representation -->
    <rect x="365" y="65" width="70" height="50" fill="#E8F5E8" rx="3"/>
    <circle class="app-icon" cx="400" cy="90" r="8" fill="#FF6B6B"/>
    <circle cx="385" cy="80" r="3" fill="#4ECDC4"/>
    <circle cx="415" cy="100" r="3" fill="#45B7D1"/>
    
    <!-- Bottom buttons -->
    <rect x="365" y="125" width="15" height="15" fill="#FF6B6B" rx="2"/>
    <rect x="385" y="125" width="15" height="15" fill="#4ECDC4" rx="2"/>
    <rect x="405" y="125" width="15" height="15" fill="#96CEB4" rx="2"/>
    <rect x="425" y="125" width="15" height="15" fill="#FECA57" rx="2"/>
  </g>
  
  <text x="400" y="195" text-anchor="middle" fill="#666" font-size="12">Coming Soon - Screenshots will be updated as development progresses</text>
</svg>

</div>

---

## 🗂️ Project Structure

```
Fleet Master/
├── 📱 Fleet_MasterApp.swift      # Main app entry point
├── 🖼️  ContentView.swift         # Primary view controller
├── 🎨 Assets.xcassets/           # App icons and images
├── 🔍 Preview Content/           # SwiftUI preview assets
├── 🧪 Fleet MasterTests/         # Unit tests
├── 🎯 Fleet MasterUITests/       # UI tests
└── 📊 Fleet Master.xcodeproj/    # Xcode project file
```

---

## 🤝 Contributing

<div align="center">

<svg width="100%" height="100" viewBox="0 0 400 100" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .contributor {
        animation: contributorWave 3s ease-in-out infinite;
      }
      @keyframes contributorWave {
        0%, 100% { transform: translateY(0px); }
        50% { transform: translateY(-5px); }
      }
    </style>
  </defs>
  
  <circle class="contributor" cx="100" cy="50" r="20" fill="#FF6B6B"/>
  <circle class="contributor" cx="150" cy="50" r="20" fill="#4ECDC4" style="animation-delay: -0.5s;"/>
  <circle class="contributor" cx="200" cy="50" r="20" fill="#45B7D1" style="animation-delay: -1s;"/>
  <circle class="contributor" cx="250" cy="50" r="20" fill="#96CEB4" style="animation-delay: -1.5s;"/>
  <circle class="contributor" cx="300" cy="50" r="20" fill="#FECA57" style="animation-delay: -2s;"/>
  
  <text x="200" y="85" text-anchor="middle" fill="#333" font-size="12" font-weight="bold">Join Our Amazing Community!</text>
</svg>

</div>

We welcome contributions from the community! Here's how you can help:

1. **🍴 Fork the repository**
2. **🌿 Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **💾 Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **📤 Push to the branch** (`git push origin feature/AmazingFeature`)
5. **🔄 Open a Pull Request**

### Development Guidelines

- Follow Swift naming conventions
- Write unit tests for new features
- Update documentation as needed
- Ensure iOS compatibility (15.0+)

---

## 📄 License

<div align="center">

<svg width="100%" height="80" viewBox="0 0 300 80" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .license-text {
        animation: licenseGlow 4s ease-in-out infinite;
      }
      @keyframes licenseGlow {
        0%, 100% { fill: #666; }
        50% { fill: #333; }
      }
    </style>
  </defs>
  
  <rect x="50" y="20" width="200" height="40" fill="none" stroke="#DDD" stroke-width="2" rx="5"/>
  <text x="150" y="45" class="license-text" text-anchor="middle" font-size="14" font-weight="bold">MIT License</text>
</svg>

</div>

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact & Support

<div align="center">

<p>
  <a href="mailto:support@fleetmaster.com">📧 support@fleetmaster.com</a> |
  <a href="https://twitter.com/fleetmaster">🐦 @FleetMaster</a> |
  <a href="https://linkedin.com/company/fleetmaster">💼 LinkedIn</a>
</p>

<p>
  <strong>Made with ❤️ by Kushagra Kulshrestha</strong>
</p>

<svg width="100%" height="50" viewBox="0 0 400 50" xmlns="http://www.w3.org/2000/svg">
  <text x="200" y="30" text-anchor="middle" fill="#666" font-size="12">
    ⭐ If you found this project helpful, please give it a star! ⭐
  </text>
</svg>

</div>

---

<div align="center">

![Footer](https://readme-typing-svg.herokuapp.com?font=Orbitron&size=20&duration=3000&pause=1000&color=2E86AB&center=true&vCenter=true&width=600&lines=Thank+you+for+using+Fleet+Master!;Happy+Fleet+Management!+🚛✨)

</div>
