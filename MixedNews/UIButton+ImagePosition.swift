//
//  UIButton+ImagePosition.swift
//  MixedNews
//
//  Created by DianQK on 22/03/2018.
//  Copyright © 2018 DianQK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension UIButton {

    public enum ImagePosition {
        case left
        case right
        case top
        case bottom
    }

}

extension Reactive where Base: UIButton {

    public func setImagePosition(_ imagePosition: UIButton.ImagePosition, spacing: CGFloat, padding: UIEdgeInsets = .zero) {
        _ = self.methodInvoked(#selector(UIButton.layoutSubviews))
            .observeOn(MainScheduler.asyncInstance)
            .takeUntil(self.deallocated)
            .subscribe(onNext: { [weak button = self.base] _ in
                guard let `button` = button, let titleLabel = button.titleLabel, let imageView = button.imageView else {
                    return
                }

                let labelWidth = titleLabel.frame.width
                let labelHeight = titleLabel.frame.height
                let imageWidth = imageView.frame.width
                let imageHeight = imageView.frame.height

                let imageOffsetX = labelWidth / 2
                let imageOffsetY = labelHeight / 2 + spacing / 2
                let labelOffsetX = imageWidth / 2
                let labelOffsetY = imageHeight / 2 + spacing / 2

                switch imagePosition {
                case .left:
                    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
                    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
                    button.contentEdgeInsets = UIEdgeInsets(top: padding.top, left: padding.left + spacing / 2, bottom: padding.bottom, right: padding.right + spacing / 2)
                case .right:
                    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth + spacing/2, bottom: 0, right: -(labelWidth + spacing/2))
                    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageWidth + spacing/2), bottom: 0, right: imageWidth + spacing/2)
                    button.contentEdgeInsets = UIEdgeInsets(top: padding.top, left: padding.left + spacing / 2, bottom: padding.bottom, right: padding.right + spacing / 2)
                case .top:
                    button.imageEdgeInsets = UIEdgeInsets(top: -imageOffsetY, left: imageOffsetX, bottom: imageOffsetY, right: -imageOffsetX)
                    button.titleEdgeInsets = UIEdgeInsets(top: labelOffsetY, left: -labelOffsetX, bottom: -labelOffsetY, right: labelOffsetX)
                    button.contentEdgeInsets = UIEdgeInsets(top: padding.top + spacing / 2, left: padding.left, bottom: padding.bottom + spacing / 2, right: padding.right)
                case .bottom:
                    button.imageEdgeInsets = UIEdgeInsets(top: imageOffsetY, left: imageOffsetX, bottom: -imageOffsetY, right: -imageOffsetX)
                    button.titleEdgeInsets = UIEdgeInsets(top: -labelOffsetY, left: -labelOffsetX, bottom: labelOffsetY, right: labelOffsetX)
                    button.contentEdgeInsets = UIEdgeInsets(top: padding.top + spacing / 2, left: padding.left, bottom: padding.bottom + spacing / 2, right: padding.right)
                }
            })


    }

}
