//
//  Fruit+CoreDataClass.swift
//  
//
//  Created by favre on 29/07/2018.
//
//

import Foundation
import CoreData

@objc(Fruit)
public class Fruit: NSManagedObject {
  @NSManaged public var id: String?
  @NSManaged public var name: String?
  @NSManaged public var imageName: String?
}
