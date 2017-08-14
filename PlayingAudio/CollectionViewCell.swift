//
//  CollectionViewCell.swift
//  PlayingAudio
//
//  Created by Karim El Sheikh on 8/11/17.
//  Copyright © 2017 playing. All rights reserved.
//

import UIKit
import AVFoundation
import HGCircularSlider
import MediaPlayer

private var playerViewControllerKVOContext = 0

protocol CustomCellDelegate {
    func closeView(_ cell:CollectionViewCell)
    func closeViewAutoPlay(_ cell:CollectionViewCell)
    func removeLoading(_ cell:CollectionViewCell)
    func stopLoading(_ cell:CollectionViewCell)
}

class CollectionViewCell: UICollectionViewCell {
    var delegate: CustomCellDelegate?
    var timer = Timer()
    var playtouch: Bool = false
    
    let SHADOW_GRAY: CGFloat = 120.0 / 255.0
    let WHITE: CGFloat = 255.0 / 255.0
    
    var _timeObserver:Any?
    
    var player = AVPlayer()
    var playerItem:AVPlayerItem?
    let priority = DispatchQueue.global()
    
    var theName: String = ""
    let mpic = MPRemoteCommandCenter.shared()
    
    let mpicArt = MPNowPlayingInfoCenter.default()
    
    
    typealias CompletionHandler = (_ success:Bool) -> Void
    
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var playImage: UIButton!
    @IBOutlet weak var scrubber: UISlider!
    @IBOutlet weak var countdownLbl: UILabel!
    @IBOutlet weak var closeBtnView: UIButton!
    @IBOutlet weak var updateLbl: UILabel!
    @IBOutlet weak var nextLbl: UILabel!
    
    @IBOutlet weak var playImagePreDisplay: UIImageView!
    @IBOutlet weak var cellMainViewBg: UIView!
    
