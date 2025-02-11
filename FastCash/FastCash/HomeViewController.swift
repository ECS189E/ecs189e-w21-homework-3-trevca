//
//  HomeViewController.swift
//  FastCash
//
//  Created by Trevor Carpenter on 1/18/21.
//  Copyright © 2021 Trevor Carpenter. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var TableView: UITableView!
    @IBOutlet weak var Name: UITextField!
    @IBOutlet weak var TotalAmountLabel: UILabel!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    var phoneNumber = ""
    var name = ""
    var totalAmount = 0.0
    var accounts: [Account] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.TableView.dataSource = self
        self.TableView.delegate = self
        self.setValues()
        self.tapGestureRecognizer.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = TableView.indexPathForSelectedRow {
            TableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    func setValues() {
        self.wait()
        Api.user(completion: { response, error in
            guard let resp = response else {
                return
            }
            // initialize the next view's Wallet based on the response variable
            let wallet = Wallet.init(data: resp, ifGenerateAccounts: false)
            
            self.name = wallet.userName ?? ""
            if self.name == "" {
                self.name = self.phoneNumber
            }
            self.Name.text = self.name
            self.accounts = wallet.accounts
            self.phoneNumber = wallet.phoneNumber
            self.totalAmount = self.accounts.reduce(0.0, {$0+$1.amount})
            self.TotalAmountLabel.text =  "Your Total Amount is  \(self.formatMoney(amount: self.totalAmount))"
            self.TableView.reloadData()
            self.start()
        })
    }
    
    @IBAction func nameEdited() {
        var text = Name.text ?? ""
        if text.count == 0{
            text = self.phoneNumber
        }
        self.name = text
        Name.text = text
        Api.setName(name: self.name, completion: { response, error in
            if let err = error {
                print(err)
            } else if let resp = response {
                print(resp)
            }
        })
    }
    
    @IBAction func startedEditing(_ sender: Any) {
        self.tapGestureRecognizer.isEnabled = true
    }
    
    @IBAction func logOut(_ sender: Any) {
        Api.setAccounts(accounts: self.accounts, completion: { response, error in
            if let err = error {
                print(err)
            } else if let resp = response {
                print(resp)
            }
        })
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(identifier: "login")
        if let nav = self.navigationController {
            nav.setViewControllers([loginVC, self], animated: false)
            nav.popToRootViewController(animated: true)
        } else {
            assertionFailure("no navigation controller")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
            assertionFailure("Cell dequeue error")
            return UITableViewCell.init()
        }
        cell.textLabel?.text = accounts[indexPath.row].name
        let amount = " \(self.formatMoney(amount: accounts[indexPath.row].amount))"
        cell.detailTextLabel?.text = amount
        return cell
    }
    
    func formatMoney(amount: Double) -> String {
        let charactersRev: [Character] = String(format: "$%.02f", amount).reversed()
        if charactersRev.count < 7 {
            return String(format: "$%.02f", amount)
        }
        var newChars: [Character] = []
        for (index, char) in zip(0...(charactersRev.count-1), charactersRev) {
            if (index-6)%3 == 0 && (index-6) > -1 && char != "$"{
                newChars.append(",")
                newChars.append(char)
            } else {
                newChars.append(char)
            }
        }
        
        return String(newChars.reversed())
    }
    
    @IBAction func tap(_ sender: Any) {
        self.view.endEditing(true)
        self.tapGestureRecognizer.isEnabled = false
    }
    
    func wait() {
        self.ActivityIndicator.startAnimating()
        self.view.alpha = 0.2
        self.view.isUserInteractionEnabled = false
    }
    func start() {
        self.ActivityIndicator.stopAnimating()
        self.view.alpha = 1
        self.view.isUserInteractionEnabled = true
    }
}
