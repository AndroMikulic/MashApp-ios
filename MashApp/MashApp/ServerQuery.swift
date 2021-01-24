//
//  ServerQuery.swift
//  MashApp
//
//  Created by Andro Mikulić on 16/06/2018.
//  Copyright © 2018 Rumpled Code. All rights reserved.
//

import Foundation
import SwiftSocket

class ServerQuery {
    var threadHandler: DispatchQueue?;
    
    private var broadcastListenerAddress = "0.0.0.0";
    private var listenPort : Int32 = 1337;
    private var serverIP : String = "";
    
    private var IPTag : String = "MAIP:"
    private var curPlayingTag : String = "CURPL:";
    private var REQUEST_LIST : String = "LIST";
    private var REQUEST_SONG : String = "SONG:";
    private var IN_QUEUE_ERROR : String = "ERROR";
    private var SONG_ADDED : String = "ADDED";
    private var LUCK : String = "LUCK";
    private var socketTimeout = 1000;
    
    var blockRequests = false;
    var setupDone = false;
    var votesLeft = -1;
    
    
    var mainVC : ViewController!;
    public var songs = [String]();
    public var songDisplayNames = [String]();
    var currentlyPLaying : UILabel!;
    var botIcon : UIImageView!;
    var title : UILabel!;
    var songListView : UITableView!;
    var votesLeftLabel : UILabel!;
    
    public func SetUp(){
        print("Entered server setup");
        threadHandler = DispatchQueue.global();
        let udpSocket = UDPServer(address: broadcastListenerAddress, port: listenPort);
        threadHandler?.async {
            while(true){
                let (data, _, _) = udpSocket.recv(1024);
                let stringData : String = String(bytes : data!, encoding: .isoLatin1)!;
                if(!self.setupDone && stringData.starts(with: self.IPTag)){
                    self.setupDone = true;
                    let cnt = self.IPTag.count;
                    let fromIndex : String.Index = stringData.index(stringData.startIndex, offsetBy: cnt);
                    self.serverIP = String(stringData.suffix(from: fromIndex));
                    print(self.serverIP);
                    self.GetServerInformation();
                }
                if(self.setupDone && stringData.starts(with: self.curPlayingTag)){
                    let cnt = self.curPlayingTag.count;
                    let fromIndex : String.Index = stringData.index(stringData.startIndex, offsetBy: cnt);
                    DispatchQueue.main.async {
                        self.currentlyPLaying.alpha = 1.0;
                        self.botIcon.alpha = 1.0;
                        var temp = String(stringData.suffix(from: fromIndex));
                        if(temp.hasSuffix(".mp3") || temp.hasSuffix(".MP3")){
                            let endIndex = temp.index(temp.endIndex, offsetBy: -4);
                            temp = temp.substring(to: endIndex);
                        }
                        self.currentlyPLaying.text = temp;
                    }
                }
            }
        }
    }
    
    func GetServerInformation(){
        var data : String = "";
        let socket = TCPClient(address: serverIP, port: listenPort);
        switch socket.connect(timeout: 30){
        case .success:
            switch socket.send(string: REQUEST_LIST){
            case .success:
                while(true){
                    let readByte = socket.read(1, timeout: 5);
                    if(readByte == nil){
                        break;
                    }
                    let temp : String = String(bytes: readByte!, encoding: .isoLatin1)!;
                    data.append(temp);
                }
            case .failure(let error):
                print(error);
            }
        case .failure(let error):
            print(error);
        }
        socket.close();
        songs = data.components(separatedBy: "\n");
        print(songs);
        songDisplayNames = data.components(separatedBy: "\n");
        
        DispatchQueue.main.sync {
            self.title.text?.append(" - " + String(self.songs[0]));
        }
        songs.remove(at: 0);
        songDisplayNames.remove(at: 0);
        var i = 0;
        for song in songDisplayNames{
            if(song.hasSuffix(".mp3") || song.hasSuffix(".MP3")){
                let endIndex = song.index(song.endIndex, offsetBy: -4);
                songDisplayNames[i] = song.substring(to: endIndex);
            }else{
                songDisplayNames[i] = song;
            }
            i += 1;
        }
        DispatchQueue.main.async {
            self.songListView.reloadData();
            self.songListView.alpha = 1.0;
            self.mainVC.searchBar.isEnabled = true;
        }
    }
    
