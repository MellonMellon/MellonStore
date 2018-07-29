//
//  ViewController.swift
//  MellonStoreSample
//
//  Created by favre on 29/07/2018.
//  Copyright © 2018 mellonmellon. All rights reserved.
//

import UIKit
import CoreData
import MellonStore

class ViewController: UIViewController {

  @IBOutlet weak var tableView: UITableView!
  lazy var fetchResultController: NSFetchedResultsController = {
    return Query(Fruit.self)
      .sort("name")
      .toFetchedResultsController()
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    tableView.delegate = self
    tableView.dataSource = self
    
    fetchResultController.delegate = self
    try? fetchResultController.performFetch()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

//MARK: - NSFetchedResultsControllerDelegate
extension ViewController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.reloadData()
  }
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return fetchResultController.sections?.count ?? 0
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if (editingStyle == UITableViewCellEditingStyle.delete) {
      if let fruit = fetchResultController.object(at: indexPath) as? Fruit {
        MellonStore.default.transaction { context in
          let fruit = context.fetch(entity: fruit)
          context.delete(fruit)
        }
      }
    }
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchResultController.sections?[section].numberOfObjects ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "fruitCell", for: indexPath)
    
    if let fruit = fetchResultController.object(at: indexPath) as? Fruit {
      cell.textLabel?.text = fruit.name
      cell.imageView?.image = UIImage(named: fruit.imageName ?? "")
    }
    
    return cell
  }
  
}

