//
//  MainViewController.swift
//  SCPageViewController
//
//  Created by Stefan Ceriu on 12/6/15.
//  Copyright © 2015 Stefan Ceriu. All rights reserved.
//

import UIKit

protocol MainViewControllerDelegate {
    func mainViewControllerDidChangeLayouterType(mainViewController: MainViewController)
}

enum PageLayouterType : Int {
    case Plain, Sliding, Parallax, Cards
}

class MainViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet var pickerView:UIPickerView!
    
    var delegate:MainViewControllerDelegate?
    var layouterType:PageLayouterType? {
        didSet {
            pickerView.selectRow(layouterType!.rawValue, inComponent: 0, animated: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 4
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        let layouterType = PageLayouterType.init(rawValue: row)!
        switch(layouterType) {
        case .Plain:
            return "Plain"
        case .Sliding:
            return "Sliding"
        case .Parallax:
            return "Parallax"
        case .Cards:
            return "Cards"
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        layouterType = PageLayouterType.init(rawValue: row)!
        delegate?.mainViewControllerDidChangeLayouterType(self)
    }
}
