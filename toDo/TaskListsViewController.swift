//
//  TaskListsViewController.swift
//  RealmTasks
//
//  Created by Joseph.Tsai on 2016/8/2.
//  Copyright © 2016年 Joseph.Tsai. All rights reserved
//

import UIKit
import RealmSwift

class TaskListsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var lists : Results<TaskList>!
    
    var isEditingMode = false
    
    var currentCreateAction:UIAlertAction!
    @IBOutlet weak var taskListsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        readTasksAndUpdateUI()
    }
    
    func readTasksAndUpdateUI(){
        
        lists = uiRealm.objects(TaskList)
        self.taskListsTableView.setEditing(false, animated: true)
        self.taskListsTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - User Actions -
    
    
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
    
    @IBAction func didClickOnEditButton(sender: UIBarButtonItem) {
        isEditingMode = !isEditingMode
        self.taskListsTableView.setEditing(isEditingMode, animated: true)
    }
    
    @IBAction func didClickOnAddButton(sender: UIBarButtonItem) {
        
        displayAlertToAddTaskList(nil)
    }
    
    //Enable the create action of the alert only if textfield text is not empty
    func listNameFieldDidChange(textField:UITextField){
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
            
            let listName = alertController.textFields?.first?.text
            
            if updatedList != nil{
                // update mode
                
                do{
                    try uiRealm.write({ () -> Void in
                        updatedList.name = listName!
                        self.readTasksAndUpdateUI()
                    })
                }
                catch (let e){
                    
                }

            }
            else{
                
                let newTaskList = TaskList()
                newTaskList.name = listName!
                
                do{
                    try uiRealm.write({ () -> Void in
                        uiRealm.add(newTaskList)
                        self.readTasksAndUpdateUI()
                    })
                }
                catch (let e){
                    
                }

            }
            
            
            
            print(listName, terminator: "")
        }
        
        alertController.addAction(createAction)
        createAction.enabled = false
        self.currentCreateAction = createAction
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Task Name"
            textField.addTarget(self, action: "listNameFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            if updatedList != nil{
                textField.text = updatedList.name
            }
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource -
    
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
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete") { (deleteAction, indexPath) -> Void in
            
            //Deletion will go here
            
            let listToBeDeleted = self.lists[indexPath.row]
            
            do{
                try uiRealm.write({ () -> Void in
                    uiRealm.delete(listToBeDeleted)
                    self.readTasksAndUpdateUI()
                })
            }
            catch (let e){
                
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let tasksViewController = segue.destinationViewController as! TasksViewController
        tasksViewController.selectedList = sender as! TaskList
    }

}
