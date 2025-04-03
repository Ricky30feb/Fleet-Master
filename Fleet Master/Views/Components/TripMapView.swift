import SwiftUI
import MapKit
import Foundation
import Combine
import CoreLocation
import os.log

// Adopt the MapKit types directly
// Using @available to make compiler happy for backward compatibility
@available(iOS 16.0, *)
typealias MKLookAroundView = UIView

// Creating our own LookAround view for compilation purposes
@available(iOS 16.0, *)
class CustomLookAroundView: UIView {
    var scene: MKLookAroundScene?
}

struct TripMapView: View {
    let trips: [Trip]
    let locationManager: LocationManager
    
    @State private var selectedTrip: Trip?
    @State private var region = MKCoordinateRegion(
        // Center of India (approximate)
        center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
        // Zoom level suitable for India
        span: MKCoordinateSpan(latitudeDelta: 30.0, longitudeDelta: 30.0)
    )
    @State private var routeOverlays: [String: TripRouteOverlay] = [:]
    @State private var isHindiMode = false
    @State private var showDirections = false
    @State private var showTrafficInfo = true
    @State private var mapType: MapType = .standard
    @State private var refreshID = UUID()
    @State private var is3DMode = true
    
    // User location tracking
    @State private var trackUserLocation = false
    @State private var userLocationAuthorized = false
    
    @State private var isAssignedTrip: Bool = false
    @State private var showAllRoutes: Bool = false
    @State private var highlightSelectedRoute: Bool = false
    
    @State private var showLookAround: Bool = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showPlaceCard: Bool = false
    @State private var selectedPlace: MKMapItem?
    @State private var showDetailedAnalytics: Bool = false
    @State private var showWeatherOverlay: Bool = false
    @State private var detourAlert: Bool = false
    
    init(trips: [Trip], 
         locationManager: LocationManager, 
         isAssignedTrip: Bool = false,
         showAllRoutes: Bool = false,
         highlightSelectedRoute: Bool = false) {
        self.trips = trips
        self.locationManager = locationManager
        self.isAssignedTrip = isAssignedTrip
        self.showAllRoutes = showAllRoutes
        self.highlightSelectedRoute = highlightSelectedRoute
        
        // Check if any of the trips is assigned to a driver and vehicle and is in progress
        if let firstTrip = trips.first, 
            firstTrip.status == .ongoing &&
           firstTrip.driverId != nil &&
           firstTrip.vehicleId != nil {
            self.isAssignedTrip = true
        }
    }
    
    init(trips: [Trip], selectedTrip: Trip, locationManager: LocationManager, region: MKCoordinateRegion? = nil, showUserLocation: Bool = false, showDirections: Bool = true, isAssignedTrip: Bool = false, showAllRoutes: Bool = false, highlightSelectedRoute: Bool = true) {
        self.trips = trips
        self.selectedTrip = selectedTrip
        self.locationManager = locationManager
        if let region = region {
            self._region = State(initialValue: region)
        }
        self.trackUserLocation = showUserLocation
        self.showDirections = showDirections
        self.isAssignedTrip = isAssignedTrip
        self.showAllRoutes = showAllRoutes
        self.highlightSelectedRoute = highlightSelectedRoute
    }
    
    enum MapType: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case hybrid = "Satellite"
        case terrain = "Terrain"
        case flyover = "Flyover" // Added Apple's Flyover mode
        
        var id: String { rawValue }
        
