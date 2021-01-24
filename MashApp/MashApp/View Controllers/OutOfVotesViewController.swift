//
//  OutOfVotesViewController.swift
//  MashApp
//
//  Created by Andro Mikulić on 02/08/2018.
//  Copyright © 2018 Rumpled Code. All rights reserved.
//

import UIKit

class OutOfVotesViewController: UIViewController {
    
    public var songListView : UITableView!;
    public var mainVC : ViewController!;
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showAnimate();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.removeAnimate();
    }
    @IBAction func WatchRewardVideo(_ sender: Any) {
        mainVC.ShowRewardVideo(caller : self);
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
