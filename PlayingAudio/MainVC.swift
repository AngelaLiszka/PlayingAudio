//
//  ViewController.swift
//  PlayingAudio
//
//  Created by Karim El Sheikh on 8/11/17.
//  Copyright © 2017 playing. All rights reserved.
//

import UIKit
import AnimatedCollectionViewLayout
import AVFoundation

class MainVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CustomCellDelegate, CAAnimationDelegate {
    var rowLast = false
    var thereIsCellTapped = false
    var selectedRowIndex = -1
    let group = DispatchGroup()
    var streams: [[String:Any]] = []
    let layout = AnimatedCollectionViewLayout()
    var animator: (LinearCardAttributesAnimator, Bool, Int, Int)?
    let defaults = UserDefaults.standard
    var autoPlaySwitch = false
    var autoPlayAllSourcesSwitch = false
    var player:AVPlayer?
    var playerItem:AVPlayerItem?
    var zstreams: [[String:Any]] = []
    var filterClassName: [String] = []
    var activityIndicator: UIActivityIndicatorView!
    var viewActivityIndicator: UIView!
    var currentItem: IndexPath = []
    
    typealias CompletionHandler = (_ success:Bool) -> Void
    
    
    @IBOutlet weak var cv: UICollectionView!

    @IBAction func settingsBtn(_ sender: Any) {
        performSegue(withIdentifier: "segue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList), name: NSNotification.Name(rawValue: "reload"), object: nil)
        
        NotificationCenter.default.addObserver(self,selector: #selector(playDidEnd),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,object: nil)
    }
    
    func reloadList(){
        //load data here
        self.cv.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.autoPlaySwitch = self.defaults.bool(forKey: "savedSwitchSettingDefault")
        self.autoPlayAllSourcesSwitch = self.defaults.bool(forKey: "savedAllAutoplaySwitchSettingDefault")
        cv.alwaysBounceVertical = false
        cv.isPagingEnabled = true
        cv.delegate = self
        cv.dataSource = self
        layout.animator = LinearCardAttributesAnimator()
        layout.scrollDirection = .horizontal
        cv.collectionViewLayout = layout
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20)!]
        
        nextUpdate()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
        

        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = UIColor.clear
        UIApplication.shared.statusBarStyle = .lightContent
        

        if defaults.array(forKey: "usersSelection") != nil{
            streams = []
            zstreams = []
            readJson()
            filterClassName = defaults.array(forKey: "usersSelection") as! [String]
            let filteredItems = streams.filter{ filterClassName.contains($0["name"] as! String) }
            for value in filteredItems {
                let valuesss = value
                self.zstreams.append(valuesss)
            }
            streams = zstreams
            DispatchQueue.main.async {
                self.cv.reloadSections(IndexSet(integer: 0))
            }
        } else {
            readJson()
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func nextUpdate(){
        let now = Date()
        let calendar = Calendar.current
        
        let formatterTimeTxt = DateFormatter()
        formatterTimeTxt.dateFormat = "ha"
        let currentHour = formatterTimeTxt.string(from: now)
        
        
        let hour = calendar.component(.hour, from: now)
        
        let components = DateComponents(calendar: calendar, hour: hour + 1)  // <- 17:00 = 5pm
        let next5pm = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!
        let diff = calendar.dateComponents([.minute], from: now, to: next5pm)
        let minutesLeft = Int(diff.minute!)
        if minutesLeft < 30 {
            
            print("\(minutesLeft) minutes till next update")
        } else if(minutesLeft == 30){
            print("Last update at \(currentHour)")
        }else {
            print("Last update at \(currentHour)")
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    
    func loadList(){
        if defaults.array(forKey: "usersSelection") != nil{
            filterClassName = defaults.array(forKey: "usersSelection") as! [String]
        }
        
        let filteredItems = streams.filter{ filterClassName.contains($0["name"] as! String) }
        for value in filteredItems {
            let valuesss = value
            self.zstreams.append(valuesss)
            streams = zstreams
            self.cv.reloadData()
        }
        
    }
    
    func updatedList(){
        if defaults.array(forKey: "usersSelection") != nil{
            filterClassName = defaults.array(forKey: "usersSelection") as! [String]
        }
        
        let filteredItems = streams.filter{ filterClassName.contains($0["name"] as! String) }
        for value in filteredItems {
            let valuesss = value
            self.zstreams.append(valuesss)
            streams = zstreams
            self.cv.reloadData()
        }
        
    }

    
    
    private func readJson() {
        do {
            if let file = Bundle.main.url(forResource: "stations", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                if let object = json?["station"] as? [[String: Any]] {
                    
                    for obj in object {
                        self.streams.append(obj)
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // Just 1 section for now.
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Item count equals string array length.
        return streams.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        if let cell = cv.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CollectionViewCell {
            
            let i = indexPath.row % streams.count
            cell.bind(color: streams[i]["hex"] as! String)
            cell.clipsToBounds = animator?.1 ?? true
            cell.nameLbl.text = streams[indexPath.item]["shortname"] as? String
            cell.closeBtnView.isHidden = true
            cell.countdownLbl.isHidden = true
            cell.playImage.isEnabled = false
            cell.delegate = self
            cell.backgroundColor = UIColor.clear
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 3.0
            cell.layer.cornerRadius = 10.0
            cell.playImage.isHidden = true
            cell.scrubber.isHidden = true
            cell.playImagePreDisplay.isHidden = false
            cell.closeBtnHeight.constant = 20.0
            cell.nextLbl.isHidden = true
            return cell
        }else {
            
            return CollectionViewCell()
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.layer.cornerRadius = 10
        
        
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        
        currentItem = indexPath;
        if autoPlayAllSourcesSwitch != true {
            
            if indexPath == findCenterIndex(){
                if thereIsCellTapped != true {
                    let item = cv.cellForItem(at: indexPath) as! CollectionViewCell
                    self.loadingCell()
                    self.view.isUserInteractionEnabled = true
                    
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: ({
                            let i = indexPath.row % self.streams.count
                            item.bind(color: self.streams[i]["hex"] as! String)
                            item.layer.cornerRadius = 1.0
                            item.layer.borderWidth = 0.0
                            item.frame = self.cv.bounds
//                            item.cellMainViewBg.backgroundColor = UIColor.clear
                            item.playImagePreDisplay.isHidden = true
                            item.closeBtnHeight.constant = 40.0
                            item.scrubber.isHidden = false
                            item.closeBtnView.isHidden = false
                            item.superview?.bringSubview(toFront: item)
                            self.view.setNeedsLayout()
                            self.view.layoutIfNeeded()
                            item.setupNowPlayingInfoCenter()
                            item.updateNowPlayingInfoCenter(name: (self.streams[indexPath.item]["name"] as? String)!)
                        }), completion: { (finished: Bool) in
                            let theStream = self.streams[indexPath.item]["streamURL"] as? String
                            let isLive = self.streams[indexPath.item]["isLive"] as? Bool
                            if isLive! {
                                item.liveAudioStreamSelected(audioUrl: theStream!, live:isLive!)
                            } else {
                                item.audioStreamSelected(audioUrl: theStream!, live:isLive!) { (success) -> Void in
                                    item.nextLbl.isHidden = false
                                    item.countdownLbl.isHidden = false
                                    item.playImage.isEnabled = true
                                    self.cv.isScrollEnabled = false
                                    item.playImage.isHidden = false
                                    
                                    if self.autoPlaySwitch {
                                        DispatchQueue.main.async {
                                            item.audioPlay()
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            self.activityIndicator.stopAnimating()
                                            self.viewActivityIndicator.removeFromSuperview()
                                            self.view.isUserInteractionEnabled = true
                                        }
                                    }
                                    
                                }
                            }
                            
                        })
                    })
                    self.thereIsCellTapped = true
                }
            }
            
            
        } else {
            
            
            if thereIsCellTapped != true {
                let item = cv.cellForItem(at: indexPath) as! CollectionViewCell
                self.loadingCell()
                self.view.isUserInteractionEnabled = true
                
                
                let when = DispatchTime.now() + 3 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: ({
                        let i = indexPath.row % self.streams.count
                        item.bind(color: self.streams[i]["hex"] as! String)
                        item.layer.cornerRadius = 1.0
                        item.layer.borderWidth = 0.0
                        item.frame = self.cv.bounds
//                        item.cellMainViewBg.backgroundColor = UIColor.clear
                        item.playImagePreDisplay.isHidden = true
                        item.closeBtnHeight.constant = 40.0
                        item.scrubber.isHidden = false
                        item.closeBtnView.isHidden = false
                        item.superview?.bringSubview(toFront: item)
                        self.view.setNeedsLayout()
                        self.view.layoutIfNeeded()
                        item.setupNowPlayingInfoCenter()
                        item.updateNowPlayingInfoCenter(name: (self.streams[indexPath.item]["name"] as? String)!)
                    }), completion: { (finished: Bool) in
                        let theStream = self.streams[indexPath.item]["streamURL"] as? String
                        let isLive = self.streams[indexPath.item]["isLive"] as? Bool
                        if isLive! {
                            item.liveAudioStreamSelected(audioUrl: theStream!, live:isLive!)
                        } else {
                            item.audioStreamSelected(audioUrl: theStream!, live:isLive!) { (success) -> Void in
                                item.nextLbl.isHidden = false
                                item.countdownLbl.isHidden = false
                                item.playImage.isEnabled = true
                                self.cv.isScrollEnabled = false
                                item.playImage.isHidden = false
                                
                                if self.autoPlaySwitch {
                                    DispatchQueue.main.async {
                                        item.audioPlay()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.activityIndicator.stopAnimating()
                                        self.viewActivityIndicator.removeFromSuperview()
                                        self.view.isUserInteractionEnabled = true
                                    }
                                }
                                
                            }
                        }
                        
                    })
                }
                self.thereIsCellTapped = true
            }
            
            
            
            
        }
        
        
        
    }
    
    
    
    private func findCenterIndex() -> IndexPath {
        let center = self.view.convert(self.cv.center, to: self.cv)
        let index = cv!.indexPathForItem(at: center)
        return index!
        
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let animator = animator else {print(view.bounds.width); return CGSize(width: view.bounds.width - 15, height: view.bounds.height - 200) }
        
        return CGSize(width: view.bounds.width / CGFloat(animator.2), height: view.bounds.height / CGFloat(animator.3))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func playDidEnd(){
        let cell = cv.cellForItem(at: currentItem) as! CollectionViewCell
        cell.playerItemDidReachEnd()
        closeView(cell)
    }
    
    func backBtnAction(){
        let indexPath = cv.indexPathsForSelectedItems! as [NSIndexPath]
        cv.isScrollEnabled = true
        cv.reloadItems(at: indexPath as [IndexPath])
        
    }
    
    
    func removeLoading(_ cell: CollectionViewCell) {
        self.activityIndicator.stopAnimating()
        self.viewActivityIndicator.removeFromSuperview()
        self.view.isUserInteractionEnabled = true
    }
    
    func stopLoading(_ cell: CollectionViewCell) {
        self.activityIndicator.stopAnimating()
        self.viewActivityIndicator.removeFromSuperview()
        self.view.isUserInteractionEnabled = true
    }
    
    
    
    
    func closeViewAutoPlay(_ cell: CollectionViewCell) {
        self.activityIndicator.stopAnimating()
        self.viewActivityIndicator.removeFromSuperview()
        self.view.isUserInteractionEnabled = true
        let indexPath = self.cv.indexPathsForSelectedItems! as [NSIndexPath]
        print(indexPath)
        self.cv.isScrollEnabled = true
        self.cv.reloadItems(at: indexPath as [IndexPath])
        self.thereIsCellTapped = false
        
        
        
    }
    
    
    func closeView(_ cell: CollectionViewCell) {
        self.activityIndicator.stopAnimating()
        self.viewActivityIndicator.removeFromSuperview()
        self.view.isUserInteractionEnabled = true
        
        
        
        if self.autoPlayAllSourcesSwitch {
            self.loadingCell()
            self.view.isUserInteractionEnabled = true
            self.yourFunctionName() {
                let when = DispatchTime.now() + 2 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // Your code with delay
                    
                    
                    let visibleItems: NSArray = self.cv.indexPathsForVisibleItems as NSArray
                    self.currentItem = visibleItems.object(at: 0) as! IndexPath
                    let nextItem: IndexPath = IndexPath(item: self.currentItem.item, section: 0)
                    print(self.currentItem)
                    print(nextItem)
                    if nextItem.row == self.streams.count{
                        self.cv?.scrollToItem(at: IndexPath(row: 0, section: 0),
                                              at: .right,
                                              animated: true)
                        self.activityIndicator.stopAnimating()
                        self.viewActivityIndicator.removeFromSuperview()
                        self.view.isUserInteractionEnabled = true
                    }else {
                        
                        self.scrollToNextCell() { (success) -> Void in
                            if success {
                                let when = DispatchTime.now() + 3 // change 2 to desired number of seconds
                                DispatchQueue.main.asyncAfter(deadline: when) {
                                    self.activityIndicator.stopAnimating()
                                    self.viewActivityIndicator.removeFromSuperview()
                                    self.view.isUserInteractionEnabled = true
                                    if let centerCellIndexPath: NSIndexPath  = self.cv.centerCellIndexPath as NSIndexPath? {
                                        print(centerCellIndexPath)
                                        self.collectionView(self.cv, didSelectItemAt: centerCellIndexPath as IndexPath)
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
        } else {
            let indexPath = self.cv.indexPathsForSelectedItems! as [NSIndexPath]
            self.cv.isScrollEnabled = true
            self.cv.reloadItems(at: indexPath as [IndexPath])
            self.thereIsCellTapped = false
            
        }
        
        
        
        
    }
    
    
    func yourFunctionName(finished: @escaping () -> Void) {
        
        print("Doing something!")
        self.activityIndicator.stopAnimating()
        self.viewActivityIndicator.removeFromSuperview()
        self.view.isUserInteractionEnabled = true
        let indexPath = cv.indexPathsForSelectedItems!
        print(findCenterIndex())
        print("INDEX: \(indexPath)")
//        let centerIndex = findCenterIndex()
//        cv.isScrollEnabled = true
//        cv.reloadItems(at: [centerIndex] as [IndexPath])
        self.thereIsCellTapped = false
        
        
        let del = DispatchTime.now() + 3 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: del) {
            finished()
        }
        
    }
    
    
    func scrollToNextCell(completionHandler: CompletionHandler){
        
        //get cell size
        let cellSize = CGSize(width: self.view.frame.width, height: self.view.frame.height);
        
        //get current content Offset of the Collection view
        let contentOffset = cv.contentOffset;
        
        if cv.contentSize.width <= cv.contentOffset.x + cellSize.width
        {
            cv.scrollRectToVisible(CGRect(x: 0, y: contentOffset.y, width: cellSize.width, height: cellSize.height), animated: true);
            
        } else {
            cv.scrollRectToVisible(CGRect(x: contentOffset.x + cellSize.width, y: contentOffset.y, width: cellSize.width, height: cellSize.height), animated: true);
            
        }
        let flag = true // true if download succeed,false otherwise
        
        completionHandler(flag)
    }
    
    
    func loadingCell(){
        let height: CGFloat = 50.0
        self.viewActivityIndicator = UIView(frame: CGRect(x: self.view.frame.size.width/2 - 125, y: self.view.frame.size.height/2.0 - 50, width: 250, height:100))
        self.viewActivityIndicator.backgroundColor = UIColor(red: 38/255, green: 214/255, blue: 253/255, alpha: 0.3)
        self.viewActivityIndicator.layer.cornerRadius = 26
        self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: self.viewActivityIndicator.frame.size.width/2.0 - 90, y: self.viewActivityIndicator.frame.size.height/2.0 - 25, width: 50, height: height))
        self.activityIndicator.color = UIColor.white
        self.activityIndicator.hidesWhenStopped = false
        let titleLabel = UILabel(frame: CGRect(x: self.viewActivityIndicator.frame.size.width/2.0 - 50, y: self.viewActivityIndicator.frame.size.height/2.0 - 25, width: 200, height: 50))
        titleLabel.font = UIFont(name: "Avenir-Book", size: 34)
        titleLabel.text = "Loading..."
        titleLabel.textColor = UIColor.white
        self.viewActivityIndicator.addSubview(self.activityIndicator)
        self.viewActivityIndicator.addSubview(titleLabel)
        self.view.addSubview(self.viewActivityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    
}

extension UICollectionView {
    func indexPathForView(view: AnyObject) -> IndexPath? {
        let originInCollectioView = self.convert(CGPoint.zero, from: (view as! UIView))
        return self.indexPathForItem(at: originInCollectioView) as IndexPath?
    }
}

extension UICollectionView {
    
    var centerPoint : CGPoint {
        
        get {
            return CGPoint(x: self.center.x + self.contentOffset.x, y: self.center.y + self.contentOffset.y);
        }
    }
    
    var centerCellIndexPath: IndexPath? {
        
        if let centerIndexPath = self.indexPathForItem(at: self.centerPoint) {
            return centerIndexPath
        }
        return nil
    }
}