        var hindiName: String {
            switch self {
            case .standard: return "मानक"
            case .hybrid: return "उपग्रह"
            case .terrain: return "इलाका"
            case .flyover: return "फ्लाईओवर"
            }
        }
    }
    
    var body: some View {
        // Break down complex expressions to help the compiler with type checking
        let mapViewContent = ZStack(alignment: .topTrailing) {
            // Helper function to prepare ProMapViewRepresentable with clear type annotations
            makeMapView()
            
            // Look Around view if available and active
            if showLookAround {
                makeLookAroundView()
            }
            
            // Map Controls - Top Right (Apple Maps style)
            makeMapControls()
            
            // Apple Maps Style Bottom Controls
            makeBottomControls()
            
            // Place Card View (like Apple Maps)
            if showPlaceCard, let place = selectedPlace {
                makePlaceCardView(place: place)
            }
            
            // Detailed Analytics Panel
            if showDetailedAnalytics {
                makeAnalyticsView()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            loadRoutes()
            checkLocationAuthorization()
            if selectedTrip == nil && !trips.isEmpty {
                selectedTrip = trips.first
            }
        }
        .onChange(of: selectedTrip) { _ in
            if let trip = selectedTrip {
                centerMapOnTrip(trip)
                
                // If Look Around is active, update the scene
                if showLookAround, #available(iOS 16.0, *) {
                    requestLookAroundScene(for: trip.endLocation)
                }
            }
        }
        .alert(isPresented: $detourAlert) {
            Alert(
                title: Text("Detour Detected"),
                message: Text("A vehicle has deviated from its planned route. Would you like to re-optimize?"),
                primaryButton: .default(Text("Re-optimize")) {
                    // Re-calculate routes
                    refreshID = UUID()
                    loadRoutes()
                },
                secondaryButton: .cancel()
            )
        }
        
        return mapViewContent
    }
    
    // Helper functions to break down complex expressions
    
    private func makeMapView() -> some View {
        ProMapViewRepresentable(
            trips: trips,
            selectedTrip: $selectedTrip,
            region: $region,
            routeOverlays: $routeOverlays,
            locationManager: locationManager,
            refreshID: refreshID,
            isHindiMode: isHindiMode,
            mapType: mapType,
            is3DMode: is3DMode,
            trackUserLocation: trackUserLocation,
            isAssignedTrip: isAssignedTrip,
            showAllRoutes: showAllRoutes,
            highlightSelectedRoute: highlightSelectedRoute,
            showLookAround: showLookAround,
            onPlaceSelected: { place in
                selectedPlace = place
                showPlaceCard = true
            }
        )
    }
    
    private func makeLookAroundView() -> some View {
        Group {
            if let lookAroundScene = lookAroundScene, #available(iOS 16.0, *) {
                VStack {
                    // Look Around Preview
                    LookAroundPreview(initialScene: lookAroundScene)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.top, 60)
                        .padding(.horizontal)
                }
            } else {
                // Fallback for iOS versions before 16.0
                VStack {
                    // Use center of region instead of last known location
                    LookAroundFallbackView(coordinate: region.center)
                        .frame(height: 200)
                        .padding(.top, 60)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private func makeMapControls() -> some View {
        VStack(spacing: 12) {
            // Map Layers Menu - Apple Maps Style
            Menu {
                Section("नक्शा प्रकार") {
                    ForEach(MapType.allCases) { type in
                    Button(action: {
                            mapType = type
                            // Enable 3D mode automatically for Flyover
                            if type == .flyover {
                                is3DMode = true
                            }
                        }) {
                            Label(
                                isHindiMode ? type.hindiName : type.rawValue,
                                systemImage: type == mapType ? "checkmark" : ""
                            )
                        }
                    }
                }
                
                Divider()
                
                Section("दृश्य विकल्प") {
                    Toggle(isOn: $is3DMode) {
                        Label(isHindiMode ? "3D दृश्य" : "3D View", systemImage: "cube")
                    }
                    
                    Toggle(isOn: $showTrafficInfo) {
                        Label(isHindiMode ? "ट्रैफिक" : "Traffic", systemImage: "car")
                    }
                    
                    Toggle(isOn: $showWeatherOverlay) {
                        Label(isHindiMode ? "मौसम" : "Weather", systemImage: "cloud.sun")
                    }
                }
            } label: {
                AppleMapControl(
                    symbol: "map",
                    backgroundColor: .ultraThinMaterial,
                    foregroundColor: .primary
                )
            }
            
            // Look Around Button - Apple Maps Style
            if #available(iOS 16.0, *) {
                makeLookAroundButton()
            }
            
            // User Location Button - Apple Maps Style
            makeLocationButton()
            
            // Analytics Button - Apple Maps Style
            makeAnalyticsButton()
            
            // Compass - Apple Maps Style
            if is3DMode {
                makeCompassButton()
            }
        }
        .padding(.top, 60)
        .padding(.trailing, 16)
    }
    
    private func makeLookAroundButton() -> some View {
        Button(action: {
                withAnimation {
                showLookAround.toggle()
                if showLookAround, let trip = selectedTrip {
                    requestLookAroundScene(for: trip.endLocation)
                }
            }
        }) {
            AppleMapControl(
                symbol: showLookAround ? "binoculars.fill" : "binoculars",
                backgroundColor: showLookAround ? .regularMaterial : .ultraThinMaterial,
                foregroundColor: showLookAround ? .blue : .primary
            )
        }
    }
    
    private func makeLocationButton() -> some View {
                Button(action: {
            if !userLocationAuthorized {
                locationManager.requestWhenInUseAuthorization()
            }
                    withAnimation {
                trackUserLocation.toggle()
            }
        }) {
            AppleMapControl(
                symbol: trackUserLocation ? "location.fill" : "location",
                backgroundColor: trackUserLocation ? .regularMaterial : .ultraThinMaterial,
                foregroundColor: trackUserLocation ? .blue : .primary
            )
        }
    }
    
    private func makeAnalyticsButton() -> some View {
        Button(action: {
            withAnimation {
                showDetailedAnalytics.toggle()
            }
        }) {
            AppleMapControl(
                symbol: showDetailedAnalytics ? "chart.bar.fill" : "chart.bar",
                backgroundColor: showDetailedAnalytics ? .regularMaterial : .ultraThinMaterial,
                foregroundColor: showDetailedAnalytics ? .blue : .primary
            )
        }
    }
    
    private func makeCompassButton() -> some View {
        Button(action: {
            // Reset map orientation to North
            withAnimation {
                // Reset camera orientation
                if let mapView = findMapView() {
                    let camera = mapView.camera
                    camera.heading = 0
                    mapView.setCamera(camera, animated: true)
                }
            }
        }) {
            AppleMapControl(
                symbol: "safari",
                backgroundColor: .ultraThinMaterial,
                foregroundColor: .primary
            )
        }
    }
    
    private func makeBottomControls() -> some View {
            VStack {
            Spacer()
            
            if isAssignedTrip {
                    HStack {
                    Spacer()
                    
                    // Apple Maps Style Bottom Control Bar
                    HStack(spacing: 15) {
                        // Vehicle Tracking Button
                        makeVehicleTrackingButton()
                        
                        // Show All Routes Button
                        makeAllRoutesButton()
                        
                        // Optimize Route Button
                        makeOptimizeButton()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Material.regularMaterial)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func makeVehicleTrackingButton() -> some View {
                    Button(action: {
            if let trip = selectedTrip ?? trips.first, let vehicleId = trip.vehicleId {
                locationManager.startTrackingVehicles(vehicleIds: [vehicleId])
                trackUserLocation = true
            }
        }) {
            AppleMapBottomButton(
                title: isHindiMode ? "गाड़ी का पता लगाएं" : "Track Vehicle",
                symbol: "location.fill"
            )
        }
    }
    
    private func makeAllRoutesButton() -> some View {
                            Button(action: {
                                withAnimation {
                showAllRoutes.toggle()
            }
        }) {
            AppleMapBottomButton(
                title: isHindiMode ? "सभी मार्ग" : "All Routes",
                symbol: "map"
            )
        }
    }
    
    private func makeOptimizeButton() -> some View {
        Button(action: {
            refreshID = UUID()
            loadRoutes()
        }) {
            AppleMapBottomButton(
                title: isHindiMode ? "मार्ग अनुकूलित करें" : "Optimize",
                symbol: "arrow.triangle.swap"
            )
        }
    }
    
    private func makePlaceCardView(place: MKMapItem) -> some View {
        VStack {
            Spacer()
            
            PlaceCardView(place: place, onDismiss: { showPlaceCard = false })
                    .padding(.horizontal)
                .padding(.bottom, isAssignedTrip ? 200 : 16)
                .transition(.move(edge: .bottom))
        }
    }
    
    private func makeAnalyticsView() -> some View {
        VStack {
            Spacer()
            
            TripAnalyticsView(trips: trips.filter { $0.status == .ongoing })
                .frame(height: 200)
                        .padding(.horizontal)
                .padding(.bottom, isAssignedTrip ? 200 : 16)
                .transition(.move(edge: .bottom))
        }
    }
    
    private func loadRoutes() {
        for trip in trips {
            if routeOverlays[trip.id] == nil {
                calculateRouteForTrip(trip)
            }
        }
    }
    
    private func calculateRouteForTrip(_ trip: Trip) {
        locationManager.calculateRoute(from: trip.startLocation, to: trip.endLocation) { result in
            switch result {
            case .success(let route):
                DispatchQueue.main.async {
                    let routeInfo = TripRouteOverlay(
                        route: route, 
                        tripId: trip.id, 
                        status: trip.status
                    )
                    self.routeOverlays[trip.id] = routeInfo
                    
                    if self.routeOverlays.count == 1 || self.selectedTrip?.id == trip.id {
                        centerMapOnTrip(trip)
                    }
                }
            case .failure(let error):
                print("Failed to calculate route for trip \(trip.id): \(error.localizedDescription)")
            }
        }
    }
    
    private func centerMapOnTrip(_ trip: Trip) {
        if let routeOverlay = routeOverlays[trip.id] {
            let route = routeOverlay.route
            withAnimation {
                // Enhanced 3D camera positioning
                let rect = route.polyline.boundingMapRect
                let center = route.polyline.coordinate
                
                // First show the entire route
                self.region = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(
                        latitudeDelta: rect.height * 2.0,
                        longitudeDelta: rect.width * 2.0
                    )
                )
                
                // After 3 seconds, zoom in to the route
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.region = MKCoordinateRegion(
                            center: center,
                            span: MKCoordinateSpan(
                                latitudeDelta: rect.height * 1.2,
                                longitudeDelta: rect.width * 1.2
                            )
                        )
                    }
                }
            }
        } else {
            calculateRouteForTrip(trip)
        }
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            userLocationAuthorized = true
        default:
            userLocationAuthorized = false
        }
    }
    
    // Function to request Look Around scene
    private func requestLookAroundScene(for address: String) {
        // Check if Look Around is available on this iOS version
        guard #available(iOS 16.0, *) else {
            os_log("Look Around is only available on iOS 16 and later", log: .default, type: .info)
            return
        }
        
        // Convert address to coordinate
        locationManager.geocodeAddress(address) { result in
            switch result {
            case .success(let coordinate):
                // Request Look Around scene
                let lookAroundSceneRequest = MKLookAroundSceneRequest(coordinate: coordinate)
                
                // Using correct API syntax for iOS 16+
                if #available(iOS 16.0, *) {
                    // Modern API call with proper syntax and explicit types - no start() method exists
                    let lookAroundSceneRequest = MKLookAroundSceneRequest(coordinate: coordinate)
                    Task {
                        do {
                            let scene = try await lookAroundSceneRequest.scene
                            DispatchQueue.main.async {
                                self.lookAroundScene = scene
                            }
                        } catch {
                            print("Look Around scene error: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                print("Geocoding error: \(error.localizedDescription)")
            }
        }
    }
    
    // Reusable Apple Maps style UI components
    
    // Apple Maps Control Button
    struct AppleMapControl: View {
        let symbol: String
        let backgroundColor: Material
        let foregroundColor: Color
        
        var body: some View {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .padding(12)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                .foregroundColor(foregroundColor)
        }
    }
    
    // Apple Maps Bottom Button
    struct AppleMapBottomButton: View {
        let title: String
        let symbol: String
        
        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(minWidth: 60)
            .foregroundColor(.blue)
        }
    }
    
    // Helper function to find the MKMapView in the view hierarchy
    func findMapView() -> MKMapView? {
        // Find the UIWindow
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return nil
        }
        
        // Find the MKMapView
        return findMapView(in: rootVC.view)
    }
    
    private func findMapView(in view: UIView) -> MKMapView? {
        if let mapView = view as? MKMapView {
            return mapView
        }
        
        for subview in view.subviews {
            if let mapView = findMapView(in: subview) {
                return mapView
            }
        }
        
        return nil
    }
}

