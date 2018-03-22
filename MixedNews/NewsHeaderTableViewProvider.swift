//
//  NewsHeaderTableViewProvider.swift
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

enum NewsType: RawRepresentable {

    case all
    case news(onlyStar: Bool)
    case announcement(onlyStar: Bool)

    enum Error: Swift.Error {
        case notIncludeOnlyStarFilter
    }

    var rawValue: Int {
        switch self {
        case .all:
            return 0
        case let .news(onlyStar):
            return onlyStar ? 4 : 1
        case let .announcement(onlyStar):
            return onlyStar ? 3 : 2
        }
    }

    init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .all
        case 1:
            self = .news(onlyStar: false)
        case 2:
            self = .announcement(onlyStar: false)
        case 3:
            self = .announcement(onlyStar: true)
        case 4:
            self = .news(onlyStar: true)
        default:
            return nil
        }
    }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .news:
            return "自选股新闻"
        case .announcement:
            return "自选股公告"
        }
    }

    var starTitle: String? {
        switch self {
        case .all:
            return nil
        case .news:
            return "只看星标新闻"
        case .announcement:
            return "只看业绩公告"
        }
    }

    var showOnlyStar: Bool {
        switch self {
        case .all:
            return false
        case .news, .announcement:
            return true
        }
    }

    var isOnlyShowStar: Bool {
        switch self {
        case let .news(onlyStar) where onlyStar,
             let .announcement(onlyStar) where onlyStar:
            return true
        default:
            return false
        }
    }

    func invertingStarStatus() throws -> NewsType {
        switch self {
        case let .news(onlyStar):
            return .news(onlyStar: !onlyStar)
        case let .announcement(onlyStar):
            return .announcement(onlyStar: !onlyStar)
        case .all:
            throw Error.notIncludeOnlyStarFilter
        }
    }

}

public func topNavigationController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UINavigationController? {
    if let presented = base?.presentedViewController {
        return topNavigationController(presented)
    } else if let nav = base as? UINavigationController {
        return nav
    } else if let nav = base?.navigationController {
        return nav
    } else {
        return nil
    }
}

class NewsHeaderTableViewProvider: UniqueCustomTableViewSectionProvider {

    let filterButton = UIButton()
    let startFilterbutton = UIButton()

    let currentSelectedNewsType = BehaviorSubject<NewsType>(value: .all)

    let expandFilterButtonActivityIndicator = ActivityIndicator()

    let disposeBag = DisposeBag()

    required init() {
        super.init(tableElementKindSection: .header)
        self.sectionHeight = { _ in 40 }
        self.contentView.backgroundColor = UIColor.white

        self.currentSelectedNewsType.asObservable()
            .map {
                NSAttributedString(string: $0.title, attributes: [
                    NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)
                    ])
            }
            .bind(to: filterButton.rx.attributedTitle())
            .disposed(by: disposeBag)

        self.currentSelectedNewsType.asObservable()
            .map { !$0.showOnlyStar }
            .bind(to: startFilterbutton.rx.isHidden)
            .disposed(by: disposeBag)

        self.currentSelectedNewsType.asObservable()
            .map { $0.starTitle }
            .bind(to: startFilterbutton.rx.title())
            .disposed(by: disposeBag)

        self.currentSelectedNewsType.asObservable()
            .map { $0.isOnlyShowStar }
            .bind(to: startFilterbutton.rx.isSelected)
            .disposed(by: disposeBag)

        expandFilterButtonActivityIndicator.asObservable()
            .skip(1)
            .subscribe(onNext: { [unowned self] isExpanded in
                let toTransform = isExpanded ? CATransform3DMakeRotation(.pi, 0, 0, 1) : CATransform3DIdentity
//                let fromTransform = isExpanded ? CATransform3DIdentity : CATransform3DMakeRotation(.pi, 0, 0, 1)
//                let nextTransform = isExpanded ? CGAffineTransform(rotationAngle: .pi) : CGAffineTransform.identity
//                UIView.animate(withDuration: 1, animations: {
//                    self.filterButton.imageView?.transform = nextTransform
//                })
                self.filterButton.imageView?.layer.transform = toTransform
//                let animation = CABasicAnimation(keyPath: "transform")
//                animation.fromValue = fromTransform
//                animation.toValue = toTransform
//                animation.duration = 0.3
//                self.filterButton.imageView?.layer.add(animation, forKey: nil)
            })
            .disposed(by: disposeBag)

        filterButton.setImage(#imageLiteral(resourceName: "icon_arrow_bottom"), for: .normal)
        filterButton.rx.setImagePosition(.right, spacing: 2, padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))

        self.contentView.addSubview(filterButton)
        filterButton.snp.makeConstraints { (make) in
            make.leading.top.bottom.equalTo(self.contentView)
        }

        filterButton.rx.tap.asObservable()
            .flatMap { [unowned self] () -> Observable<NewsType> in
                return Observable<NewsType>
                    .create { observer in
                        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

                        [NewsType.all, NewsType.news(onlyStar: false), NewsType.announcement(onlyStar: false)]
                            .map { type in
                                UIAlertAction(title: type.title, style: .default, handler: { _ in
                                    observer.onNext(type)
                                    observer.onCompleted()
                                })
                            }
                            .forEach(alertController.addAction)

                        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { _ in
                            observer.onCompleted()
                        }))

                        topNavigationController()?.present(alertController, animated: true, completion: nil)
                        return Disposables.create {
                            alertController.dismiss(animated: true, completion: nil)
                        }
                    }
                    .trackActivity(self.expandFilterButtonActivityIndicator)
            }
            .bind(to: self.currentSelectedNewsType)
            .disposed(by: disposeBag)

        startFilterbutton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        startFilterbutton.setImage(#imageLiteral(resourceName: "icon_uncheck"), for: .normal)
        startFilterbutton.setImage(#imageLiteral(resourceName: "icon_checked"), for: .selected)
        startFilterbutton.setTitleColor(#colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1), for: .normal)
        startFilterbutton.setTitleColor(#colorLiteral(red: 0.3568627451, green: 0.4666666667, blue: 0.7450980392, alpha: 1), for: .selected)
        startFilterbutton.rx.setImagePosition(.left, spacing: 2, padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))

        startFilterbutton.rx.tap.asObservable()
            .withLatestFrom(self.currentSelectedNewsType.asObservable())
            .map { try $0.invertingStarStatus() }
            .bind(to: self.currentSelectedNewsType)
            .disposed(by: disposeBag)

        self.contentView.addSubview(startFilterbutton)
        startFilterbutton.snp.makeConstraints { (make) in
            make.trailing.top.bottom.equalTo(self.contentView)
        }

        let bottomLineView = UIView()
        bottomLineView.backgroundColor = #colorLiteral(red: 0.9098039216, green: 0.9098039216, blue: 0.9098039216, alpha: 1)
        self.contentView.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalTo(self.contentView)
            make.height.equalTo(0.5)
        }
    }

}
