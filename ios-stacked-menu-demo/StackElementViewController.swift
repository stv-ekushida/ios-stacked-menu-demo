//
//  StackElementViewController.swift
//  ios-stacked-menu-demo
//
//  Created by Kushida　Eiji on 2017/05/18.
//  Copyright © 2017年 Kushida　Eiji. All rights reserved.
//

import UIKit

class StackElementViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!

    var headerString: String? {
        didSet {
            configureView()
        }
    }

    func configureView() {
        headerLabel.text = headerString
    }
}