// Professional Map View Representable
struct ProMapViewRepresentable: UIViewRepresentable {
    let trips: [Trip]
    @Binding var selectedTrip: Trip?
    @Binding var region: MKCoordinateRegion
    @Binding var routeOverlays: [String: TripRouteOverlay]
    let locationManager: LocationManager
    let refreshID: UUID
    let isHindiMode: Bool
    let mapType: TripMapView.MapType
    let is3DMode: Bool
    let trackUserLocation: Bool
    let isAssignedTrip: Bool
    let showAllRoutes: Bool
    let highlightSelectedRoute: Bool
    let showLookAround: Bool
    let onPlaceSelected: (MKMapItem) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Set initial region
        mapView.region = region
        
        // Configure various map settings
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = true
        mapView.showsBuildings = true
        mapView.showsUserLocation = trackUserLocation
        
        // Enable point of interest
        let config = mapView.preferredConfiguration
        if let hybridConfig = config as? MKHybridMapConfiguration {
            hybridConfig.pointOfInterestFilter = .includingAll
            mapView.preferredConfiguration = hybridConfig
        }
        
        // Configure map type
        switch mapType {
        case .standard:
            mapView.preferredConfiguration = is3DMode ? 
                MKStandardMapConfiguration(elevationStyle: .realistic) : 
                MKStandardMapConfiguration()
        case .hybrid:
            let config = MKHybridMapConfiguration(elevationStyle: is3DMode ? .realistic : .flat)
            config.pointOfInterestFilter = .includingAll
            config.showsTraffic = true
            mapView.preferredConfiguration = config
        case .terrain:
            let config = MKHybridMapConfiguration(elevationStyle: .realistic)
            config.pointOfInterestFilter = .includingAll
            mapView.preferredConfiguration = config
        case .flyover:
            let config = MKHybridMapConfiguration(elevationStyle: .realistic)
            config.pointOfInterestFilter = .includingAll
            config.showsTraffic = true
            mapView.preferredConfiguration = config
        }
        
        // Configure 3D mode
        if is3DMode {
            let camera = MKMapCamera(
                lookingAtCenter: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
                fromDistance: 1000000,
                pitch: 65,
                heading: 45
            )
            mapView.camera = camera
        }
        
        // IMPORTANT: Disable auto-tracking to prevent auto-zooming
        // Instead of using follow mode, we'll manually update the center
        mapView.userTrackingMode = .none
        
