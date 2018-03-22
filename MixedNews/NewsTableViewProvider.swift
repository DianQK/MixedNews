//
//  NewsTableViewProvider.swift
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

extension Reactive where Base: Session {

    public static func send<Request: APIKit.Request>(_ request: Request) -> Observable<Request.Response> {
        return Observable.create({ (observer) -> Disposable in
            let task = Session.send(request) { (result) in
                switch result {
                case let .success(response):
                    observer.onNext(response)
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            }
            return Disposables.create {
                task?.cancel()
            }
        })
    }

}

extension Session: ReactiveCompatible {}

struct News: StringIdentifiableType, Equatable, Codable {

    var identity: String {
        return self.id
    }

    static func ==(lhs: News, rhs: News) -> Bool {
        return lhs.id == rhs.id
            && lhs.order_id == rhs.order_id
            && lhs.code == rhs.code
            && lhs.name == rhs.name
            && lhs.price_str == rhs.price_str
            && lhs.change_rate_str == rhs.change_rate_str
            && lhs.stock_type == rhs.stock_type
            && lhs.state == rhs.state
            && lhs.type == rhs.type
            && lhs.title == rhs.title
            && lhs.media == rhs.media
            && lhs.pub_date == rhs.pub_date
            && lhs.end_date == rhs.end_date
//            && lhs.url == rhs.url
//            && lhs.offline_url == rhs.offline_url
    }


    let id: String
    let order_id: String
    let code: String
    let name: String
    let price_str: String
    let change_rate_str: String
    let stock_type: Int
    let state: String
    let type: String
    let title: String
    let media: String
    let pub_date: Date
    let end_date: Date
//    let url: URL?
//    let offline_url: URL?

}

public struct DataNoParser: DataParser {

    public var contentType: String? { return nil }

    public func parse(data: Data) throws -> Any {
        return data
    }
}

struct MixedNewsRequest: APIKit.Request {

    var baseURL: URL {
        return URL(string: "https://stock.snssdk.com/v2")!
    }

    var method: HTTPMethod { return .get }

    var path: String { return "/portfolios/mixed_news" }

    var dataParser: DataParser { return DataNoParser() }

    var queryParameters: [String : Any]? {
        return [
            "device_id": 50008157890,
            "limit": 20,
            "os": "iOS",
            "filter": filter.rawValue
        ]
    }

    let filter: NewsType

    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> [News] {
        let object = object as! Data
        let result = try mixedNewsJSONDecoder.decode(MixedNewsResponse<[News]>.self, from: object)
        return result.data
    }

    typealias Response = [News]

}

struct MixedNewsResponse<Data: Codable>: Codable {
    let data: Data
}

public let mixedNewsJSONDecoder: JSONDecoder = {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.secondsSince1970
    return jsonDecoder
}()

class MyNewsTableViewCell: UITableViewCell {

    let titleLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = #colorLiteral(red: 0.1333333333, green: 0.1333333333, blue: 0.1333333333, alpha: 1)

        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(contentView).offset(16)
            make.top.equalTo(contentView).offset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class NewsTableViewProvider: AnimatableTableViewProvider {

    func configureCell(_ tableView: UITableView, cell: MyNewsTableViewCell, indexPath: IndexPath, value: News) {
        cell.titleLabel.text = value.title
    }

    func genteralValues() -> Observable<[News]> {
        return self.filter
            .flatMapLatest { Session.rx.send(MixedNewsRequest(filter: $0)) }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath, value: News) -> CGFloat? {
        return 72
    }

    let filter: Observable<NewsType>

    init(filter: Observable<NewsType>) {
        self.filter = filter
    }

    typealias Cell = MyNewsTableViewCell
    typealias Value = News

}
