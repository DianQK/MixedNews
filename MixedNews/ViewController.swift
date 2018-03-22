//
//  ViewController.swift
//  MixedNews
//
//  Created by DianQK on 22/03/2018.
//  Copyright © 2018 DianQK. All rights reserved.
//

import UIKit
import SnapKit
import Flix
import RxSwift
import RxCocoa
import APIKit

class BottomTableViewProvider: UniqueCustomTableViewProvider {

    let titleLabel = UILabel()

    override init() {
        super.init()
        self.itemHeight = { _ in 44 }
        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.9490196078, alpha: 1)
        self.selectionStyle.accept(.none)

        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        self.titleLabel.textColor = #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        self.titleLabel.text = "已显示全部内容"

        self.contentView.addSubview(titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.center.equalTo(self.contentView)
        }
    }

}

class ViewController: UIViewController {

    let tableView = UITableView(frame: .zero, style: .plain)

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorInset = UIEdgeInsets.zero

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }

        let newsHeaderTableViewProvider = NewsHeaderTableViewProvider()
        let newsTableViewProvider = NewsTableViewProvider(filter: newsHeaderTableViewProvider.currentSelectedNewsType.asObservable())
        let bottomTableViewProvider = BottomTableViewProvider()

        self.tableView.flix.build([
            AnimatableTableViewSectionProvider(
                providers: [newsTableViewProvider, bottomTableViewProvider],
                headerProvider: newsHeaderTableViewProvider,
                footerProvider: nil)
            ])
    }

}