        // Initialize search completer
        context.coordinator.initializeSearchCompleter()
        
        // Inside makeUIView function, add this after configuration setup
        if isAssignedTrip || showAllRoutes {
            // Start tracking all active vehicles
            let activeVehicleIds = trips.filter { $0.status == .ongoing }
                .compactMap { $0.vehicleId }
            
            if !activeVehicleIds.isEmpty {
                locationManager.startTrackingVehicles(vehicleIds: activeVehicleIds)
            }
            
            // Add vehicle annotations
            context.coordinator.addVehicleAnnotations(to: mapView)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Only update the map type and 3D mode if they change
        updateMapConfiguration(mapView)
        
        // Store the current user region if the user has moved the map
        if context.coordinator.userHasChangedRegion {
            // Don't change the region that the user has set
            // Just update annotations and overlays
            updateAnnotationsAndOverlays(mapView)
            return
        }
        
        // Check if the route overlays have changed
        let hasNewOverlays = context.coordinator.previousOverlaysCount != routeOverlays.count
        context.coordinator.previousOverlaysCount = routeOverlays.count
        
        // Only set region if we have a new selected trip, new overlays, or it's the initial setup
        if context.coordinator.initialSetupDone == false || 
           context.coordinator.previousSelectedTripId != selectedTrip?.id ||
           hasNewOverlays {
            
            context.coordinator.initialSetupDone = true
            context.coordinator.previousSelectedTripId = selectedTrip?.id
            
            // Set the region based on route if available
            if let trip = selectedTrip, let routeOverlay = routeOverlays[trip.id] {
                let routeBounds = routeOverlay.route.polyline.boundingMapRect
                mapView.setVisibleMapRect(
                    routeBounds.insetBy(dx: -routeBounds.width * 0.2, dy: -routeBounds.height * 0.2),
                    animated: true
                )
            } else if is3DMode {
                let camera = MKMapCamera(
                    lookingAtCenter: region.center,
                    fromDistance: Double(region.span.latitudeDelta * 111000),
                    pitch: 65,
                    heading: 45
                )
                mapView.setCamera(camera, animated: true)
            } else {
                mapView.setRegion(region, animated: true)
            }
        }
        
        updateAnnotationsAndOverlays(mapView)
        
        // Track user location without changing zoom if requested
        if trackUserLocation && mapView.userLocation.location != nil {
            // Instead of using built-in tracking (which auto-zooms),
            // we'll manually update the center if needed
            if !context.coordinator.userHasChangedRegion {
                let currentRegion = mapView.region
                let userLocation = mapView.userLocation.location!.coordinate
                
                // Create a new region with the same zoom level but centered on user
                let newRegion = MKCoordinateRegion(
                    center: userLocation,
                    span: currentRegion.span
                )
                
                // Only update if significantly different
                if abs(currentRegion.center.latitude - userLocation.latitude) > 0.001 ||
                   abs(currentRegion.center.longitude - userLocation.longitude) > 0.001 {
                    mapView.setRegion(newRegion, animated: true)
                }
            }
        }
    }
    
