import SwiftUI
import Charts
import MapKit

struct DashboardView: View {
    @EnvironmentObject private var tripViewModel: TripViewModel
    @EnvironmentObject private var driverViewModel: DriverViewModel
    @EnvironmentObject private var vehicleViewModel: VehicleViewModel
    @EnvironmentObject private var maintenanceViewModel: MaintenanceViewModel
    @State private var showNotificationCenter = false
    @State private var selectedTrip: Trip?
    @State private var showTripDetail = false
    @State private var isRefreshing = false
    @State private var selectedMaintenanceRequest: MaintenanceRequest?
    @State private var showMaintenanceDetail = false
    @State private var refreshTimer: Timer?
    
    // Computed properties for maintenance requests
    private var allMaintenanceRequests: [MaintenanceRequest] {
        let requests = maintenanceViewModel.getPendingMaintenanceRequests(vehicles: vehicleViewModel.vehicles)
        return requests
    }
    
    private var overdueMaintenanceRequests: [MaintenanceRequest] {
        let currentDate = Date().timeIntervalSince1970
        let requests = allMaintenanceRequests.filter { !$0.isScheduled && !$0.isDriverRequest && $0.dueDateTimestamp < currentDate }
        return requests
    }
    
    private var driverRepairRequests: [MaintenanceRequest] {
        let requests = allMaintenanceRequests.filter { !$0.isScheduled && $0.isDriverRequest }
        return requests
    }
    
