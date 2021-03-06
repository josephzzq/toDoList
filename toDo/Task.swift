//
//  Task.swift
//  toDo
//
//  Created by Joseph.Tsai on 2016/8/2.
//  Copyright © 2016年 Joseph.Tsai. All rights reserved.
//

import RealmSwift


enum listStatus:String {
    case InProgress
    case Pending
    case Done
}


class Task: Object {
    dynamic var name = ""
    dynamic var createdAt = NSDate()
    dynamic var notes = ""
    dynamic var todoListStatus = listStatus.InProgress.rawValue
}