    // Helper to update annotations and overlays
    private func updateAnnotationsAndOverlays(_ mapView: MKMapView) {
        // Remove existing annotations and overlays
        let nonUserAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(nonUserAnnotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add annotations and route overlays for trips
        for trip in trips {
            addTripAnnotations(trip, to: mapView)
            
            if let routeOverlay = routeOverlays[trip.id] {
                mapView.addOverlay(routeOverlay.route.polyline, level: .aboveRoads)
            }
        }
        
        // Update vehicle annotations if tracking
        if isAssignedTrip || showAllRoutes {
            // Safely access the coordinator
            if let coordinator = mapView.delegate as? Coordinator {
                coordinator.addVehicleAnnotations(to: mapView)
            }
        }
    }
    
    // Helper to update map configuration if needed
    private func updateMapConfiguration(_ mapView: MKMapView) {
        // Update map type if needed
        switch mapType {
        case .standard:
            let newConfig = is3DMode ? 
                MKStandardMapConfiguration(elevationStyle: .realistic) : 
                MKStandardMapConfiguration()
            if !(mapView.preferredConfiguration is MKStandardMapConfiguration) {
                mapView.preferredConfiguration = newConfig
            }
        case .hybrid:
            let newConfig = MKHybridMapConfiguration(elevationStyle: is3DMode ? .realistic : .flat)
            newConfig.pointOfInterestFilter = .includingAll
            newConfig.showsTraffic = true
            if !(mapView.preferredConfiguration is MKHybridMapConfiguration) {
                mapView.preferredConfiguration = newConfig
            }
        case .terrain:
            let newConfig = MKHybridMapConfiguration(elevationStyle: .realistic)
            newConfig.pointOfInterestFilter = .includingAll
            if !(mapView.preferredConfiguration is MKHybridMapConfiguration) {
                mapView.preferredConfiguration = newConfig
            }
        case .flyover:
            let newConfig = MKHybridMapConfiguration(elevationStyle: .realistic)
            newConfig.pointOfInterestFilter = .includingAll
            newConfig.showsTraffic = true
            if !(mapView.preferredConfiguration is MKHybridMapConfiguration) {
                mapView.preferredConfiguration = newConfig
            }
        }
    }
    
    // Add missing methods for Trip annotations
    private func addTripAnnotations(_ trip: Trip, to mapView: MKMapView) {
        // Geocode start location
        locationManager.geocodeAddress(trip.startLocation) { result in
            if case .success(let startCoordinate) = result {
                let startAnnotation = ProTripPointAnnotation(
                    coordinate: startCoordinate,
                    title: isHindiMode ? "शुरुआत: \(trip.startLocation)" : "Start: \(trip.startLocation)",
                    subtitle: formatDateTime(trip.scheduledStartTime),
                    type: .start,
                    tripId: trip.id
                )
                
                DispatchQueue.main.async {
                    mapView.addAnnotation(startAnnotation)
                }
                
                // Geocode end location
                locationManager.geocodeAddress(trip.endLocation) { result in
                    if case .success(let endCoordinate) = result {
                        let endAnnotation = ProTripPointAnnotation(
                            coordinate: endCoordinate,
                            title: isHindiMode ? "समाप्ति: \(trip.endLocation)" : "End: \(trip.endLocation)",
                            subtitle: formatDateTime(trip.scheduledEndTime),
                            type: .end,
                            tripId: trip.id
                        )
                        
                        DispatchQueue.main.async {
                            mapView.addAnnotation(endAnnotation)
                            
                            // Add waypoints along the route if available
                            if let routeOverlay = routeOverlays[trip.id] {
                                addWaypointAnnotations(for: routeOverlay.route, trip: trip, to: mapView)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Add missing waypoint annotations method
    private func addWaypointAnnotations(for route: MKRoute, trip: Trip, to mapView: MKMapView) {
        // Add waypoint annotations at key points along the route
        if route.steps.count > 2 {
            // Skip first and last step (departure and arrival)
            let keySteps = route.steps.dropFirst().dropLast()
            
            // Add annotations for major turns or maneuvers
            for (index, step) in keySteps.enumerated() {
                if step.distance > 1000 || isSignificantManeuver(step.instructions) {
                    let annotation = ProWaypointAnnotation(
                        coordinate: step.polyline.coordinate,
                        title: step.instructions,
                        subtitle: "\(formatDistance(step.distance))",
                        index: index,
                        tripId: trip.id
                    )
                    mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    // Helper for significant maneuvers
    private func isSignificantManeuver(_ instructions: String) -> Bool {
        // Check if the instruction contains keywords indicating major maneuvers
        let significantTerms = ["turn", "exit", "merge", "highway", "freeway", "roundabout", "u-turn"]
        return significantTerms.contains { instructions.lowercased().contains($0) }
    }
    
    // Format distance helper
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return "\(Int(meters)) m"
        }
    }
    
    // Required by UIViewRepresentable - creates Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, MKLocalSearchCompleterDelegate {
        var parent: ProMapViewRepresentable
        // Store animation timers
        private var animationTimers: [String: Timer] = [:]
        // Search related properties
        private var searchCompleter = MKLocalSearchCompleter()
        private var searchResults: [MKLocalSearchCompletion] = []
        
        // Track map state to prevent unnecessary updates
        var userHasChangedRegion: Bool = false
        var initialSetupDone: Bool = false
        var previousSelectedTripId: String? = nil
        var previousOverlaysCount: Int = 0
        
        init(_ parent: ProMapViewRepresentable) {
            self.parent = parent
            super.init()
        }
        
        // Clean up timers when the coordinator is deinitialized
        deinit {
            for timer in animationTimers.values {
                timer.invalidate()
            }
            animationTimers.removeAll()
        }
        
        // Initialize search completer
        func initializeSearchCompleter() {
            searchCompleter.delegate = self
            searchCompleter.resultTypes = .pointOfInterest
            searchCompleter.pointOfInterestFilter = .excludingAll
        }
        
        // Helper function to add vehicle annotations
        func addVehicleAnnotations(to mapView: MKMapView) {
            // Clear existing vehicle annotations
            let existingVehicleAnnotations = mapView.annotations.filter { $0 is VehicleAnnotation }
            mapView.removeAnnotations(existingVehicleAnnotations)
            
            // Add vehicle annotations for each active trip
            for trip in parent.trips.filter({ $0.status == .ongoing && $0.vehicleId != nil }) {
                if let vehicleId = trip.vehicleId,
                   let vehicleLocationInfo = parent.locationManager.vehicleLocations[vehicleId] {
                    let annotation = VehicleAnnotation(
                        coordinate: vehicleLocationInfo.coordinate,
                        title: "Vehicle \(vehicleId)",
                        vehicleId: vehicleId,
                        tripId: trip.id,
                        heading: vehicleLocationInfo.heading
                    )
                    mapView.addAnnotation(annotation)
                }
            }
        }
        
        // MARK: - MKMapViewDelegate Methods
        
        // Track when user manually changes the map region
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Detect if this is a user-initiated change
            if let view = mapView.subviews.first,
               let gestureRecognizers = view.gestureRecognizers {
                for recognizer in gestureRecognizers {
                    if recognizer.state == .began || recognizer.state == .changed {
                        userHasChangedRegion = true
                        break
                    }
                }
            }
        }
        
        // Update the bound region with the user's chosen region
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if userHasChangedRegion {
                // Update the bound region when user finishes moving the map
                parent.region = mapView.region
            }
        }
        
        // MKMapViewDelegate methods for annotation views
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            // Handle trip point annotations
            if let tripAnnotation = annotation as? ProTripPointAnnotation {
                return configureTripPointAnnotationView(for: tripAnnotation, in: mapView)
            }
            
            // Handle waypoint annotations
            if let waypointAnnotation = annotation as? ProWaypointAnnotation {
                return configureWaypointAnnotationView(for: waypointAnnotation, in: mapView)
            }
            
            // Handle vehicle annotations
            if let vehicleAnnotation = annotation as? VehicleAnnotation {
                let identifier = "VehicleAnnotation"
                
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKAnnotationView
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: vehicleAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    
                    // Add info button to callout
                    let infoButton = UIButton(type: .detailDisclosure)
                    infoButton.tintColor = .systemBlue
                    annotationView?.rightCalloutAccessoryView = infoButton
                    
                    // Add route tracking button 
                    let trackButton = UIButton(type: .system)
                    trackButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
                    trackButton.tintColor = .systemGreen
                    annotationView?.leftCalloutAccessoryView = trackButton
                } else {
                    annotationView?.annotation = vehicleAnnotation
                }
                
                // Set vehicle icon based on its heading
                let vehicleImage = UIImage(named: "car-top-view")?.withTintColor(.blue, renderingMode: .alwaysOriginal)
                    ?? UIImage(systemName: "car.fill")?.withTintColor(.blue, renderingMode: .alwaysOriginal)
                
                // Apply a shadow to make the vehicle stand out
                annotationView?.layer.shadowColor = UIColor.black.cgColor
                annotationView?.layer.shadowOpacity = 0.5
                annotationView?.layer.shadowOffset = CGSize(width: 0, height: 1)
                annotationView?.layer.shadowRadius = 2
                
                // Scale the image to appropriate size
                annotationView?.image = vehicleImage
                annotationView?.frame.size = CGSize(width: 32, height: 32)
                
                // Rotate to match heading
                annotationView?.transform = CGAffineTransform(rotationAngle: CGFloat(vehicleAnnotation.heading) * .pi / 180)
                
                return annotationView
            }
            
            // Handle points of interest when Look Around is enabled
            if parent.showLookAround, annotation.title != nil, #available(iOS 16.0, *) {
                let identifier = "POIAnnotation"
                
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    
                    // Add Look Around button to callout
                    let lookAroundButton = UIButton(type: .detailDisclosure)
                    lookAroundButton.setImage(UIImage(systemName: "binoculars"), for: .normal)
                    annotationView?.rightCalloutAccessoryView = lookAroundButton
                } else {
                    annotationView?.annotation = annotation
                }
                
                return annotationView
            }
            
            return nil
        }
        
        // Annotation view configuration methods
        private func configureTripPointAnnotationView(for annotation: ProTripPointAnnotation, in mapView: MKMapView) -> MKAnnotationView {
            let identifier = "TripPoint"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // Add button to show details
                let button = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = button
            } else {
                annotationView?.annotation = annotation
            }
            
            // Style based on type
            switch annotation.type {
            case .start:
                annotationView?.markerTintColor = .systemGreen
                annotationView?.glyphImage = UIImage(systemName: "flag.fill")
            case .end:
                annotationView?.markerTintColor = .systemRed
                annotationView?.glyphImage = UIImage(systemName: "flag.checkered")
            }
            
            // Highlight if selected
            if let selectedTrip = parent.selectedTrip, selectedTrip.id == annotation.tripId {
                annotationView?.markerTintColor = annotationView?.markerTintColor?.withAlphaComponent(1.0)
                annotationView?.glyphTintColor = .white
            } else {
                annotationView?.markerTintColor = annotationView?.markerTintColor?.withAlphaComponent(0.7)
            }
            
            return annotationView!
        }
        
        private func configureWaypointAnnotationView(for annotation: ProWaypointAnnotation, in mapView: MKMapView) -> MKAnnotationView {
            let identifier = "Waypoint"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Use a small dot for waypoints
            let dotImage = UIImage(systemName: "circle.fill")?
                .withTintColor(.blue.withAlphaComponent(0.7), renderingMode: .alwaysOriginal)
            annotationView?.image = dotImage
            annotationView?.frame.size = CGSize(width: 10, height: 10)
            
            return annotationView!
        }
        
        // Handle callout button taps
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let vehicleAnnotation = view.annotation as? VehicleAnnotation {
                if control == view.rightCalloutAccessoryView {
                    // Info button - show details
                    if let trip = parent.trips.first(where: { $0.id == vehicleAnnotation.tripId }) {
                        parent.selectedTrip = trip
                    }
                } else if control == view.leftCalloutAccessoryView {
                    // Track button - center on vehicle
                    if let coordinate = view.annotation?.coordinate {
                        let region = MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                        mapView.setRegion(region, animated: true)
                        
                        // Enable tracking for this vehicle
                        if let vehicleID = (view.annotation as? VehicleAnnotation)?.vehicleId {
                            parent.locationManager.startTrackingVehicles(vehicleIds: [vehicleID])
                        }
                    }
                }
            }
        }
        
        // Overlay renderer
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                // Find the trip associated with this polyline
                if let trip = findTripForOverlay(overlay) {
                    // Create a special premium gradient renderer with enhanced visual effects
                    let gradientRenderer = MKGradientPolylineRenderer(overlay: overlay)
                    
                    // Special rendering for assigned routes
                    if parent.isAssignedTrip, let selectedTripId = parent.selectedTrip?.id, trip.id == selectedTripId {
                        // Premium Apple Maps inspired style with vibrant gradient
                        gradientRenderer.setColors([
                            UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0),   // Bright blue
                            UIColor(red: 0.0, green: 0.7, blue: 0.9, alpha: 1.0),   // Sky blue
                            UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0),   // Turquoise
                            UIColor(red: 0.0, green: 0.7, blue: 0.9, alpha: 1.0),   // Sky blue
                            UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0)    // Bright blue
                        ], locations: [0.0, 0.25, 0.5, 0.75, 1.0])
                        
                        // Enhanced line styling
                        gradientRenderer.lineWidth = 10
                        gradientRenderer.lineCap = .round
                        gradientRenderer.lineJoin = .round
                        
                        // Premium glow effect
                        gradientRenderer.strokeColor = UIColor.white.withAlphaComponent(0.5)
                        
                        // Create pulsing effect timer with premium animation
                        let polylineID = "assigned-\(selectedTripId)"
                        if animationTimers[polylineID] == nil {
                            animationTimers[polylineID] = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self, weak gradientRenderer, weak mapView] _ in
                                guard let renderer = gradientRenderer, let mapView = mapView else { return }
                                
                                // Elegant pulsing animation with smooth transitions
                                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut) {
                                    if renderer.lineWidth == 10 {
                                        // Expanded state
                                        renderer.lineWidth = 12
                                        renderer.strokeColor = UIColor.white.withAlphaComponent(0.6)
                                        // Enhanced colors during pulse
                                        renderer.setColors([
                                            UIColor(red: 0.1, green: 0.7, blue: 1.0, alpha: 1.0),   // Brighter blue
                                            UIColor(red: 0.1, green: 0.8, blue: 0.9, alpha: 1.0),   // Brighter sky
                                            UIColor(red: 0.1, green: 0.9, blue: 0.8, alpha: 1.0),   // Brighter turquoise
                                            UIColor(red: 0.1, green: 0.8, blue: 0.9, alpha: 1.0),   // Brighter sky
                                            UIColor(red: 0.1, green: 0.7, blue: 1.0, alpha: 1.0)    // Brighter blue
                                        ], locations: [0.0, 0.25, 0.5, 0.75, 1.0])
                                    } else {
                                        // Contracted state
                                        renderer.lineWidth = 10
                                        renderer.strokeColor = UIColor.white.withAlphaComponent(0.5)
                                        // Original colors
                                        renderer.setColors([
                                            UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0),
                                            UIColor(red: 0.0, green: 0.7, blue: 0.9, alpha: 1.0),
                                            UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0),
                                            UIColor(red: 0.0, green: 0.7, blue: 0.9, alpha: 1.0),
                                            UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0)
                                        ], locations: [0.0, 0.25, 0.5, 0.75, 1.0])
                                    }
                                    
                                    // Smooth redraw
                                    mapView.setNeedsDisplay()
                                }
                            }
                        }
                        
                        return gradientRenderer
                    }
                    // If highlighting selected route but not assigned - premium style with different color scheme
                    else if parent.highlightSelectedRoute, let selectedTripId = parent.selectedTrip?.id, trip.id == selectedTripId {
                        // Premium google-maps inspired gradient for selected routes
                        switch trip.status {
                        case .scheduled:
                            // Deep blue to light blue gradient for scheduled trips
                            gradientRenderer.setColors([
                                UIColor(red: 0.1, green: 0.3, blue: 0.9, alpha: 0.9),  // Deep blue
                                UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.9),  // Medium blue
                                UIColor(red: 0.1, green: 0.3, blue: 0.9, alpha: 0.9)   // Deep blue
                            ], locations: [0.0, 0.5, 1.0])
                            
                        case .ongoing:
                            // Orange to yellow gradient for in-progress trips - vibrant
                            gradientRenderer.setColors([
                                UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9),  // Deep orange
                                UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.9),  // Yellow-orange
                                UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9)   // Deep orange
                            ], locations: [0.0, 0.5, 1.0])
                            
                            // Add animated pulsing for in-progress routes
                            let polylineID = "selected-\(selectedTripId)"
                            if animationTimers[polylineID] == nil {
                                animationTimers[polylineID] = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self, weak gradientRenderer, weak mapView] _ in
                                    guard let renderer = gradientRenderer, let mapView = mapView else { return }
                                    
                                    UIView.animate(withDuration: 0.75, delay: 0, options: .curveEaseInOut) {
                                        if renderer.lineWidth == 8 {
                                            // Expanded state - more vibrant
                                            renderer.lineWidth = 10
                                            renderer.strokeColor = UIColor.white.withAlphaComponent(0.5)
                                            // Brighter orange-yellow during pulse
                                            renderer.setColors([
                                                UIColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 0.9),
                                                UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.9),
                                                UIColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 0.9)
                                            ], locations: [0.0, 0.5, 1.0])
                                        } else {
                                            // Contracted state
                                            renderer.lineWidth = 8
                                            renderer.strokeColor = UIColor.white.withAlphaComponent(0.4)
                                            // Normal orange-yellow
                                            renderer.setColors([
                                                UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9),
                                                UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.9),
                                                UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9)
                                            ], locations: [0.0, 0.5, 1.0])
                                        }
                                        
                                        mapView.setNeedsDisplay()
                                    }
                                }
                            }
                            
                        case .completed:
                            // Green gradient for completed trips
                            gradientRenderer.setColors([
                                UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 0.9),  // Deep green
                                UIColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.9),  // Light green
                                UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 0.9)   // Deep green
                            ], locations: [0.0, 0.5, 1.0])
                            
                        case .cancelled:
                            // Red gradient for cancelled trips
                            gradientRenderer.setColors([
                                UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 0.8),  // Dark red
                                UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.8),  // Light red
                                UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 0.8)   // Dark red
                            ], locations: [0.0, 0.5, 1.0])
                        }
                        
                        // Premium line styling for all selected routes
                        gradientRenderer.lineWidth = 8
                        gradientRenderer.lineCap = .round
                        gradientRenderer.lineJoin = .round
                        
                        // Enhanced glow effect
                        gradientRenderer.strokeColor = UIColor.white.withAlphaComponent(0.4)
                        
                        return gradientRenderer
                    }
                    // Standard routes with enhanced styling based on status
                    else {
                        // Default enhancement for non-selected routes
                        var baseColor: UIColor
                        var pulseColor: UIColor
                        
                        switch trip.status {
                        case .scheduled:
                            baseColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.7)
                            pulseColor = UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.7)
                        case .ongoing:
                            baseColor = UIColor(red: 0.9, green: 0.5, blue: 0.0, alpha: 0.7)
                            pulseColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.7)
                        case .completed:
                            baseColor = UIColor(red: 0.0, green: 0.6, blue: 0.2, alpha: 0.7)
                            pulseColor = UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 0.7)
                        case .cancelled:
                            baseColor = UIColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 0.6)
                            pulseColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 0.6)
                        }
                        
                        // Create a more subtle gradient for non-selected routes
                        gradientRenderer.setColors([
                            baseColor,
                            pulseColor,
                            baseColor
                        ], locations: [0.0, 0.5, 1.0])
                        
                        // Slimmer line for non-selected routes
                        gradientRenderer.lineWidth = 5
                        gradientRenderer.lineCap = .round
                        gradientRenderer.lineJoin = .round
                        
                        // Light glow effect
                        gradientRenderer.strokeColor = UIColor.white.withAlphaComponent(0.3)
                        
                        return gradientRenderer
                    }
                }
                
                // Fallback renderer for polylines without associated trips
                let renderer = MKPolylineRenderer(overlay: polyline)
                
                if polyline.title == "History Trail" {
                    renderer.strokeColor = UIColor(Color.gray.opacity(0.6))
                    renderer.lineWidth = 3
                    renderer.lineDashPattern = [2, 5]
                } else {
                    renderer.strokeColor = UIColor(Color.blue.opacity(0.7))
                renderer.lineWidth = 5
                    renderer.lineCap = .round
                    renderer.lineJoin = .round
                }
                
                return renderer
            }
            
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(overlay: circle)
                
                if circle.title == "Start" {
                    renderer.fillColor = UIColor(Color.green.opacity(0.7))
                    renderer.strokeColor = UIColor(Color.green)
                } else if circle.title == "End" {
                    renderer.fillColor = UIColor(Color.red.opacity(0.7))
                    renderer.strokeColor = UIColor(Color.red)
                } else {
                    renderer.fillColor = UIColor(Color.blue.opacity(0.3))
                    renderer.strokeColor = UIColor(Color.blue)
                }
                
                renderer.lineWidth = 2
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // Find the trip associated with an overlay
        private func findTripForOverlay(_ overlay: MKOverlay) -> Trip? {
            for (tripId, routeOverlay) in parent.routeOverlays {
                if overlay === routeOverlay.route.polyline {
                    return parent.trips.first(where: { $0.id == tripId })
                }
            }
            return nil
        }
        
        // MARK: - MKLocalSearchCompleterDelegate
        
        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            searchResults = completer.results
            
            // If places of interest found and Look Around is enabled, show them on the map
            if !searchResults.isEmpty, parent.showLookAround, #available(iOS 16.0, *) {
                // Select the first result to show its place card
                if let firstResult = searchResults.first {
                    let searchRequest = MKLocalSearch.Request(completion: firstResult)
                    let search = MKLocalSearch(request: searchRequest)
                    
                    search.start { [weak self] (response, error) in
                        guard let self = self, let response = response else { return }
                        
                        if let mapItem = response.mapItems.first {
                            // Pass the found place to parent
                            DispatchQueue.main.async {
                                self.parent.onPlaceSelected(mapItem)
                            }
                        }
                    }
                }
            }
        }
        
        func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
            print("Search completer error: \(error.localizedDescription)")
        }
        
        // Function to pulse polyline for selected route
        func pulsePolyline(polylineID: String, renderer: MKGradientPolylineRenderer, mapView: MKMapView) {
            // Toggle between two styles for pulsing effect
            if renderer.lineWidth == 8 {
                renderer.lineWidth = 10
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.4)
            } else {
                renderer.lineWidth = 8
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.3)
            }
            
            // Refresh the map view to show the change
            mapView.setNeedsDisplay()
        }
    }
}

