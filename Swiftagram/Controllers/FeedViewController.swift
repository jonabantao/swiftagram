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
        query.order(byDescending: "createdAt")
        query.includeKeys(["author", "comments", "comments.author"])
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
        query.order(byDescending: "createdAt")
        query.includeKeys(["author", "comments", "comments.author"])
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        let comment = PFObject(className: "Comments")
        
        comment["text"] = "Hey a comment"
        comment["post"] = post
        comment["author"] = PFUser.current()!
        
        post.add(comment, forKey: "comments")
        
        post.saveInBackground { (success, error) in
            if (success) {
                print("Comment saved")
            } else {
                print("Comment error")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell") as! PostTableViewCell
        
        if indexPath.row == 0 {
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            cell.contentLabel.text = (post["caption"] as! String)
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af_setImage(withURL: url)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as! CommentTableViewCell
            let comment = comments[indexPath.row - 1]
            let commenter = comment["author"] as! PFUser
            
            cell.commentLabel.text = (comment["text"] as! String)
            cell.commenterLabel.text = commenter.username
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == posts.count {
            self.loadMorePosts()
        }
    }
}
