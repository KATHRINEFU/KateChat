//
//  ProfileViewController.swift
//  KateChat
//
//  Created by KateFu on 2/5/23.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    private let followInstaLabel: UILabel = {
        let label = UILabel()
        label.text = "Follow me on Instagram!"
        label.textAlignment = .center
        label.textColor = .black
        label.numberOfLines = 0
        label.contentMode = .scaleToFill
        return label
    }()
    
//    private let instaBtn: UIButton = {
//        let button = UIButton()
////        button.setImage(UIImage(named: "insta.png"), for: .normal)
//        button.isEnabled = true
//        button.isUserInteractionEnabled = true
//        return button
//    }()
    
    private let instaImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "insta")
        iv.contentMode = .scaleAspectFill
        iv.layer.masksToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    
    var data = ["Log Out"]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isUserInteractionEnabled = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(instaImageTapped(tapGestureRecognizer:)))
        instaImageView.addGestureRecognizer(tapGestureRecognizer)
//        instaBtn.addTarget(self, action: #selector(instaBtnTapped), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.tableHeaderView = createTableHeader()
        addProfileInfo()
        tableView.tableFooterView = createTableFooter()
    }
    
    @objc private func instaImageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        print("image tapped")
    }
    
    private func createTableFooter()->UIView?{
        let footerView = UIView(frame: CGRect(x: 0 , y: self.view.height-200, width: self.view.width, height: 200))
        footerView.isUserInteractionEnabled = true
        
        let socialStack =  UIStackView(frame: CGRect(x: 0, y: 0, width: footerView.width/2, height: 150))
        socialStack.isUserInteractionEnabled = true
        
        followInstaLabel.frame = CGRect(x: socialStack.left+20, y: 0, width: 200, height: socialStack.height)
        
        instaImageView.frame = CGRect(x: followInstaLabel.right+50, y: socialStack.top+50, width: 150, height: socialStack.height)
        
        
        socialStack.addSubview(followInstaLabel)
        socialStack.addSubview(instaImageView)
        
        footerView.addSubview(socialStack)
        
        return footerView
    }
    
    private func addProfileInfo(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return
        }
        
        guard let name = UserDefaults.standard.value(forKey: "name") as? String else{
            return
        }
        data.insert(name, at: 0)
        data.insert(email, at: 0)
        
    }
    
    func createTableHeader()->UIView?{
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let fileName = safeEmail+"_profile_picture.png"
        let path = "images/"+fileName
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .purple
        let imageView = UIImageView(frame: CGRect(x: (headerView.width-150)/2, y: 75, width: 150, height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadUrl(for: path, completion: {[weak self]result in
            switch result{
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        })
        
        return headerView
    }
    
    func downloadImage(imageView: UIImageView, url: URL){
        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume()
    }
    
    
    
}

extension ProfileViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .systemPink
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        do {
            if indexPath.row == 2{
                try FirebaseAuth.Auth.auth().signOut()
                            let loginVC = LoginViewController()
                            let nav = UINavigationController(rootViewController: loginVC)
                            nav.modalPresentationStyle = .fullScreen
                            present(nav, animated: true)
            }
            
        }catch{
            print("Failed to logout")
        }
    }
}