// Professional Annotation Classes
class ProTripPointAnnotation: MKPointAnnotation {
    enum PointType {
        case start, end
    }
    
    let type: PointType
    let tripId: String
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, type: PointType, tripId: String) {
        self.type = type
        self.tripId = tripId
        super.init()
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

class ProWaypointAnnotation: MKPointAnnotation {
    let index: Int
    let tripId: String
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, index: Int, tripId: String) {
        self.index = index
        self.tripId = tripId
        super.init()
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

// Helper for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Other helper functions and structures remain the same
struct TripRouteOverlay {
    let route: MKRoute
    let tripId: String
    let status: TripStatus
}

// Helper function to format date and time
func formatDateTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

func formatDuration(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes) min"
    }
}

func statusColor(for status: TripStatus) -> Color {
    switch status {
    case .scheduled:
        return .blue
    case .ongoing:
        return .orange
    case .completed:
        return .green
    case .cancelled:
        return .red
    }
}

// Helper function for Hindi status
func statusInHindi(for status: TripStatus) -> String {
    switch status {
    case .scheduled:
        return "अनुसूचित"
    case .ongoing:
        return "प्रगति में"
    case .completed:
        return "पूर्ण"
    case .cancelled:
        return "रद्द"
    }
}

// Add this class at the end of the file, outside of the TripMapView struct
class VehicleAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    let vehicleId: String
    let tripId: String
    var heading: Double
    
    init(coordinate: CLLocationCoordinate2D, title: String, vehicleId: String, tripId: String, heading: Double) {
        self.coordinate = coordinate
        self.title = title
        self.vehicleId = vehicleId
        self.tripId = tripId
        self.heading = heading
        super.init()
    }
}

