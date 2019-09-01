//
//  DataViewController.swift
//  Ayero
//
//  Created by Yahor Paulikau on 9/23/16.
//  Copyright © 2017 One Car Per Green. All rights reserved.
//

import UIKit
import CoreMotion
import MapKit
import CoreLocation


// global constant
let penaltyMax: Double   = 1.2      // To set the panalty scale, use this as a top boundary


class DataViewController: UIViewController,
    CLLocationManagerDelegate,
    MKMapViewDelegate {

    var dataObject: String = ""
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var barChart: SimpleChart!
    @IBOutlet weak var btnStart: StartButton!
    @IBOutlet weak var btnLoadRoute: StartButton!
    
    
    // constants
    let distanceSnap: Double = 60.0     // Penalty discharge ditance, m
    let distanceDot: Double  = 10.0     // Interm dot interval, m
    
    let alpha: Double        = 0.5      // Low frequency filter (0.2)
    let accMA: Int           = 10       // Moving average   (10)
    let accInterval: Int     = 50       // Measurement interval, ms
    let gravityMA: Int       = 10       // Gravity sensor movig average, ms
    let gravityPeriod: Int   = 500      // MA for gravity, ms
    let uploadInterval       = 60.0     // upload data to server every uploadInterval seconds.

    
    // variables
    var centerTimer: Timer!
    var mManager: CMMotionManager!
    var locManager: CLLocationManager!
    var vehicleLocation: CLLocation!
    var prevLocation: CLLocation!
    var penaltyArray: [(time: NSDate, p: Double, a:Double, latitude: Double, longitude: Double, speed: Double)] = []
    var locationTimer: Int = 0
    var currentMeaUuid = UUID().uuidString
    var regionRadius: CLLocationDistance = 150
    var penaltySumTotal: Double = 0.0
    var timer: Timer = Timer()
    
    // minor trace on the map to be removed after new pinpoint has been set
    var ephemealDots: [MKOverlayRenderer] = []
    var isLocationUpdated: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = false
        mManager = CMMotionManager()
        locManager = CLLocationManager()
        locManager.allowsBackgroundLocationUpdates = true
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.pausesLocationUpdatesAutomatically = true
        checkLocationAuthorizationStatus()
        initLocationService(stop: true)
        barChart.backgroundColor = UIColor(white: 1, alpha: 0.75)
    }

    
    // Interface action methods
    
    @IBAction func loadRouteMap(_ sender: Any) {
        syncDocumentsToS3()
        
        // only "BAR" file can be used
        removeOverlays()
        let points = readFromFile(fileName: "2017-07-09-15-10-54-bar.txt")
        displayRoute(pointsArray: points)
        
        /*for item in points {
            let loc = CLLocation(latitude: item.lat, longitude: item.long)
            //updateLocation(loc: loc)

            //DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10), execute: {
                self.updateLocation(loc: loc)
            //})
            centerMapOnLocation(location: self.vehicleLocation)

            usleep(60)
            
        }*/
    }
    
    
    @IBAction func routeStart(_ sender: Any) {
        if btnStart.isStarted {
            btnStart.isStarted = false
            btnStart.setTitle("Start",for: .normal)
            stopMeasurement()
        } else {
            btnStart.isStarted = true
            btnStart.setTitle("Stop",for: .normal)
            startMeasurement()
        }
        btnStart.setNeedsDisplay()
    }
    
    
    func initLocationService(stop: Bool) {
        locManager.startUpdatingLocation()
        
        DispatchQueue.global(qos: .background).async {
            while (!self.isLocationUpdated) {
                usleep(10)
            }
            
            DispatchQueue.main.async {
                self.centerMapOnCurrentLocation(true)
                if stop {
                    self.locManager.stopUpdatingLocation()
                }
            }
        }
    }

    
    func centerMapOnCurrentLocation(_ now: Bool) {
        if vehicleLocation != nil && (locationTimer == 0 || now){
            centerMapOnLocation(location: self.vehicleLocation)
        }
    }
    

    func centerMapOnLocation(location: CLLocation) {
        //var prevSpeed: CLLocationSpeed = vehicleSpeed
        //if prevLocation != nil {
        //    prevSpeed = prevLocation.speed
        //}
        
        let radius = regionRadius
        //let speed = vehicleSpeed==0 ? 0.001 : vehicleSpeed
        
        /*if abs(prevSpeed - speed)/speed > 0.2 {
            let mph = 2.23694 * speed
            if (mph <= 25) {
                radius = 150
            } else if mph > 25 && mph <= 50 {
                radius = 250
            } else {
                radius = 400
            }
        }*/
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  radius * 2, radius * 2)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    

    func stopMeasurement() {
        mManager.stopDeviceMotionUpdates()
        locManager.stopUpdatingLocation()
        locationTimer = 0
        timer.invalidate()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    @objc func upload2s3 () {
        syncDocumentsToS3()
    }
    
    func startMeasurement() {
        if vehicleLocation==nil {
            print("Can't get device location, stopping measurement.")
            return
        }

        timer = Timer.scheduledTimer(timeInterval: uploadInterval, target: self, selector: (#selector(self.upload2s3)), userInfo: nil, repeats: true)
        timer.tolerance = uploadInterval * 0.1

        let updateInterval: TimeInterval = TimeInterval(Double(self.accInterval) / 1000)
        let gravityTicks =  self.gravityPeriod / self.accInterval
        let sGravity = GravitySensor(ticks: gravityTicks)
        let sAccel = AccelerometerWrapper(alpha: self.alpha, accMA: accMA)
        let dToday = LogDateFormatter("y-MM-dd-H-m-ss-SSSS").getDateFormat(Date())
        let logFileName = userIdentifier + "-" + dToday + "-log.txt"
        let barFileName = userIdentifier + "-" + dToday + "-bar.txt"
        let rawFileName = userIdentifier + "-" + dToday + "-raw.txt"

        let dFormatter = LogDateFormatter("y-MM-dd H:m:ss.SSSS")

        
        // log processing variables
        var ticks = 1
        var grVector: XyzVector = (0.0, 0.0, 0.0)
        var penaltySumBrake: Double = 0.0
        var penaltySumAccel: Double = 0.0
        var speedSum: Double = 0.0
        var rawLog = "time, AccX, AccY, AccZ, GrX, GrY, GrZ, GyroX, GyroY, GyroZ, MagX, MagY, MagZ"
        var trackingText = "time, vCorr, penaltySumTotal, accX, accY, accZ, dX, dY, dZ, rX, rY, rZ, latitude, longitude, speed"

        // Initialize penalty accumulator
        penaltySumTotal = 0.0
        
        mManager.startDeviceMotionUpdates()
        initLocationService(stop: false)
        
        removeOverlays()
        removeEphemeralDots()
        
        // register initial route point
        self.penaltyArray.append((Date() as NSDate, 0, 0,
                                  vehicleLocation.coordinate.latitude,
                                  vehicleLocation.coordinate.longitude,
                                  vehicleLocation.speed))

        prevLocation = self.vehicleLocation
        var prevMiniLoc: CLLocation = self.vehicleLocation
        
        if !mManager.isDeviceMotionAvailable {
            print("Device motion is not available, process halted.")
            return
        }
        
        mManager.deviceMotionUpdateInterval = updateInterval
        mManager.startDeviceMotionUpdates(to: OperationQueue()) { data, error in
            guard data != nil else {
                print("There was an error: \(String(describing: error))")
                return
            }

            let gravity = data?.gravity
            if gravity != nil {
                DispatchQueue.main.async {
                    grVector = sGravity.getData(gravity!)
                }
            }
            
            let rotation = data?.rotationRate
            let magneticfield = data?.magneticField.field
            
            if let acceleration = data?.userAcceleration {
                DispatchQueue.main.async {
                    let (v_corr, delta) = sAccel.getData(acceleration, gravityCorrection: grVector)
                    
                    self.penaltySumTotal += abs(v_corr)
                    if v_corr > 0 { penaltySumBrake += abs(v_corr) } else { penaltySumAccel += abs(v_corr) }
                    
                    speedSum += self.vehicleLocation.speed

                    
                    // write raw data
                    let sRaw = String(format: "%@s,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f", dFormatter.getDateFormat(Date()), acceleration.x, acceleration.y, acceleration.z,
                                      gravity!.x, gravity!.y, gravity!.z,
                                      rotation!.x, rotation!.y, rotation!.z,
                                      magneticfield!.x, magneticfield!.y, magneticfield!.z)
                    rawLog = "\(rawLog)\n\(sRaw)"
                    
                    
                    
                    // write values to the file on every measurement
                    let sLog = String(format: "%@s,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.04f,%.012f,%.012f,%.04f",
                                      dFormatter.getDateFormat(Date()), v_corr,
                                      self.penaltySumTotal,
                                      acceleration.x, acceleration.y, acceleration.y,
                                      delta.x, delta.y, delta.z,
                                      grVector.x, grVector.y, grVector.z,
                                      self.vehicleLocation.coordinate.latitude,
                                      self.vehicleLocation.coordinate.longitude,
                                      self.vehicleLocation.speed)
                    trackingText = "\(trackingText)\n\(sLog)"
                    ticks += 1
                    
                    
                    // mini dots
                    let mdistance = prevMiniLoc.distance(from: self.vehicleLocation)
                    if Double(mdistance) > self.distanceDot {
                        self.displayMiniDot(self.penaltySumTotal,
                                       self.vehicleLocation.coordinate.latitude,
                                       self.vehicleLocation.coordinate.longitude,
                                       routeDot.temporary)
                        prevMiniLoc = self.vehicleLocation
                    }
                    


                    // Add major point every 'distanceSnap' meters
                    let distance = self.prevLocation.distance(from: self.vehicleLocation)
                    if Double(distance) > self.distanceSnap {
                        self.prevLocation = self.vehicleLocation

                        // display bar on the bar chart. 
                        self.barChart.addBar(p: (penaltySumAccel, penaltySumBrake))

                        // Adding log record to penalty file
                        let time = Date() as NSDate
                        let lat = self.vehicleLocation.coordinate.latitude
                        let long = self.vehicleLocation.coordinate.longitude
                        let speedAvg = speedSum / Double(ticks)
                        self.penaltyArray.append((time, self.penaltySumTotal, penaltySumAccel, lat, long, speedAvg))
                        
                        // register new point in the route
                        self.displayMiniDot(self.penaltySumTotal, lat, long, routeDot.regular)

                        let sPen = String(format: "%@s,%.04f,%.012f,%.012f,%.012f", time, self.penaltySumTotal, lat, long, self.vehicleLocation.speed)
                        
                        // log to file
                        writeToFile(content: sPen, fileName: barFileName)
                        writeToFile(content: trackingText, fileName: logFileName)
                        writeToFile(content: rawLog, fileName: rawFileName)
                        rawLog = ""

                        self.penaltySumTotal = 0.0
                        penaltySumAccel = 0.0
                        penaltySumBrake = 0.0
                        speedSum = 0.0
                        ticks = 1
                        trackingText = ""

                        self.removeEphemeralDots()
                        self.centerMapOnCurrentLocation(false)
                    }
                }
            }
        }

        // don't let the system fall asleep while we tracking route.
        UIApplication.shared.isIdleTimerDisabled = true
    }



    // ---------------------- MapView ------------------- //
    
    func penaltyToRadius(_ penalty: Double) -> CLLocationDistance {
        return min(penalty * (9 / penaltyMax) + 5, 10);
    }
    
    
    // Displays temporary dot on the map
    func displayMiniDot(_ penalty:Double, _ lat:Double, _ long:Double, _ selector:routeDot) {
        let x = CLLocationDegrees(lat)
        let y = CLLocationDegrees(long)
        let r = penaltyToRadius(penalty)
        let circle = ColorCicrle(center: CLLocationCoordinate2DMake(x, y), radius: r)
        circle.color = mapColor2Penalty(penalty: penalty, penaltyMax: penaltyMax)
        circle.dotSelector = selector
        self.mapView.add(circle)
        self.mapView.renderer(for: circle)?.setNeedsDisplay()
    }
    
    
    // Displays route on the map and centers it to the starting pount. Array can have just Two points. 
    func displayRoute(pointsArray: [(penalty:Double, lat:Double, long:Double, speed:Double)]) {
        for item in pointsArray  {
            displayMiniDot(item.penalty, item.lat, item.long, routeDot.regular)
        }
    }

    
    func removeOverlays() {
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
    }
    
    func removeEphemeralDots() {
        var i: Int = 1
        for item in mapView.overlays.reversed() {
            if let circle = item as? ColorCicrle {
                if circle.dotSelector == routeDot.temporary {
                    self.mapView.remove(circle)
                    i = i + 1;
                    if (i >= 100) { break };
                }
            }
        }
        
    }

    // MKMapView delegate methods //
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is ColorPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            if let poly = overlay as? ColorPolyline {
                lineView.strokeColor = hexStringToUIColor(hex: poly.color!)
            }
            return lineView
        } else if overlay is ColorCicrle {
            let circleView = ColorCicrleRenderer(overlay: overlay)
            return circleView
        }
        
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        locationTimer = 1
        // Start center location timer
        centerTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(resetCenterTimerLocation), userInfo: nil, repeats: true)
    }
    
    public func mapViewDidFinishLoadingMap(_ mapView: MKMapView)
    {
        mapView.setUserTrackingMode(.none, animated: true)
    }
    
    

    // CLLocationManager delegate methods //
    
    func locationManager(_ manager:CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        updateLocation(loc: locations[locations.count - 1])
        self.isLocationUpdated = true
    }
    
    
    func updateLocation (loc: CLLocation) {
        vehicleLocation = loc
        
        // remove prev dot
        for item in mapView.overlays.reversed() {
            if let circle = item as? ColorCicrle {
                if circle.dotSelector == routeDot.cursor {
                    self.mapView.remove(circle)
                }
            }
        }
        
        self.displayMiniDot(penaltySumTotal,
                            self.vehicleLocation.coordinate.latitude,
                            self.vehicleLocation.coordinate.longitude,
                            routeDot.cursor)

    }
    
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            //mapView.showsUserLocation = true
        } else {
            locManager.requestWhenInUseAuthorization()
        }
        // to do: if user cancels authorization show statistics screen. 
    }
    
    
    func resetCenterTimerLocation() {
        locationTimer = 0
    }
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
}

