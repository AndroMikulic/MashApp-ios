//
//  LuckSongAddedViewController.swift
//  MashApp
//
//  Created by Andro Mikulić on 30/07/2018.
//  Copyright © 2018 Rumpled Code. All rights reserved.
//
import UIKit

class LuckSongAddedViewController: UIViewController {
    
    public var songListView : UITableView!;
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showAnimate();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        songListView.alpha = 1.0;
        self.removeAnimate();
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
    
    func removeAnimate()
    {
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