    @IBOutlet weak var closeBtnHeight: NSLayoutConstraint!
    
    
    @IBAction func closeBtn(_ sender: Any) {
        print(player.rate)
        player.replaceCurrentItem(with: nil)
        print("closed")
        print(player.rate)
        if let delegate = self.delegate {
            delegate.closeViewAutoPlay(self)
        }
        if player.rate != 0 {
            print("IM PAUSING")
            player.pause()
            playImage.setImage(#imageLiteral(resourceName: "play"), for: UIControlState.normal)
        }
        
        player.seek(to: kCMTimeZero)
        
        
        if (_timeObserver != nil) {
            player.removeTimeObserver(_timeObserver!)
            _timeObserver = nil
        }
    }
    
    func nextUpdate(){
        let now = Date()
        let calendar = Calendar.current
        
        let formatterTimeTxt = DateFormatter()
        formatterTimeTxt.dateFormat = "ha"
        formatterTimeTxt.amSymbol = "am"
        formatterTimeTxt.pmSymbol = "pm"
        let currentHour = formatterTimeTxt.string(from: now)
        
        
        let hour = calendar.component(.hour, from: now)
        
        let components = DateComponents(calendar: calendar, hour: hour + 1)  // <- 17:00 = 5pm
        let next5pm = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!
        let diff = calendar.dateComponents([.minute], from: now, to: next5pm)
        let minutesLeft = Int(diff.minute!)
        if minutesLeft < 30 {
            
            print("\(minutesLeft) minutes till next update")
            nextLbl.text = "\(minutesLeft) minutes till next update"
        } else if(minutesLeft == 30){
            print("Last update at \(currentHour)")
            nextLbl.text = "\(minutesLeft) minutes till next update"
        }else {
            print("Last update at \(currentHour)")
            nextLbl.text = "Next update in \(minutesLeft) minutes"
        }
        updateLbl.text = "Updated at \(currentHour)"
    }
    
    @IBAction func play(_ sender: Any) {
        if player.rate == 0
        {

            player.play()
            playImage.setImage(#imageLiteral(resourceName: "pause"), for: UIControlState.normal)
            
            
        } else {
            player.pause()
            playImage.setImage(#imageLiteral(resourceName: "play"), for: UIControlState.normal)
        }
        
        
    }
    
    
    func audioPlay(){
        if player.timeControlStatus == .playing {
            player.pause()
            playImage.setImage(#imageLiteral(resourceName: "play"), for: UIControlState.normal)
        } else if player.timeControlStatus == .paused {
            print("LOADING")
            player.play()
            playImage.setImage(#imageLiteral(resourceName: "pause"), for: UIControlState.normal)
        }
        
        
    }
    
    
    @IBAction func scrubberMoved(_ sender: UISlider) {
        let seconds : Int64 = Int64(scrubber.value)
        let targetTime:CMTime = CMTimeMake(seconds, 1)
        
        player.seek(to: targetTime)
        
        if player.rate == 0
        {
            player.play()
        }
        
    }
    
    
    func liveAudioStreamSelected(audioUrl: String, live: Bool){
        
        if let streamer = URL(string: audioUrl){
            let playerItem:AVPlayerItem = AVPlayerItem(url: streamer)
            player = AVPlayer(playerItem: playerItem)
            
            scrubber!.isContinuous = true
            scrubber?.addTarget(self, action: #selector(CollectionViewCell.scrubberMoved(_:)), for: .valueChanged)
            
            player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, 1), queue: DispatchQueue.main) { (CMTime) -> Void in
                if self.player.currentItem?.status == .readyToPlay {
                    let time : Float64 = CMTimeGetSeconds(self.player.currentTime());
                    self.scrubber!.value = Float ( time );
                }
            }
            
        }
        
        
        
    }
    
    
    func getFormatedTime(FromTime timeDuration:Int) -> String {
        let minutes = Int(timeDuration) / 60 % 60
        let seconds = Int(timeDuration) % 60
        let strDuration = String(format:"%02d:%02d", minutes, seconds)
        return strDuration
    }
    ///add Obsever in NotificationCenter for AVPlayerItemDidPlayToEndTime
    func addObserverForPlayerEnd(){
        NotificationCenter.default.addObserver(self,selector: #selector(playerItemDidReachEnd(_:)),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        nextUpdate()
        cellMainViewBg.layer.cornerRadius = 20.0
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print("dfdfdfdfdfdffdfffff")
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print("dfdfdfdfdfdfd44444444fdffdfffff")
            print(error.localizedDescription)
        }
    }
    
    
    func setupNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        mpic.skipBackwardCommand.isEnabled = false
        mpic.seekBackwardCommand.isEnabled = false
        
        mpic.playCommand.addTarget {event in
            self.player.play()
            self.setupNowPlayingInfoCenter()
            return .success
        }
        mpic.pauseCommand.addTarget {event in
            self.player.pause()
            return .success
        }
        mpic.nextTrackCommand.addTarget {event in
            return .success
        }
        mpic.previousTrackCommand.addTarget {event in
            return .success
        }
        
    }
    
    
    func updateNowPlayingInfoCenter(name: String? = nil) {
        
        if let stationName = name {
            mpicArt.nowPlayingInfo = [MPMediaItemPropertyTitle : "\(stationName)" as AnyObject]
        }
        
        
    }
    
    
    func bind(color: String) {
        cellMainViewBg.backgroundColor = color.hexColor
    }
    
    
    override func prepareForReuse() {
        contentView.backgroundColor = UIColor.clear
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 3.0
        layer.cornerRadius = 10.0
    }
    

    
    let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()
    
    func updatePlayerUI(withCurrentTime currentTime: CGFloat) {
        var components = DateComponents()
        components.second = Int(currentTime)
        countdownLbl.text = dateComponentsFormatter.string(from: components)
    }
    
    func updateTimer() {
        let components = DateComponents()

        countdownLbl.text = dateComponentsFormatter.string(from: components)
    }
    
    
    func playerItemDidReachEnd(_ notification: Notification) {
        if let _: AVPlayerItem = notification.object as? AVPlayerItem {
            print("AUDIO FINISHED")
            player.replaceCurrentItem(with: nil)
            if let delegate = self.delegate {
                delegate.closeView(self)
            }
            player.pause()
            player.seek(to: kCMTimeZero)
            playImage.setImage(#imageLiteral(resourceName: "play"), for: UIControlState.normal)
            
            if (_timeObserver != nil) {
                player.removeTimeObserver(_timeObserver!)
                _timeObserver = nil
            }
            
            
            
        }
    }
    
    func audioStreamSelected(audioUrl: String, live: Bool, completionHandler: @escaping CompletionHandler){
        if let streamer = URL(string: audioUrl){
            
            let playerItem:AVPlayerItem = AVPlayerItem(url: streamer)
            self.player = AVPlayer(playerItem: playerItem)
            
            player.replaceCurrentItem(with: playerItem)
            player.actionAtItemEnd = .pause
            
            let duration : CMTime = playerItem.asset.duration
            let secondss : Float64 = CMTimeGetSeconds(duration)
            
            _ = CMTimeGetSeconds(duration)

            
            let interval = CMTimeMake(1, 4)
            
            self.scrubber.minimumValue = 0
            
            self.scrubber!.maximumValue = Float(secondss)
            self.scrubber!.isContinuous = false
            self.scrubber!.tintColor = UIColor(red: 38/255, green: 214/255, blue: 253/255, alpha: 1.0)
            self.countdownLbl.text = String(self.getFormatedTime(FromTime: Int(secondss)))
            
            self.scrubber?.addTarget(self, action: #selector(CollectionViewCell.scrubberMoved(_:)), for: .valueChanged)
            
            
            if (_timeObserver == nil) {
                _timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) {
                    [weak self] time in
                    
                    if self?.player.currentItem?.status == AVPlayerItemStatus.readyToPlay {
                        
                        if (self?.player.currentItem?.isPlaybackLikelyToKeepUp) != nil {
                            
                            if let delegate = self?.delegate {
                                delegate.removeLoading(self!)
                            }
                            
                            let seconds = CMTimeGetSeconds(time)
                            self?.updatePlayerUI(withCurrentTime: CGFloat(seconds))
                            
                            let times : Float64 = CMTimeGetSeconds(self!.player.currentTime());
                            self?.scrubber!.value = Float ( times );
                            let countdown = secondss - times
                            let countTime = self?.getFormatedTime(FromTime: Int(countdown))
                            self?.countdownLbl.text = String(describing: countTime!)
                            
                        }
                    }
                    
                    
                    
                    
                    
                }
            }
            let flag = true
            completionHandler(flag)
        }
        
    }
    
}


extension String {
    var hexColor: UIColor {
        let hex = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return .clear
        }
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        
    }
}
