
import XCTest
//import XCPlayground
import Foundation

class HSS_UI_Swift: XCTestCase {
    
    let waitForPopup = 1 //in seconds. For now: 1, potentially could be increased to 7
    let loginElite = ''
    let passElite = ''
    let vls = ["Japan", "IN", "United States", "Great Britain", "AU", "CA", "CN", "CZ", "DE", "DK", "ES", "FR", "HK", "IE", "NL", "RU", "SE", "TR", "UA", "MX"]
    let app = XCUIApplication()
    let connection = XCUIApplication().menuBarItems["Connection"]
    let virtualLocation = XCUIApplication().menuItems["Virtual Location"]
    let countries = XCUIApplication().menuBarItems["Connection"].menus.menuItems["Virtual Location"].menus
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        closePopupWindows()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        signOut()
        super.tearDown()
    }
    
    func test00_createAccount()
    {
        //given
        signOut()
        
        //when 1
        let random = arc4random()
        let email = "af_mac_auto_\(random)@gmail.com"
        let password = "Zk#\(random)"
        
        app.menuItems["My Account"].click()
        app.buttons["Sign In"].click()
        app.buttons["Sign Up Now!"].click()
        
        app.windows["MainWindow"].textFields["Email"].click()
        app.windows["MainWindow"].textFields["Email"].typeText(email)
        app.windows["MainWindow"].secureTextFields["Password"].click()
        app.windows["MainWindow"].secureTextFields["Password"].typeText(password)
        app.windows["MainWindow"].secureTextFields["Confirm Password"].click()
        app.windows["MainWindow"].secureTextFields["Confirm Password"].typeText(password)
        app.buttons["Create Account"].click()
        
        waitForActivityIndicatorToDisappear()
        
        //then 1
        closePopupWindows()
        app.menuItems["My Account"].click()
        let label = app.windows["MainWindow"].staticTexts[email]
        waitUntil(label.exists)
        XCTAssertTrue(label.exists, "The user was not able to create a new account")
        
        //when 2
        signIn(email, password: password)
        
        //then 2
        app.menuItems["My Account"].click()
        waitUntil(label.exists)
        XCTAssertTrue(label.exists, "The user was not able to login with a newly created account")
    }
    
    
    func test01_SignInAsElite() {
        //given
        
        //when
        signIn(loginElite, password: passElite)
        
        //then
        app.menuItems["My Account"].click()
        let label = app.windows["MainWindow"].staticTexts[loginElite]
        waitUntil(label.exists)
        XCTAssertTrue(label.exists, "The user was not able to login")
    }
    
    func test02_SignOut()
    {
        //given
        signIn(loginElite, password: passElite)
        
        //when
        signOut()
        
        //then
        XCTAssertTrue(app.windows["MainWindow"].staticTexts["-----"].exists, "The user was not able to sign out")
    }
    
    
    func test03_ConnectAsFree()
    {
        //given
        closePopupWindows()
        app.menuBars.menuItems["My Account"].click()
        
        for _ in 1...10
        {
            if app.windows["MainWindow"].buttons["Sign In"].exists
            {
                break
            }
            if app.windows["MainWindow"].buttons["Sign Out"].exists
            {
                signOut()
                break
            }
            sleep(1)
        }
        
        //when
        app.menuBars.menuItems["Connect"].click()
        closePopupWindows()
        app.menuBars.menuItems["Connection"].click()
        
        //then
        let label = app.windows["MainWindow"].staticTexts["Connected"]
        waitUntil(label.exists)
        XCTAssertTrue(label.exists, "Connection to the US server as a free user is not established")
    }
    
    func test04_VerifyDisconnect()
    {
        //given
        app.menuItems["Connect"].click()
        closePopupWindows()
        
        var label = app.windows["MainWindow"].staticTexts["Connected"]
        waitUntil(label.exists)
        XCTAssert(label.exists, "The connection was not established")
        
        //when
        app.menuItems["Disconnect"].click()
        
        //then
        label = app.windows["MainWindow"].staticTexts["Disconnected"]
        waitUntil(label.exists)
        XCTAssert(label.exists, "The 'disconnect' functionality didn't work")
    }
    
    func test05_Connect_US_Elite()
    {
        let vl = "United States"
        
        //given
        signIn(loginElite, password: passElite)
        
        //when
        connectTo(vl)
        
        //then
        app.menuItems["Connection"].click()
        let label = app.windows["MainWindow"].staticTexts["Connected"]
        waitUntil(label.exists)
        XCTAssert(label.exists, "The connection to \(vl) as an Elite user was not established")
    }
    
    func test06_FastVlSwitch()
    {
        //given
        signIn(loginElite, password: passElite)
        
        //when
        let vlsShuffled = vls.shuffle()
        app.menuBars.menuItems["Connect"].click()
        closePopupWindows()
        app.menuItems["Connection"].click()
        for vl in vlsShuffled
        {
            print ("VL: \(vl)")
            connection.click()
            virtualLocation.hover()
            for _ in 1...30
            {
                if countries.menuItems[vl].hittable {break}
                connection.click()
                virtualLocation.hover()
            }
            countries.menuItems[vl].click()
            //then
            for _ in 1...30
            {
                if XCUIApplication().windows["MainWindow"].staticTexts["Connected"].exists {break}
                sleep(1)
            }
            XCTAssert(XCUIApplication().windows["MainWindow"].staticTexts["Connected"].exists, "VL fast switch: the connection to \(vl) as an Elite was unsuccessful")
        }
    }
    
    func test07_ConnectDisconnectToVls()
    {
        //given
        signIn(loginElite, password: passElite)
        
        //when
        let vlsShuffled = vls.shuffle()
        app.menuItems["Connection"].click()
        for vl in vlsShuffled
        {
            connectTo(vl)
            //then
            for _ in 1...30
            {
                if XCUIApplication().windows["MainWindow"].staticTexts["Connected"].exists {break}
                sleep(1)
            }
            XCTAssert(app.windows["MainWindow"].staticTexts["Connected"].exists, "VL connect/disconnect: the connection to \(vl) as an Elite was unsuccessful")
            app.menuItems["Disconnect"].click()
        }
    }
    
    func testRequest() -> Void
    {
        let expectation = self.expectationWithDescription("Network Reqeust")
        let url = NSURL(string: "http://www.google.com")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) { (data, response, error) in
            print("RESPONSE")
            print(response)
            
            if(error == nil)
            {
                let responseDataString = String(data: data!, encoding: NSASCIIStringEncoding)
                print ("DATA")
                print(responseDataString)
            }
            
            expectation.fulfill()
        }
        task.resume()
        
        self.waitForExpectationsWithTimeout(10.0) { (error) in
            print("error waiting for expectation")
        }
    }
    
    func testTemp()
    {
        print(app.debugDescription)
        
    }
    
    func testPurchase()
    {
//        self.addUIInterruptionMonitorWithDescription(<#T##handlerDescription: String##String#>, handler: <#T##(XCUIElement) -> Bool#>)
        
        
        // Add handler
        // Push button that produces alert
        // app.tap() - for some reason in order to receive the event in the handler
    }
    
    func testNetwork()
    {
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let url = NSURL(string: "http://masilotti.com")!
        let task = session.dataTaskWithURL(url) { (data, _, _) -> Void in
            if let data = data {
                let string = String(data: data, encoding: NSUTF8StringEncoding)
                print("output:")
                print(string)
            }
        }
        task.resume()
    }
    
    func testAppleScript()
    {
        let task = NSTask()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["~/Desktop/testscript.scpt"]
        
        task.launch()
    }
    
    
    /* ------------------ Functions ------------------- */
    
    func closePopupWindows()
    {
        for _ in 1...waitForPopup
        {
            sleep(1)
            if app.windows["MainWindow"].sheets.staticTexts["Enjoy a free 7 day trial of Hotspot Shield!"].exists
            {
                app.windows["MainWindow"].sheets.buttons["Close"].click()
                break
            }
            
            if app.windows["MainWindow"].sheets.buttons["Skip"].exists
            {
                app.windows["MainWindow"].sheets.buttons["Skip"].click()
                break
            }
            
            
//            let mainwindowWindow = app.windows["MainWindow"]
//            mainwindowWindow.childrenMatchingType(.CheckBox).element.click()
//            mainwindowWindow.sheets.buttons["Skip"].click()
//            
//            
//            let checkBox = app.windows["MainWindow"].childrenMatchingType(.CheckBox).element
//            checkBox.click()
//            checkBox.click()
//            
//            
//            let mainwindowWindow = app.windows["MainWindow"]
//            mainwindowWindow.childrenMatchingType(.CheckBox).element.click()
//            mainwindowWindow.sheets.buttons["Yes, rate 5 stars"].click()
            
            
//            if app.windows["MainWindow"].sheets.staticTexts["Hotspot Shield would like to run a helper that will alert you wh"].exists
//            {
//                app.windows["MainWindow"].sheets.buttons["No Thanks"].click()
//                break
//            }
            
        }
    }
    
    func signIn(login: String, password: String)
    {
        app.menuBars.menuItems["My Account"].click()
        
        //The user is already signed in
        if app.windows["MainWindow"].buttons["Sign Out"].exists
        {
            if app.windows["MainWindow"].staticTexts[loginElite].exists {return}
            app.windows["MainWindow"].buttons["Sign Out"].click()
            
        }else //Otherwise click Sign-In button
        {
            app.windows["MainWindow"].buttons["Sign In"].click()
        }
        
        //Sign-In form submission
        app.windows["MainWindow"].textFields["Email or Username"].click()
        app.windows["MainWindow"].textFields["Email or Username"].typeText(login)
        app.windows["MainWindow"].secureTextFields["Password"].click()
        app.windows["MainWindow"].secureTextFields["Password"].typeText(password)
        app.windows["MainWindow"].buttons["Sign In"].click()
        
        waitForActivityIndicatorToDisappear()
    }

    
    func signOut()
    {
        closePopupWindows()
        app.menuBars.menuItems["My Account"].click()
        if app.windows["MainWindow"].buttons["Sign In"].exists {return}
        
        app.windows["MainWindow"].buttons["Sign Out"].click()
        waitUntil(app.windows["MainWindow"].toolbars.staticTexts["0 Days Left"].hittable)
        app.windows["MainWindow"].buttons["or skip"].click()
        
        closePopupWindows()
        app.menuBars.menuItems["My Account"].click()
        waitWhile(app.windows["MainWindow"].staticTexts[loginElite].exists)
    }
    
    func connectTo(vl: String)
    {
        for _ in 1...30
        {
            connection.click()
            virtualLocation.hover()
            if countries.menuItems[vl].hittable
            {
                countries.menuItems[vl].click()
                break
            }
            sleep(1)
        }
        app.menuItems["Connect"].click()
        checkForProfile()
    }
    
    func checkForProfile()
    {
        addUIInterruptionMonitorWithDescription("Profile") { (alert) -> Bool in
            alert.sheets.buttons["Download Profile..."].click()
            return true
        }
        
    }
    
    func waitUntil(check: Bool, seconds: Int = 30)
    {
        for _ in 1...seconds
        {
            if check {return}
            sleep(1)
        }
        XCTAssert(false)
    }
    
    func waitWhile(check: Bool, seconds: Int = 30)
    {
        for _ in 1...seconds
        {
            
            if check
            {
                sleep(1)
            }
            else
            {
                return
            }
        }
        XCTAssert(false)
    }
    
    func waitForActivityIndicatorToDisappear()
    {
        for _ in 1...30
        {
            if XCUIApplication().windows["MainWindow"].childrenMatchingType(.ActivityIndicator).element.exists
            {
                sleep(1)
            }
            else
            {
                return
            }
        }
        XCTAssert(false)
    }
    
}

extension CollectionType {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Generator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}