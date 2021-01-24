//
//  CurrentlyPlayingInfoViewController.swift
//  MashApp
//
//  Created by Andro Mikulić on 02/08/2018.
//  Copyright © 2018 Rumpled Code. All rights reserved.
//

import UIKit

class CurrentlyPlayingInfoViewController: UIViewController {
    
    @IBOutlet var shareButton: UIButton!
    @IBOutlet var statusText: UILabel!
    @IBOutlet public var songLabel: UILabel!
    public var songListView : UITableView!;
    public var mainVC : ViewController!;
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showAnimate();
        let tap = UITapGestureRecognizer(target: self, action: #selector(CurrentlyPlayingInfoViewController.CopySongToClipboard));
        songLabel.isUserInteractionEnabled = true;
        songLabel.addGestureRecognizer(tap);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(touches.first?.view != songLabel){
            self.removeAnimate();
        }
    }
    
    @objc func CopySongToClipboard(){
        UIPasteboard.general.string = songLabel.text;
        statusText.text = "Copied!";
    }
    
    @IBAction func ShareSong(_ sender: Any) {
        if var top = self.view?.window?.rootViewController {
            while let presentedViewController = top.presentedViewController {
                top = presentedViewController
            }
            let activityVC = UIActivityViewController(activityItems: [songLabel.text ?? "MashApp is AWSOME!"], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = view
            top.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func showAnimate()
    {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
    }
    
    public func removeAnimate()
    {
        songListView.alpha = 1.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0;
        }, completion:{(finished : Bool)  in
            if (finished)
            {
                self.view.removeFromSuperview()
            }
        });
    }
    
}