    var body: some View {
        NavigationStack {
        ScrollView {
                VStack(spacing: 36) {  // Increased from 24 to 36
                    // KPI Metrics (Fleet Summary)
                    VStack(spacing: 24) {  // Increased spacing
                        Text("Fleet Summary")
                            .font(.title2)  // Larger title
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        // KPI Grid with larger spacing
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 20),
                                GridItem(.flexible(), spacing: 20)
                            ],
                            spacing: 20
                        ) {
                            // Total Vehicles KPI
                            KPICard(
                                title: "Total Vehicles",
                                value: "",
                                icon: "car.fill",
                                details: [
                                    KPIDetail(
                                        label: "Active",
                                        value: "\(vehicleViewModel.activeVehicles.count)",
                                        color: Color(hex: "1E3A8A")  // Using primary gradient color
                                    ),
                                    KPIDetail(
                                        label: "Under Maintenance",
                                        value: "\(vehicleViewModel.vehicles.filter { !$0.isActive }.count)",
                                        color: Color(hex: "1E3A8A")  // Using primary gradient color
                                    ),
                                    KPIDetail(
                                        label: "On Trip",
                                        value: "0",
                                        color: Color(hex: "1E3A8A")  // Using primary gradient color
                                    )
                                ]
                            )
                            
                            // Drivers KPI
                            KPICard(
                                title: "Drivers",
                                value: "",
                                icon: "person.2.fill",
                                details: [
                                    KPIDetail(
                                        label: "Available",
                                        value: "\(driverViewModel.availableDrivers.count)",
                                        color: Color(hex: "059669")  // Using primary gradient color
                                    ),
                                    KPIDetail(
                                        label: "On Trip",
                                        value: "\(driverViewModel.drivers.filter { !$0.isAvailable && $0.isActive }.count)",
                                        color: Color(hex: "059669")  // Using primary gradient color
                                    )
                                ]
                            )
                            
                            // Maintenance KPI
                            KPICard(
                                title: "Maintenance",
                                value: "",
                                icon: "wrench.fill",
                                details: [
                                    KPIDetail(
                                        label: "Ongoing",
                                        value: "\(vehicleViewModel.vehicles.filter { !$0.isActive }.count)",
                                        color: Color(hex: "C2410C")  // Using primary gradient color
                                    ),
                                    KPIDetail(
                                        label: "Scheduled",
                                        value: "0",
                                        color: Color(hex: "C2410C")  // Using primary gradient color
                                    ),
                                    KPIDetail(
                                        label: "Overdue",
                                        value: "0",
                                        color: Color(hex: "C2410C")  // Using primary gradient color
                                    )
                                ]
                            )
                            
                            // Active Trips KPI
                            KPICard(
                                title: "Active Trips",
                                value: "",
                                icon: "arrow.triangle.swap",
                                details: [
                                    KPIDetail(
                                        label: "Ongoing",
                                        value: "\(tripViewModel.inProgressTrips.count)",
                                        color: Color(hex: "4F46E5")  // Using primary gradient color
                                    ),
                                    KPIDetail(
                                        label: "Scheduled",
                                        value: "0",
                                        color: Color(hex: "4F46E5")  // Using primary gradient color
                                    ),
                                    KPIDetail(
                                        label: "Delayed",
                                        value: "0",
                                        color: Color(hex: "4F46E5")  // Using primary gradient color
                                    )
                                ]
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)  // Added padding at the bottom of this section
                    
                    // Active Trips Section
                    VStack(alignment: .leading, spacing: 16) {
                    HStack {
                            Text("Ongoing Trips")
                                .font(.title2)
                                .fontWeight(.bold)
                        
                        Spacer()
                        
                            NavigationLink(destination: TripManagementView(initialFilter: .ongoing)) {
                            Text("View All")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if tripViewModel.inProgressTrips.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "car.2.fill")
                            .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text("No Active Trips")
                                        .font(.headline)
                                Text("All vehicles are currently stationary")
                                        .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(.systemGray4).opacity(0.5), radius: 5)
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(tripViewModel.inProgressTrips.prefix(2))) { trip in
                                    ActiveTripCard(trip: trip)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)  // Added padding at the bottom of this section
                    
                    // Maintenance and Repair Requests Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maintenance & Repair Requests")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Horizontal scrollable cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                // Overdue Maintenance Cards
                                ForEach(overdueMaintenanceRequests) { request in
                                    MaintenanceRequestCard(request: request, isOverdue: true) {
                                        // Call appropriate view model method to mark as completed
                                        Task {
                                            await maintenanceViewModel.markRequestCompleted(requestId: request.id)
                                            // Refresh data after marking as completed
                                            refreshAllData()
                                        }
                                    }
                                }
                                
                                // Driver-generated Repair Request Cards
                                ForEach(driverRepairRequests) { request in
                                    MaintenanceRequestCard(request: request, isOverdue: false) {
                                        // Call appropriate view model method to mark as completed
                                        Task {
                                            await maintenanceViewModel.markRequestCompleted(requestId: request.id)
                                            // Refresh data after marking as completed
                                            refreshAllData()
                                        }
                                    }
                                }
                                
                                // Empty state
                                if overdueMaintenanceRequests.isEmpty && 
                                    driverRepairRequests.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.green)
                                        Text("No Pending Requests")
                                            .font(.headline)
                                        Text("All maintenance is up to date")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 450, height: 300)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color(.systemGray3).opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 16)
                        }
                        .frame(height: 350) // Ensure container is tall enough for cards
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNotificationCenter = true
                    } label: {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isRefreshing = true
                        Task {
                            // Use the public methods from view models
                            await refreshAllData()
                            isRefreshing = false
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                isRefreshing ? 
                                    .linear(duration: 1).repeatForever(autoreverses: false) : 
                                    .default,
                                value: isRefreshing
                            )
                    }
                }
            }
            .sheet(isPresented: $showNotificationCenter) {
                NotificationCenterView()
            }
            .sheet(item: $selectedTrip) { trip in
                TripDetailView(trip: trip)
            }
            .sheet(isPresented: $showMaintenanceDetail) {
                if let request = selectedMaintenanceRequest {
                    MaintenanceDetailView(person: request.personnel)
                }
            }
        }
        .onAppear {
            // Initial data load
            Task {
                await refreshAllData()
            }
            
            // Setup timer to refresh data every 30 seconds
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                Task {
                    await refreshAllData()
                }
            }
        }
        .onDisappear {
            // Clean up resources when the view disappears
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
    
    private func refreshAllData() {
        // Use public methods to refresh data
        Task {
            await tripViewModel.loadTrips()
            await vehicleViewModel.fetchVehicles()
            await maintenanceViewModel.fetchMaintenanceRequests()
        }
    }
    
    var maintenanceRequestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Maintenance Requests", count: allMaintenanceRequests.count)
            
            if maintenanceViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if allMaintenanceRequests.isEmpty {
                Text("No maintenance requests")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        // Using a more explicit approach for ForEach
                        ForEach(0..<allMaintenanceRequests.count, id: \.self) { index in
                            let request = allMaintenanceRequests[index]
                            VStack(alignment: .leading, spacing: 12) {
                                Text("\(request.vehicle.make) \(request.vehicle.model)")
                                    .font(.headline)
                                
                                Text(request.vehicle.registrationNumber)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Divider()
                                
                                Text("Issue: \(request.problem)")
                                    .fontWeight(.medium)
                                
                                Text(request.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button("Mark as Completed") {
                                    Task {
                                        await maintenanceViewModel.markRequestCompleted(requestId: request.id)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding()
                            .frame(width: 300, height: 200)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// KPI Detail Model
struct KPIDetail {
    let label: String
    let value: String
    let color: Color
}

// KPI Card Component
struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let details: [KPIDetail]
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon and title
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: iconGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
//                    .shadow(color: iconGradient[0].opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text(title)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 12) {
                ForEach(details, id: \.label) { detail in
                    HStack(alignment: .center, spacing: 12) {
                        // Indicator dot (using primary color)
                        Circle()
                            .fill(iconGradient[0])
                            .frame(width: 8, height: 8)
                        
                        // Label and value
            HStack {
                            Text(detail.label)
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                
                Spacer()
                
                            Text(detail.value)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(iconGradient[0])
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(cardGradient)
                    .opacity(isHovered ? 0.15 : 0.1)
                
                // Glass effect overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            iconGradient[0].opacity(isHovered ? 0.3 : 0.1),
                            iconGradient[1].opacity(isHovered ? 0.2 : 0.05),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: iconGradient[0].opacity(0.1), radius: isHovered ? 15 : 10, x: 0, y: 4)
        .shadow(color: iconGradient[1].opacity(0.05), radius: isHovered ? 5 : 1, x: 0, y: 1)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
    }
    
    // Gradient colors based on card type with semantic meaning
    private var iconGradient: [Color] {
        switch title {
        case "Total Vehicles":
            // Deep Blue to Royal Blue - Automotive industry standard colors
            // Represents reliability, professionalism, and trust
            return [Color(hex: "1E3A8A"), Color(hex: "3B82F6")]
        case "Drivers":
            // Forest Green to Emerald - Human resource management colors
            // Represents growth, safety, and personnel
            return [Color(hex: "059669"), Color(hex: "34D399")]
        case "Maintenance":
            // Deep Orange to Amber - Universal maintenance colors
            // Represents caution, attention, and industrial standards
            return [Color(hex: "C2410C"), Color(hex: "F59E0B")]
        case "Active Trips":
            // Indigo to Purple - Movement and energy colors
            // Represents dynamic activity and navigation
            return [Color(hex: "4F46E5"), Color(hex: "8B5CF6")]
        default:
            return [.blue, .blue.opacity(0.7)]
        }
    }
    
    // Card background gradient based on card type
    private var cardGradient: some ShapeStyle {
        LinearGradient(
            colors: iconGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    var isFullWidth: Bool = false
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(title, systemImage: icon)
                        .font(.headline)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .frame(maxWidth: isFullWidth ? .infinity : nil)
        .background {
            if isFullWidth {
                // Regular card background for full-width cards
                Color(.systemBackground)
            } else {
                // Enhanced glass effect for small cards
                ZStack {
                    Color(.systemBackground)
                        .opacity(0.7)
                    
                    // Enhanced gradient overlay
                    LinearGradient(
                        colors: [
                            .white.opacity(0.7),
                            .white.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .blur(radius: 0.5)
                .background(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        // Multiple layered shadows for depth
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
        // Enhanced border for glass effect
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    .linearGradient(
                        colors: [
                            .white.opacity(0.8),
                            .white.opacity(0.2),
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isFullWidth ? 0 : 1
                )
        )
        // Outer glow effect
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.1), lineWidth: isFullWidth ? 0 : 2)
                .blur(radius: 4)
        )
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let valueColor: Color
    let icon: String?
    
    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundStyle(valueColor)
        }
    }
}

struct NotificationCenterView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Empty notifications array that would be populated from a real data source
    @State private var notifications: [NotificationItem] = []
    
    enum NotificationType {
        case driver
        case maintenance
    }
    
    struct NotificationItem: Identifiable {
        let id: Int
        let title: String
        let message: String
        let time: String
        let type: NotificationType
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Notification List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // If no notifications
                        if notifications.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.gray.opacity(0.5))
                                    .padding(.top, 60)
                                
                                Text("No Notifications")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                
                                Text("You're all caught up!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.vertical, 40)
                        } else {
                            // Today's notifications
                            if let todayNotifications = groupedNotifications["Today"], !todayNotifications.isEmpty {
                                NotificationDateHeader(title: "Today")
                                
                                ForEach(todayNotifications) { notification in
                                    NotificationRow(
                                        title: notification.title,
                                        message: notification.message,
                                        time: notification.time,
                                        type: notification.type
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                            
                            // Earlier notifications
                            if let earlierNotifications = groupedNotifications["Earlier"], !earlierNotifications.isEmpty {
                                NotificationDateHeader(title: "Earlier")
                                
                                ForEach(earlierNotifications) { notification in
                                    NotificationRow(
                                        title: notification.title,
                                        message: notification.message,
                                        time: notification.time,
                                        type: notification.type
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Group notifications by date category
    private var groupedNotifications: [String: [NotificationItem]] {
        var groups: [String: [NotificationItem]] = [
            "Today": [],
            "Earlier": []
        ]
        
        for notification in notifications {
            if notification.time.contains("minutes ago") || 
               notification.time.contains("hour ago") || 
               notification.time.contains("hours ago") {
                groups["Today", default: []].append(notification)
            } else {
                groups["Earlier", default: []].append(notification)
            }
        }
        
        return groups
    }
}

struct NotificationDateHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground).opacity(0.5))
    }
}

struct NotificationRow: View {
    let title: String
    let message: String
    let time: String
    let type: NotificationCenterView.NotificationType
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(type == .driver ? .blue : .orange)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: type == .driver ? "person.fill" : "wrench.fill")
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .background(Color(.systemBackground))
    }
}

struct FrequentRepairRow: View {
    let icon: String
    let iconColor: Color
    let repairType: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }
            
            // Repair Type
            Text(repairType)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MaintenanceRequest Card Component
struct MaintenanceRequestCard: View {
    let request: MaintenanceRequest
    let isOverdue: Bool
    let onMarkCompleted: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with fixed height
            HStack(spacing: 12) {
                Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "wrench.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isOverdue ? Color.red : Color.orange)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isOverdue ? "Maintenance Due" : "Repair Request")
                        .font(.headline)
                    
                    Text(request.vehicle.registrationNumber)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(isOverdue ? "Overdue" : "Pending")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isOverdue ? Color.red : Color.orange)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 16)
            
            Divider()
                .padding(.bottom, 16)
            
            // Details section with fixed layout
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text("Vehicle:")
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    Text(request.vehicle.make + " " + request.vehicle.model)
                        .fontWeight(.medium)
                }
                
                HStack(alignment: .top) {
                    Text(isOverdue ? "Due Date:" : "Reported:")
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    Text(formattedDate(isOverdue ? request.dueDateTimestamp : request.createdTimestamp))
                        .fontWeight(.medium)
                }
                
                if !isOverdue {
                    HStack(alignment: .top) {
                        Text("Issue:")
                            .foregroundStyle(.secondary)
                            .frame(width: 100, alignment: .leading)
                        
                        Text(request.problem)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            Spacer(minLength: 20)
            
            // Priority indicator with fixed position at bottom
            if !isOverdue {
                Divider()
                    .padding(.vertical, 12)
                
                HStack {
                    Text("Priority:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Simulated priority based on the issue description length
                    let priority = request.problem.count > 30 ? "High" : "Medium"
                    Text(priority)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(priority == "High" ? Color.red : Color.orange)
                    
                    Spacer()
                    
                    // Mark as completed button moved to bottom right
                    Button(action: onMarkCompleted) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Mark as completed")
                                .font(.footnote)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.8))
                        .foregroundStyle(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.borderless)
                }
            } else {
                Divider()
                    .padding(.vertical, 12)
                
                HStack {
                    Spacer()
                    
                    // Mark as completed button for overdue cases
                    Button(action: onMarkCompleted) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Mark as completed")
                                .font(.footnote)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.8))
                        .foregroundStyle(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(20)
        .frame(width: 450, height: 350)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
        .shadow(
            color: Color(.systemGray3).opacity(0.3),
            radius: 10,
            x: 0,
            y: 5
        )
    }
    
    private func formattedDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MaintenanceRequest Model
struct MaintenanceRequest: Identifiable {
    let id: String
    let vehicle: Vehicle
    let problem: String
    let description: String
    let dueDateTimestamp: Double
    let createdTimestamp: Double
    let isDriverRequest: Bool
    var isScheduled: Bool = false
    let personnel: MaintenancePersonnel
}

// Helper Components
struct SectionHeader: View {
    var title: String
    var count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text("\(count) total")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

#Preview {
    DashboardView()
        .environmentObject(TripViewModel())
        .environmentObject(DriverViewModel())
        .environmentObject(VehicleViewModel())
} 