    func RequestSong(requestedSong : String){
        blockRequests = true;
        if(votesLeft <= 0){
            OutOfVotes();
            return;
        }
        var data : String = "";
        threadHandler?.async {
            let socket = TCPClient(address: self.serverIP, port: self.listenPort);
            switch socket.connect(timeout: 30){
            case .success:
                switch socket.send(string: self.REQUEST_SONG + requestedSong){
                case .success:
                    while(true){
                        let readByte = socket.read(1, timeout: 5);
                        if(readByte == nil){
                            break;
                        }
                        let temp : String = String(bytes: readByte!, encoding: .utf8)!;
                        data.append(temp);
                    }
                case .failure(let error):
                    print(error);
                }
            case .failure(let error):
                print(error);
            }
            let returnMsg : String = String(data);
            if(returnMsg.starts(with: self.SONG_ADDED)){
                if(returnMsg.contains(self.LUCK)){
                    self.LuckySongAdded();
                }
                else{
                    self.SongAdded();
                }
            }
            else if(returnMsg == self.IN_QUEUE_ERROR){
                self.SongInQueue();
            }
            self.blockRequests = false;
        }
    }
    
    func DeductVotePoint(){
        votesLeft = votesLeft - 1;
        DispatchQueue.main.async {
            self.votesLeftLabel.text = String(self.votesLeft);
        }
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
                voteData.append(String(votesLeft));
                voteData.append("_");
                voteData.append(dateFormatter.string(from: Date()));
                try voteData.write(toFile: filePath, atomically: false, encoding: .utf8);
            }catch{
                print("Failed to write to Vote File");
            }
        }
    }
    
    func SongAdded(){
        self.DeductVotePoint();
        DispatchQueue.main.async {
            self.songListView.alpha = 0.1;
            let popupMessage = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "songAddedVC") as! SongAddedViewController;
            self.mainVC.addChild(popupMessage);
            popupMessage.songListView = self.songListView;
            popupMessage.view.frame = self.mainVC.view.frame;
            self.mainVC.view.addSubview(popupMessage.view);
            popupMessage.didMove(toParent: self.mainVC);
        }
    }
    
    func LuckySongAdded(){
        DispatchQueue.main.async {
            self.songListView.alpha = 0.1;
            let popupMessage = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "luckSongAddedVC") as! LuckSongAddedViewController;
            self.mainVC.addChild(popupMessage);
            popupMessage.songListView = self.songListView;
            popupMessage.view.frame = self.mainVC.view.frame;
            self.mainVC.view.addSubview(popupMessage.view);
            popupMessage.didMove(toParent: self.mainVC);
        }
    }
    
    func SongInQueue(){
        DispatchQueue.main.async {
            self.songListView.alpha = 0.1;
            let popupMessage = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "songInQueueVC") as! SongInQueueViewController;
            self.mainVC.addChild(popupMessage);
            popupMessage.songListView = self.songListView;
            popupMessage.view.frame = self.mainVC.view.frame;
            self.mainVC.view.addSubview(popupMessage.view);
            popupMessage.didMove(toParent: self.mainVC);
        }
    }
    
    func OutOfVotes(){
        DispatchQueue.main.async {
            self.songListView.alpha = 0.1;
            let outOfVotesPopup = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "outOfVotesVC") as! OutOfVotesViewController;
            self.mainVC.addChild(outOfVotesPopup);
            outOfVotesPopup.songListView = self.songListView;
            outOfVotesPopup.view.frame = self.mainVC.view.frame;
            outOfVotesPopup.mainVC = self.mainVC;
            self.mainVC.view.addSubview(outOfVotesPopup.view);
            outOfVotesPopup.didMove(toParent: self.mainVC);
        }
        self.blockRequests = false;
    }
}
