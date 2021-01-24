//
//  ViewController.swift
//  MashApp
//
//  Created by Andro Mikulić on 12/06/2018.
//  Copyright © 2018 Rumpled Code. All rights reserved.
//

import UIKit
import GoogleMobileAds

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GADRewardBasedVideoAdDelegate{
    
    @IBOutlet weak var searchIcon: UIImageView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet var topIcon: UIImageView!
    @IBOutlet var botIcon: UIImageView!
    @IBOutlet var songListView: UITableView!
    @IBOutlet weak var currentlyPlaying: UILabel!
    @IBOutlet weak var votesLeftLabel: UILabel!
    @IBOutlet var placeTitle: UILabel!
    var serverQuery : ServerQuery!;
    
    public var filteredIndexes = [Int]();
    
    let VOTE_REFRESH_INTERVAL = 2; //in hours
    var MAXIMUM_VOTE_COUNT = 3;
    var voteTimeStamp : Date!;
    
    let ADMOB_APP_ID = "ca-app-pub-2846368323100628~5573244123";
    //REAL
    let ADMOB_ADU_ID = "ca-app-pub-2846368323100628/8471704357";
    
    //TEST
    //let ADMOB_ADU_ID = "ca-app-pub-3940256099942544/1712485313";
    
    var videoAdCaller : OutOfVotesViewController!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        songListView.dataSource = self;
        songListView.delegate = self;
        serverQuery = ServerQuery();
        SetUpVideoRewards();
        LoadVoteFile();
        ServerConnectionSetup();
        let curPlayingTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.ShowCurrentlyPlayingView));
        currentlyPlaying.isUserInteractionEnabled = true;
        currentlyPlaying.addGestureRecognizer(curPlayingTap);
        let appInfoTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.ShowMashAppInfoView));
        topIcon.isUserInteractionEnabled = true;
        topIcon.addGestureRecognizer(appInfoTap);
    }
    
    func LoadVoteFile(){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("v.dat") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                do{
                    let votefileString = try String(contentsOfFile: filePath);
                    let voteData = votefileString.components(separatedBy: "_");
                    let voteCount = Int(voteData[0]);
                    let dateFormatter = ISO8601DateFormatter();
                    let voteTime = dateFormatter.date(from: voteData[1]);
                    voteTimeStamp = voteTime;
                    if(voteCount! > MAXIMUM_VOTE_COUNT || voteCount! < 0){
                        serverQuery.votesLeft = MAXIMUM_VOTE_COUNT;
                    } else {
                        serverQuery.votesLeft = voteCount!;
                    }
                    let currentTime = Date();
                    let timeDifference = currentTime.timeIntervalSince(voteTime!);
                    let hourDifference = timeDifference / 3600;
                    if(hourDifference >= Double(VOTE_REFRESH_INTERVAL)){
                        serverQuery.votesLeft = MAXIMUM_VOTE_COUNT;
                    }
                    votesLeftLabel.text = String(serverQuery.votesLeft);
                }catch{
                    print("Error reading file");
                }
            } else {
                SetMaximumVotePoints();
            }
        } else {
            print("FILE PATH NOT AVAILABLE")
        }
        VoteUpdaterSetup();
    }
    
    func ServerConnectionSetup(){
        serverQuery.mainVC = self;
        serverQuery.currentlyPLaying = self.currentlyPlaying;
        serverQuery.botIcon = self.botIcon;
        serverQuery.title = self.placeTitle;
        serverQuery.songListView = self.songListView;
        serverQuery.votesLeftLabel = self.votesLeftLabel;
        serverQuery.SetUp();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serverQuery.songs.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath);
        cell.textLabel?.font = UIFont(name: "Dosis-Medium", size: 16.0);
        cell.textLabel?.font = cell.textLabel?.font.withSize(16.0);
        cell.textLabel?.textColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0);
        cell.textLabel?.numberOfLines = 2;
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping;
        cell.textLabel?.text = serverQuery.songDisplayNames[indexPath.item];
        return cell;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (filteredIndexes.contains(indexPath.item)) {
            return 0
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSong = serverQuery.songs[indexPath.item];
        tableView.deselectRow(at: indexPath, animated: true);
        if(!serverQuery.blockRequests){
            serverQuery.RequestSong(requestedSong: selectedSong);
        }
    }
    
    @objc func ShowCurrentlyPlayingView(sender:UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.songListView.alpha = 0.1;
            let popupMessage = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "playingVC") as! CurrentlyPlayingInfoViewController;
            self.addChild(popupMessage);
            popupMessage.songListView = self.songListView;
            popupMessage.view.frame = self.view.frame;
            popupMessage.songLabel.text = self.currentlyPlaying.text;
            self.view.addSubview(popupMessage.view);
            popupMessage.didMove(toParent: self);
        }
    }
    
    @IBAction func SearchChanged(_ sender: Any) {
        filteredIndexes.removeAll();
        if(searchBar.text! == ""){
            songListView.reloadData();
            return;
        }
        var i = 0;
        for song in serverQuery.songDisplayNames{
            if(song.lowercased().range(of: searchBar.text!.lowercased()) == nil){
                filteredIndexes.append(i);
            }
            i += 1;
        }
        songListView.reloadData();
    }
    
    @objc func ShowMashAppInfoView(sender:UITapGestureRecognizer) {
        DispatchQueue.main.async {
            let popupMessage = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "appInfoVC") as! MashAppInfoViewController;
            self.addChild(popupMessage);
            popupMessage.view.frame = self.view.frame;
            self.view.addSubview(popupMessage.view);
            popupMessage.didMove(toParent: self);
        }
    }
    
    func SetUpVideoRewards(){
        let request = GADRequest();
        //request.testDevices = [ kGADSimulatorID ];
        GADRewardBasedVideoAd.sharedInstance().delegate = self;
        DispatchQueue.main.async {
            GADRewardBasedVideoAd.sharedInstance().load(request, withAdUnitID:self.ADMOB_ADU_ID);
        }
    }
    
    public func ShowRewardVideo(caller : OutOfVotesViewController){
        self.videoAdCaller = caller;
        if GADRewardBasedVideoAd.sharedInstance().isReady == true {
            GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
        }
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
                            didRewardUserWith reward: GADAdReward) {
        GADRewardBasedVideoAd.sharedInstance().load(GADRequest(), withAdUnitID:ADMOB_ADU_ID);
        SetMaximumVotePoints();
        videoAdCaller.removeAnimate();
        print("Rewarded");
    }
    
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd:GADRewardBasedVideoAd) {
        print("Reward based video ad is received.")
    }
    
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("Opened reward based video ad.")
    }
    
    func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("Reward based video ad started playing.")
    }
    
    func rewardBasedVideoAdDidCompletePlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("Reward based video ad has completed.")
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        videoAdCaller.removeAnimate();
        GADRewardBasedVideoAd.sharedInstance().load(GADRequest(), withAdUnitID:ADMOB_ADU_ID);
        print("Reward based video ad is closed.")
    }
    
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("Reward based video ad will leave application.")
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
                            didFailToLoadWithError error: Error) {
        print("Reward based video ad failed to load.")
        GADRewardBasedVideoAd.sharedInstance().load(GADRequest(), withAdUnitID:ADMOB_ADU_ID);
    }
    
    func SetMaximumVotePoints(){
        print("Setting maximum vote points");
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("v.dat") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                do{
                    try fileManager.removeItem(atPath: filePath);
                }catch{
                    print("Vote File found BUT failed to remove");
                }
            }
            do{
                let dateFormatter = ISO8601DateFormatter();
                var voteData : String = "";
                voteData.append("3_");
                voteData.append(dateFormatter.string(from: Date()));
                try voteData.write(toFile: filePath, atomically: false, encoding: .utf8);
                serverQuery.votesLeft = 3;
                votesLeftLabel.text = "3";
            }catch{
                print("Failed to write to Vote File");
            }
        }
    }
    
    func VoteUpdaterSetup(){
        Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.CheckForVoteTime), userInfo: nil, repeats: true);
    }
    
    @objc func CheckForVoteTime(){
        let currentTime = Date();
        let timeDifference = currentTime.timeIntervalSince(voteTimeStamp!);
        let hourDifference = timeDifference / 3600;
        if(hourDifference >= Double(VOTE_REFRESH_INTERVAL)){
            SetMaximumVotePoints();
        }
        
    }
}
