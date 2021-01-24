//
//  MashAppInfoViewController.swift
//  MashApp
//
//  Created by Andro Mikulić on 03/08/2018.
//  Copyright © 2018 Rumpled Code. All rights reserved.
//

import UIKit

class MashAppInfoViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad();
        self.showAnimate();
    }
    @IBAction func OpenLink(_ sender: Any) {
        let link = URL(string : "https://www.mashapp.eu");
        UIApplication.shared.open(link!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil);
    }
    
    @IBAction func BackToApp(_ sender: Any) {
        removeAnimate();
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
