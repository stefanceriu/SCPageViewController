//
//  RootViewController.swift
//  SCPageViewController
//
//  Created by Stefan Ceriu on 10/14/15.
//  Copyright © 2015 Stefan Ceriu. All rights reserved.
//

import Foundation

class RootViewController : UIViewController , SCPageViewControllerDataSource, SCPageViewControllerDelegate, MainViewControllerDelegate {
    
    var pageViewController : SCPageViewController = SCPageViewController()
    var viewControllers = [UIViewController?]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        for(var i = 0 ; i<5; i++) {
            viewControllers.append(nil);
            
        }
        
        self.pageViewController.setLayouter(SCPageLayouter(), animated: false, completion: nil)
        self.pageViewController.easingFunction = SCEasingFunction(type: SCEasingFunctionType.Linear)
        
        //self.pageViewController.scrollView.maximumNumberOfTouches = 1;
        //self.pageViewController.scrollView.panGestureRecognizer.minimumNumberOfTouches = 2;
        
        self.pageViewController.dataSource = self;
        self.pageViewController.delegate = self;

        self.addChildViewController(self.pageViewController)
        self.pageViewController.view.frame = self.view.bounds
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
    }
    
    //MARK: - SCPageViewControllerDataSource
    
    func numberOfPagesInPageViewController(pageViewController: SCPageViewController!) -> UInt {
        return UInt(self.viewControllers.count)
    }
    
    func pageViewController(pageViewController: SCPageViewController!, viewControllerForPageAtIndex pageIndex: UInt) -> UIViewController! {

        
        if let viewController = self.viewControllers[Int(pageIndex)] {
            return viewController
        } else {
            let viewController = MainViewController()
            viewController.delegate = self;
            
            func randomColor () -> UIColor {
                let hue = CGFloat(arc4random() % 256) / 256.0;  //  0.0 to 1.0
                let saturation = (CGFloat(arc4random() % 128) / 256.0 ) + 0.5  //  0.5 to 1.0, away from white
                let brightness = (CGFloat(arc4random() % 128) / 256.0 ) + 0.5  //  0.5 to 1.0, away from black
                
                return UIColor.init(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0);
            }
            
            viewController.view.backgroundColor = randomColor()
            viewController.view.frame = self.view.bounds;
            self.viewControllers[Int(pageIndex)] = viewController
            return viewController
        }
    }
    
    //MARK: - SCPageViewControllerDelegate
    
    func pageViewController(pageViewController: SCPageViewController!, didNavigateToOffset offset: CGPoint) {
        
        func layouterToType(layouter: SCPageLayouterProtocol) -> PageLayouterType {
            switch layouter {
            case is SCSlidingPageLayouter:
                return PageLayouterType.Sliding
            case is SCParallaxPageLayouter:
                return PageLayouterType.Parallax
            case is SCCardsPageLayouter:
                return PageLayouterType.Cards
            default:
                return PageLayouterType.Plain
            }
        }
        
        let layouterType = layouterToType(self.pageViewController.layouter!);
        
        for optionalValue in self.viewControllers {
            if(optionalValue != nil) {
                let viewController = optionalValue as! MainViewController
                viewController.layouterType = layouterType;
            }
            
        }
    }
    
    //MARK: - MainViewControllerDelegate
    
    func mainViewControllerDidChangeLayouterType(mainViewController: MainViewController) {
        switch(mainViewController.layouterType!) {
        case .Plain:
            self.pageViewController.setLayouter(SCPageLayouter(), animated: false, completion: nil)
        case .Sliding:
            self.pageViewController.setLayouter(SCSlidingPageLayouter(), animated: true, completion: nil)
        case .Parallax:
            self.pageViewController.setLayouter(SCParallaxPageLayouter(), animated: true, completion: nil)
        case .Cards:
            self.pageViewController.setLayouter(SCCardsPageLayouter(), animated: true, completion: nil)
        }
    }
}