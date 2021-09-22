//
//  ViewController.swift
//  testUI
//
//  Created by Ahmed Eid on 2/14/1443 AH.
//

import UIKit
import SQLite3

class ContactsTVC: UITableViewController {

    var db : OpaquePointer?
    var contacts =  [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        db = openDatabase()
        if let db = db {
            createTable(db: db)
            query(db: db)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAlertController))
    }
    
    
    func openDatabase() -> OpaquePointer? {
        var db: OpaquePointer?
        let fileUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Contacts.sqlite")
        
        if sqlite3_open(fileUrl?.path, &db) ==  SQLITE_OK {
            print("successfully! open connection to database")
            return db;
        } else {
            print("faild to open database")
            return nil
        }
    }
    
    func createTable(db: OpaquePointer) {
        let createTabelString = """
        CREATE TABLE IF NOT EXISTS CONTACTS  (Id INT PRIMARY KEY NOT NULL, name CHAR(255));
        """
        
        //1
        var createTableStatment: OpaquePointer?
        
        //2
        if sqlite3_prepare_v2(db, createTabelString, -1, &createTableStatment, nil) == SQLITE_OK {
            
            //3
            if sqlite3_step(createTableStatment) == SQLITE_DONE {
               print("contacts table created")
            } else {
                print("contacts table not created")
            }
            
        } else {
            print("fail to prepaire table string")
        }
        
        //4
        sqlite3_finalize(createTableStatment)
    }
    
    
    func insertRow(id:Int32, name:NSString, db:OpaquePointer) {
        
        let insertString = "INSERT INTO CONTACTS (Id, name) VALUES (?, ?);"
        
        var insertStatment: OpaquePointer?
        
        //1 prepare statement by convert it to bytes
        //
        if sqlite3_prepare_v2(db, insertString, -1, &insertStatment, nil) == SQLITE_OK {
            
            // here you are find the value for the ? placeholder
            // binding assign id value to id key
            sqlite3_bind_int(insertStatment, 1, id)
            
            // assign name value to name key
            sqlite3_bind_text(insertStatment, 2, name.utf8String, -1, nil)
            
            // execute statement and verify it is finished
            if sqlite3_step(insertStatment) == SQLITE_DONE {
               print("Row instered successfully!")
            } else {
                print("Fail to inster row")
            }
            
            // if you were going to inster multipule contacts you are retain the statment
            // and reuse it with deferent values
            // free resources
            sqlite3_finalize(insertStatment)
        } else {
            let err = String(cString: sqlite3_errmsg(db))
            print("Can not prepare inster statemetn Err: \(err)")
        }
        
    }
    
    
    func query(db: OpaquePointer) {
        let queryString = "SELECT * from CONTACTS;"
        var queryStatment: OpaquePointer?
        
        
        if sqlite3_prepare_v2(db, queryString, -1, &queryStatment, nil) == SQLITE_OK {
            print("Query Result:")
            contacts = []
            while (sqlite3_step(queryStatment) == SQLITE_ROW) {
                let id = sqlite3_column_int(queryStatment, 0)
                guard let queryName = sqlite3_column_text(queryStatment, 1) else {
                    print("Fail to get name value")
                    return
                }
                let name = String(cString: queryName)
                
                print("\(id)  | \(name)")
                contacts.append("\(id)  | \(name)")
            }
            self.tableView.reloadData()
            
            sqlite3_finalize(queryStatment)
            
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Query is not prepared due to error \(errorMessage)")
        }
    }
    
    func delete(db: OpaquePointer) {
        let deleteString = "DELETE FROM CONTACTS WHERE Id = 2;"
        var deleteStatment: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteString, -1, &deleteStatment, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatment) == SQLITE_DONE {
               print("Row Deleted Successfully")
            } else {
                print("Fail to delte row")
            }
            
        } else {
            print("Fail to prepare delete query")
        }
        
        sqlite3_finalize(deleteStatment)
    }

    
    @objc func showAlertController() {
        let ac = UIAlertController(title: "Enter new contact", message: "Here you can add new contact to database", preferredStyle: .alert)
        ac.addTextField { (idTF) in
            idTF.placeholder = "Enter Id"
        }
        ac.addTextField { (nameTF) in
            nameTF.placeholder = "Enter contact"
        }
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] action in
            guard let ac = ac,let self = self, let db = self.db  else {
                return
            }
            guard let id = ac.textFields?[0].text else {
                return
            }
            guard let name = ac.textFields?[1].text else {
                return
            }
            guard let idAsInt = Int32(id) else {
                return
            }
            self.insertRow(id: idAsInt, name: NSString(string: name), db: db)
            self.query(db: db)
        }
        ac.addAction(submitAction)
        present(ac, animated: true, completion: nil)
    }

}

extension ContactsTVC {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        cell.textLabel?.text = contacts[indexPath.row]
        return cell
    }
}