// Apple-style place card view
struct PlaceCardView: View {
    let place: MKMapItem
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with place name and close button
            HStack {
                Text(place.name ?? "Location")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            // Address
            if let address = place.placemark.thoroughfare {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    Text(address)
                        .font(.subheadline)
                }
            }
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {}) {
                    VStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                        Text("Directions")
                            .font(.caption)
                    }
                }
                
                Button(action: {}) {
                    VStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                        Text("Info")
                            .font(.caption)
                    }
                }
                
                Button(action: {}) {
                    VStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                        Text("Save")
                            .font(.caption)
                    }
                }
                
                Button(action: {}) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                        Text("Share")
                            .font(.caption)
                    }
                }
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Material.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

// Advanced analytics view
struct TripAnalyticsView: View {
    let trips: [Trip]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fleet Analytics")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(trips.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Active trips")
                        .font(.caption)
                }
                
                VStack {
                    Text(String(format: "%.1f", calculateAverageDelay()))
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Avg delay (min)")
                        .font(.caption)
                }
                
                VStack {
                    Text(String(format: "%.1f", calculateFuelEfficiency()))
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Fuel (km/l)")
                        .font(.caption)
                }
                
                VStack {
                    Text("\(onTimeDeliveryPercentage())%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("On time")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            
            if !trips.isEmpty {
                VStack(alignment: .leading) {
                    Text("Efficiency Tips")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top, 4)
                    
                    Text("Optimize routes during off-peak hours for 12% fuel savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Material.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    // Sample analytics calculations
    private func calculateAverageDelay() -> Double {
        return trips.isEmpty ? 0.0 : 5.3 // Simulated value
    }
    
    private func calculateFuelEfficiency() -> Double {
        return trips.isEmpty ? 0.0 : 12.8 // Simulated value
    }
    
    private func onTimeDeliveryPercentage() -> Int {
        return trips.isEmpty ? 0 : 94 // Simulated value
    }
}

// Look Around Preview for iOS 16+
@available(iOS 16.0, *)
struct LookAroundPreview: UIViewRepresentable {
    let initialScene: MKLookAroundScene
    
    func makeUIView(context: Context) -> UIView {
        if #available(iOS 16.0, *) {
            let view = CustomLookAroundView()
            view.scene = initialScene
            return view
        } else {
            // Fallback for compiler - this code won't actually run due to @available check
            let label = UILabel()
            label.text = "Look Around requires iOS 16+"
            return label
        }
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update scene if needed
        if #available(iOS 16.0, *), let lookAroundView = uiView as? CustomLookAroundView {
            lookAroundView.scene = initialScene
        }
    }
}

// Mock classes for earlier iOS versions
class MockMKLookAroundView: UIView {}

// Backward compatibility wrapper for older iOS
struct MockLookAroundPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let label = UILabel()
        label.text = "Look Around requires iOS 16+"
        label.textAlignment = .center
        return label
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Nothing to update
    }
}

// Fallback Look Around Preview for iOS versions before 16.0
struct LookAroundFallbackView: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        VStack(spacing: 12) {
            // Simple map view
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )), annotationItems: [MapLocation(coordinate: coordinate)]) { location in
                MapMarker(coordinate: location.coordinate, tint: .red)
            }
            .cornerRadius(12)
            
            Text("Look Around not available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Simple location struct for map annotation
    struct MapLocation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
}

#Preview {
    TripMapView(trips: [], locationManager: LocationManager())
} 
