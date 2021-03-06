//
//  UitlaatViewController.swift
//  NavigationTests
//
//  Created by Thorr Stevens on 05/06/15.
//  Copyright (c) 2015 Thorr Stevens. All rights reserved.
//

import UIKit
import Alamofire
import CoreLocation

let LOCATION_RADIUS = 0.4 //%%% how wide to search in relation to own location when dealing with latitude and longitude
let HOURS_AGO = 10 //%%% get messages from how many hours ago?

class UitlaatViewController: UIViewController {
    
    var charData:CharacterData!;
    var uitlaatContainer:DraggableUitlaatContainer!;
    
    var uitlaatMessages:Array<UitlaatData>!;
    
    var uitlaatView:UitlaatView {
        get{
            return self.view as! UitlaatView;
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);
        
        println("[UitlaatVC] Initialising ViewController");
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCharacterData(userData:CharacterData){
        
        self.charData = userData;
        self.uitlaatView.updateCharacterButton(self.charData.image);
        
    }
    
    override func loadView() {
        
        println("[UitlaatVC] Loading View");
        
        let containerRect = CGRectMake(0, 0, 488, 320);
        
        self.view = UitlaatView(frame: containerRect);
        
        self.loadUitlaatMessages();
        
    }
    
    func loadUitlaatMessages(){
        
        println("[UitlaatVC] Loading uitlaat posts");
        
        var locManager = CLLocationManager();
        locManager.requestWhenInUseAuthorization();
        var latitude = 50.960406;
        var longitude = 5.354287;
        var currentLocation = CLLocation();
        
        if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways
            ){
                
                currentLocation = locManager.location;
                
                latitude = currentLocation.coordinate.latitude;
                longitude = currentLocation.coordinate.longitude;
                
        }
        
        var lastSwipedID = 0;
        if (NSUserDefaults.standardUserDefaults().objectForKey("lastSwipedUitlaatId") != nil) {
            lastSwipedID = NSUserDefaults.standardUserDefaults().integerForKey("lastSwipedUitlaatId");
        }
        
        let maxLat = latitude + LOCATION_RADIUS;
        let minLat = latitude - LOCATION_RADIUS;
        let maxLong = longitude + LOCATION_RADIUS;
        let minLong = longitude - LOCATION_RADIUS;
        
        let apiEndPoint = "http://student.howest.be/thorr.stevens/20142015/MA4/BADGET/api/uitlaat/filter/hours/\(HOURS_AGO)/min_lat/\(minLat)/max_lat/\(maxLat)/min_long/\(minLong)/max_long/\(maxLong)/last_swiped_id/\(lastSwipedID)/";
        
        println("[UitlaatVC] Getting posts from \(apiEndPoint)");
        
        Alamofire.request(.GET, apiEndPoint).responseJSON { (_, _, data, _) in
            
            var jsonData = JSON(data!);
            
            var err:NSErrorPointer! = NSErrorPointer();
            let uitlaatData = NSJSONSerialization.dataWithJSONObject(jsonData.object, options: nil, error: err);
            
            self.uitlaatMessages = UitlaatPostsFactory.createFromJSONData(uitlaatData!);
            
            self.uitlaatContainer = DraggableUitlaatContainer(frame: CGRectMake(100, 0, 368, 300), uitlaatMessages: self.uitlaatMessages);
            self.uitlaatView.updateUitlaatContainer(self.uitlaatContainer);
            
        }
        
    }
    
    override func viewDidLoad() {
        
        println("[UitlaatVC] View did load");
        
        super.viewDidLoad();
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "postUitlaat:",
            name: "POST_TAPPED",
            object: self.uitlaatView.txtUitlaat
        );
        
    }
    
    func postUitlaat(notification:NSNotification){
        
        let alert = UIAlertController(title: "Misschien dronken", message: "Zeker dat u dit bericht wil posten? \n -\"\(self.uitlaatView.txtUitlaat.text)\"-", preferredStyle: UIAlertControllerStyle.Alert);
        
        let yesAction = UIAlertAction(title: "euh...ja zeker?", style: UIAlertActionStyle.Default) { (action) -> Void in
            
            println("[UitlaatVC] Posting message: \(self.uitlaatView.txtUitlaat.text)");
            
            var locManager = CLLocationManager();
            locManager.requestWhenInUseAuthorization();
            var latitude = 50.960406;
            var longitude = 5.354287;
            var currentLocation = CLLocation();
            
            if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways
                ){
                    
                    currentLocation = locManager.location;
                    
                    latitude = currentLocation.coordinate.latitude;
                    longitude = currentLocation.coordinate.longitude;
                    
            }
            
            var postsEndpoint: String = "http://student.howest.be/thorr.stevens/20142015/MA4/BADGET/api/uitlaat/"
            var parameters = ["character_id": self.charData.id, "title": "Pukkelpop 2015", "message": self.uitlaatView.txtUitlaat.text, "latitude": latitude, "longitude": longitude];
            Alamofire.request(.POST, postsEndpoint, parameters: parameters as! [String : AnyObject], encoding: .JSON)
                .responseJSON { (request, response, data, error) in
                    if let anError = error
                    {
                        println("error calling POST on /posts");
                        println(error);
                    }
                    else if let data: AnyObject = data
                    {
                        let post = JSON(data);
                        println("The post is: " + post.description);
                        
                        let successAlert = UIAlertController(title: "Success!", message: "Je uitlaatbericht is met succes gepost.\n Dansen dansen!", preferredStyle: UIAlertControllerStyle.Alert);
                        self.presentViewController(successAlert, animated: true, completion: nil);
                        
                        self.uitlaatView.txtUitlaat.text = "";
                        self.uitlaatView.hideInput();
                        
                        let delay = 0.9 * Double(NSEC_PER_SEC);
                        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay));
                        dispatch_after(time, dispatch_get_main_queue()) {
                            successAlert.dismissViewControllerAnimated(true, completion: nil);
                            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasPostedMessage");
                            NSNotificationCenter.defaultCenter().postNotificationName(
                                "ACHIEVEMENT_COMPLETED",
                                object: "uitlaat"
                            );
                        }
                    }
            }
            
        }
        
        let cancelAction = UIAlertAction(title: "toch nog aanpassen", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            println("[UitlaatVC] Post was cancelled.");
        }
        
        let destroyAction = UIAlertAction(title: "vernietig het bewijs", style: UIAlertActionStyle.Destructive) { (action) -> Void in
            
            println("[UitlaatVC] Post was destroyed.");
            
            self.uitlaatView.txtUitlaat.text = "";
            self.uitlaatView.hideInput();
            
        }
        
        alert.addAction(cancelAction);
        alert.addAction(yesAction);
        alert.addAction(destroyAction);
        
        self.presentViewController(alert, animated: true, completion: nil);
        
        
    }
    
    deinit {
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: "POST_TAPPED",
            object: self.uitlaatView.txtUitlaat
        );
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
