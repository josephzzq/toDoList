//
//  TasksViewController.swift
//  RealmTasks
//
//  Created by Joseph.Tsai on 2016/8/2.
//  Copyright © 2016年 Joseph.Tsai. All rights reserved
//

import UIKit
import RealmSwift
import Charts

class TasksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var selectedList : TaskList!
    var inProgressTasks : Results<Task>!
    var pendingTasks : Results<Task>!
    var completedTasks : Results<Task>!
    var currentCreateAction:UIAlertAction!
    
    var isEditingMode = false
    
    var footerView = PieChartView()
    
    @IBOutlet weak var tasksTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = selectedList.name
 
        footerView.noDataText=""
        readTasksAndUpateUI()
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        footerView.centerText="\(self.title!) List %"
        self .chartMethod()
    }
    
    
    // MARK: - User Actions -
    
    @IBAction func didClickOnEditTasks(sender: AnyObject) {
        isEditingMode = !isEditingMode
        self.tasksTableView.setEditing(isEditingMode, animated: true)
    }
    @IBAction func didClickOnNewTask(sender: AnyObject) {
        self.displayAlertToAddTask(nil)
    }
    
    func readTasksAndUpateUI(){
        
        inProgressTasks = self.selectedList.tasks.filter("todoListStatus = 'InProgress'")
        pendingTasks = self.selectedList.tasks.filter("todoListStatus = 'Pending'")
        completedTasks = self.selectedList.tasks.filter("todoListStatus = 'Done'")
        
        self.tasksTableView.reloadData()
    }
    
    func chartMethod(){
        
        let progressRatio = ratio(inProgressTasks.count)
        let pendingRatio = ratio(pendingTasks.count)
        let completeRatio = ratio(completedTasks.count)
        
        var pieChartStatusPercent : [Double]=[]
        var pieChartStatus : [String]=[]
        
        if progressRatio > 0.0 {
            pieChartStatusPercent.append(progressRatio)
            pieChartStatus.append("Work")
        }
        
        if pendingRatio > 0.0 {
            pieChartStatusPercent.append(pendingRatio)
            pieChartStatus.append("Pending")
        }
        
        if completeRatio > 0.0 {
            pieChartStatusPercent.append(completeRatio)
            pieChartStatus.append("Finish")
        }

        guard  pieChartStatusPercent.isEmpty else{
            self.setChart(pieChartStatus, values: pieChartStatusPercent)
            return
        }
    }
    
    func ratio(count: Int) -> Double {
        let totalCount = completedTasks.count+inProgressTasks.count+pendingTasks.count
        let ratio = Double(count)/Double(totalCount)*Double(100)
        if ratio.isNaN {
            return 0.0
        }
        return ratio
    }
    
    func setChart(dataPoints: [String], values: [Double]) {
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(yVals: dataEntries, label: "%")
        
        // setup %
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.maximumFractionDigits = 1
        formatter.multiplier = 1.0
        pieChartDataSet.valueFormatter = formatter
        
        // custom legend label color
        let legend = footerView.legend
        legend.textColor=UIColor .whiteColor()
        legend.position=ChartLegend.Position.BelowChartCenter
//        legend.setCustom(colors: [UIColor.whiteColor(), UIColor.whiteColor(), UIColor.whiteColor()], labels: ["Work", "Pending", "Finish"])

        // setup ramdom color
        var colors: [UIColor] = []
        for i in 0..<dataPoints.count {
            let red = Double(arc4random_uniform(256))
            let green = Double(arc4random_uniform(256))
            let blue = Double(arc4random_uniform(256))
            
            let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
            colors.append(color)
            
            pieChartDataSet.colors = colors
        }

        // setup x,y val
        let pieChartData = PieChartData(xVals: dataPoints, dataSet: pieChartDataSet)
        footerView.data = pieChartData
        footerView.animate(xAxisDuration: 1.4, yAxisDuration: 1.4)
        footerView.descriptionText=""
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UITableViewDataSource -
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if section == 0{
            return inProgressTasks.count
        } else if section == 1{
            return pendingTasks.count
        }
        return completedTasks.count
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0{
            return "IN PROGRESS - TASKS"
        }else if section == 1{
            return "PENDING - TASKS"
        }
        return "COMPLETED - TASKS"
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        if section==2 {
            return 300
        }
        return 0
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        if section==2 {
            let footerView=UIView(frame: CGRectMake(0, 0,self.view.frame.width, 0))
            self.footerView.frame=footerView.frame
            return self.footerView
        }
        return nil
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")
        var task: Task!
        if indexPath.section == 0{
            task = inProgressTasks[indexPath.row]
        }
        else if indexPath.section == 1 {
            task = pendingTasks[indexPath.row]
        }else{
            task = completedTasks[indexPath.row]
        }
        
        cell?.selectionStyle=UITableViewCellSelectionStyle.None
        
        cell?.textLabel?.text = task.name
        return cell!
    }
    
    
    func displayAlertToAddTask(updatedTask:Task!){
        
        var title = "New Task"
        var doneTitle = "Create"
        if updatedTask != nil{
            title = "Update Task"
            doneTitle = "Update"
        }
        
        let alertController = UIAlertController(title: title, message: "Write the name of your task.", preferredStyle: UIAlertControllerStyle.Alert)
        let createAction = UIAlertAction(title: doneTitle, style: UIAlertActionStyle.Default) { (action) -> Void in
            
            let taskName = alertController.textFields?.first?.text
            
            if updatedTask != nil{
                // update task
                do{
                    try realmInstance.write({ () -> Void in
                        updatedTask.name = taskName!
                        self.readTasksAndUpateUI()
                    })
                }
                catch (let e){
                    
                }

            }
            else{
                // new task
                let newTask = Task()
                newTask.name = taskName!
            
                do{
                    try realmInstance.write({ () -> Void in
                        self.selectedList.tasks.append(newTask)
                        self.readTasksAndUpateUI()
                        self.chartMethod()
                    })
                }
                catch (let e){
                    
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
            if updatedTask != nil{
                textField.text = updatedTask.name
            }
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    //Enable the create action of the alert only if textfield text is not empty
    func taskNameFieldDidChange(textField:UITextField){
        self.currentCreateAction.enabled = textField.text?.characters.count > 0
    }
    
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete") { (deleteAction, indexPath) -> Void in
            
            //1.Delete
            var taskToBeDeleted: Task!
            if indexPath.section == 0{
                taskToBeDeleted = self.inProgressTasks[indexPath.row]
            }else if indexPath.section == 1{
                taskToBeDeleted = self.pendingTasks[indexPath.row]
            }else{
                taskToBeDeleted = self.completedTasks[indexPath.row]
            }
            
            do{
               try realmInstance.write({ () -> Void in
                    realmInstance.delete(taskToBeDeleted)
                    self.readTasksAndUpateUI()
                    self.chartMethod()
                })
            }
            catch (let e){
                
            }

        }
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit") { (editAction, indexPath) -> Void in
            
            //2.Editing
            var taskToBeUpdated: Task!
            if indexPath.section == 0{
                taskToBeUpdated = self.inProgressTasks[indexPath.row]
            }else if indexPath.section == 1{
                taskToBeUpdated = self.pendingTasks[indexPath.row]
            }else{
                taskToBeUpdated = self.completedTasks[indexPath.row]
            }
            
            self.displayAlertToAddTask(taskToBeUpdated)
            
        }
        
        let pendingAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Pending") { (doneAction, indexPath) -> Void in
            
            //3.Pending
            var taskToBeUpdated: Task!
            if indexPath.section == 0{
                taskToBeUpdated = self.inProgressTasks[indexPath.row]
            }else if indexPath.section == 1{
                taskToBeUpdated = self.pendingTasks[indexPath.row]
            }else{
                taskToBeUpdated = self.completedTasks[indexPath.row]
            }
            
            do{
                try realmInstance.write({ () -> Void in
                    taskToBeUpdated.todoListStatus = "Pending"
                    self.readTasksAndUpateUI()
                    self.chartMethod()
                })
            }
            catch (let e){
                
            }
            
        }
        
        let doneAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Done") { (doneAction, indexPath) -> Void in
            
            //4.Done
            var taskToBeUpdated: Task!
            if indexPath.section == 0{
                taskToBeUpdated = self.inProgressTasks[indexPath.row]
            }else if indexPath.section == 1{
                taskToBeUpdated = self.pendingTasks[indexPath.row]
            }else{
                taskToBeUpdated = self.completedTasks[indexPath.row]
            }
            
            do{
                try realmInstance.write({ () -> Void in
                      taskToBeUpdated.todoListStatus = "Done"
                    self.readTasksAndUpateUI()
                    self.chartMethod()
                })
            }
            catch (let e){
                
            }
            
        }
        return [deleteAction, editAction, pendingAction, doneAction]
    }
}
