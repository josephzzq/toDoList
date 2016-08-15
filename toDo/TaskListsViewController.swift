//
//  TaskListsViewController.swift
//  RealmTasks
//
//  Created by Joseph.Tsai on 2016/8/2.
//  Copyright © 2016年 Joseph.Tsai. All rights reserved
//

import UIKit
import RealmSwift
import GoogleMobileAds

class TaskListsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GADBannerViewDelegate, GADInterstitialDelegate{

    var lists : Results<TaskList>!
    var isEditingMode = false
    var currentCreateAction:UIAlertAction!
    
    @IBOutlet weak var taskListsTableView: UITableView!
    @IBOutlet weak var bannerView: GADBannerView!
    var interstitial:GADInterstitial!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup admob
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.loadRequest(GADRequest())
        bannerView.delegate=self
    
//        self.createLoadInterstitial()
    }
    
    override func viewWillAppear(animated: Bool) {
        readTasksAndUpdateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // TODO: need move to welcome page
    func createLoadInterstitial(){
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        let request = GADRequest()
        // Request test ads on devices you specify. Your test device ID is printed to the console when
        // an ad request is made.
        request.testDevices = [ kGADSimulatorID, "2e774b2da80a408a362abcf758084c55" ]
        interstitial.loadRequest(request)
        interstitial.delegate = self
    }
    
    // MARK: GADInterstitialDelegate delegate
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        /// Called when an interstitial ad request succeeded.
        print("interstitialDidReceiveAd")
        if interstitial.isReady {
            interstitial.presentFromRootViewController(self)
        }
    }
    
    /// Called when an interstitial ad request failed.
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Called just before presenting an interstitial.
    func interstitialWillPresentScreen(ad: GADInterstitial!) {
        print("interstitialWillPresentScreen")
    }
    
    /// Called before the interstitial is to be animated off the screen.
    func interstitialWillDismissScreen(ad: GADInterstitial!) {
        print("interstitialWillDismissScreen")
    }
    
    /// Called just after dismissing an interstitial and it has animated off the screen.
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        print("interstitialDidDismissScreen")
    }
    
    /// Called just before the application will background or terminate because the user clicked on an
    /// ad that will launch another app (such as the App Store).
    func interstitialWillLeaveApplication(ad: GADInterstitial!) {
        print("interstitialWillLeaveApplication")
    }
    
    
    // MARK: GADBannerView delegate
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        bannerView.hidden=false
        bannerView.alpha=0
        UIView.animateWithDuration(1, animations: {
            bannerView.alpha=1
        })
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("adView:didFailToReceiveAdWithError:\(error.localizedDescription)")
    }
    
    // MARK: Actions
    func readTasksAndUpdateUI(){
        
        lists = realmInstance.objects(TaskList)
        self.taskListsTableView.setEditing(false, animated: true)
        self.taskListsTableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let tasksViewController = segue.destinationViewController as! TasksViewController
        tasksViewController.selectedList = sender as! TaskList
    }
    
    
    @IBAction func didSelectSortCriteria(sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0{
            
            // A-Z
            self.lists = self.lists.sorted("name")
        }
        else{
            // date
            self.lists = self.lists.sorted("createdAt", ascending:false)
        }
        self.taskListsTableView.reloadData()
    }
    
    @IBAction func editTaskBtn(sender: UIBarButtonItem) {
        isEditingMode = !isEditingMode
        self.taskListsTableView.setEditing(isEditingMode, animated: true)
    }
    
    @IBAction func addTaskBtn(sender: UIBarButtonItem) {
        
        displayAlertToAddTaskList(nil)
    }
    
    // enable create action when textField >0
    func taskNameFieldDidChange(textField:UITextField){
        self.currentCreateAction.enabled = textField.text?.characters.count > 0
    }
    
    func displayAlertToAddTaskList(updatedList:TaskList!){
        
        var title = "New Tasks"
        var doneTitle = "Create"
        
        if updatedList != nil{
            title = "Update Tasks"
            doneTitle = "Update"
        }
        
        let alertController = UIAlertController(title: title, message: "Write the name of your task.", preferredStyle: UIAlertControllerStyle.Alert)
        let createAction = UIAlertAction(title: doneTitle, style: UIAlertActionStyle.Default) { (action) -> Void in
            
            let taskName = alertController.textFields?.first?.text
            
            if updatedList != nil{
                // update task
                do{
                    try realmInstance.write({ () -> Void in
                        updatedList.name = taskName!
                        self.readTasksAndUpdateUI()
                    })
                }
                catch (let err){
                    
                }
            }
            else{
                // create task
                let newTaskList = TaskList()
                newTaskList.name = taskName!
                
                do{
                    try realmInstance.write({ () -> Void in
                        realmInstance.add(newTaskList)
                        self.readTasksAndUpdateUI()
                    })
                }
                catch (let err){
                    
                }
            }
        }
        
        alertController.addAction(createAction)
        createAction.enabled = false
        self.currentCreateAction = createAction
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Task Name"
            textField.addTarget(self, action: "taskNameFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            if updatedList != nil{
                textField.text = updatedList.name
            }
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let listsTasks = lists{
            return listsTasks.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell")
        
        let list = lists[indexPath.row]
        
        cell?.selectionStyle=UITableViewCellSelectionStyle.None
        
        cell?.textLabel?.text = list.name
        cell?.detailTextLabel?.text = "\(list.tasks.count) Tasks"
        return cell!
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete") { (deleteAction, indexPath) -> Void in
            
            //Deletion will go here
            
            let listToBeDeleted = self.lists[indexPath.row]
            
            do{
                try realmInstance.write({ () -> Void in
                    realmInstance.delete(listToBeDeleted)
                    self.readTasksAndUpdateUI()
                })
            }
            catch (let err){
                
            }
        }
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit") { (editAction, indexPath) -> Void in
            
            // Editing will go here
            let listToBeUpdated = self.lists[indexPath.row]
            self.displayAlertToAddTaskList(listToBeUpdated)
            
        }
        return [deleteAction, editAction]
    }

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.performSegueWithIdentifier("openTasks", sender: self.lists[indexPath.row])
    }
    


}
