//
//  MainViewController.swift
//  SCPageViewController
//
//  Created by Stefan Ceriu on 12/6/15.
//  Copyright © 2015 Stefan Ceriu. All rights reserved.
//

import UIKit

protocol MainViewControllerDelegate {
    func mainViewControllerDidChangeLayouterType(_ mainViewController: MainViewController)
}

enum PageLayouterType : Int {
    case plain, sliding, parallax, cards
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 4
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        let layouterType = PageLayouterType.init(rawValue: row)!
        switch(layouterType) {
        case .plain:
            return "Plain"
        case .sliding:
            return "Sliding"
        case .parallax:
            return "Parallax"
        case .cards:
            return "Cards"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        layouterType = PageLayouterType.init(rawValue: row)!
        delegate?.mainViewControllerDidChangeLayouterType(self)
    }
}
