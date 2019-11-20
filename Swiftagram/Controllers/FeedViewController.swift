//
//  FeedViewController.swift
//  Swiftagram
//
//  Created by Jonathan Abantao on 11/12/19.
//  Copyright © 2019 Jonathan Abantao. All rights reserved.
//

import UIKit
import Parse
import Alamofire

import AlamofireImage

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts = [PFObject]()
    var postsLimit = 20
    var refreshCount = 0
    let postsRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        DataRequest.addAcceptableImageContentTypes(["application/octet-stream"])
        
        postsRefreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
        tableView.refreshControl = postsRefreshControl
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadPosts()
    }
    
    @IBAction func logout(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        
        let sceneDelegate = self.view.window?.windowScene?.delegate as! SceneDelegate
        
        sceneDelegate.window?.rootViewController = loginViewController
    }
    
    @objc private func loadPosts() {
        refreshCount = 0
        
        let query = PFQuery(className: "Posts")
        query.includeKey("author")
        query.limit = 20
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            } else {
                print("\(String(describing: error))")
            }
            
            self.postsRefreshControl.endRefreshing()
        }
    }
    
    private func loadMorePosts() {
        let query = PFQuery(className: "Posts")
        query.includeKey("author")
        query.limit = 20
        query.skip = refreshCount * 20
        refreshCount += 1
        
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts += posts!
                self.tableView.reloadData()
            } else {
                print("\(String(describing: error))")
            }
            
            self.postsRefreshControl.endRefreshing()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell") as! PostTableViewCell
        let post = posts[indexPath.row]
        
        let user = post["author"] as! PFUser
        cell.usernameLabel.text = user.username
        cell.contentLabel.text = (post["caption"] as! String)
        
        let imageFile = post["image"] as! PFFileObject
        let urlString = imageFile.url!
        let url = URL(string: urlString)!
        
        cell.photoView.af_setImage(withURL: url)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == posts.count {
            self.loadMorePosts()
        }
    }
}
