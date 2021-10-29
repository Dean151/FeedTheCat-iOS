//
//  Models.swift
//  Aln
//
//  Created by Thomas Durand on 11/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import SwiftUI

public struct User: Codable {
    public struct Session: Codable, Equatable {
        public let domain: String
        public let expires: Date?
        public let secure: Bool
        public let name: String
        public let path: String
        public let value: String
        public let version: Int

        public init(cookie: HTTPCookie) {
            domain = cookie.domain
            expires = cookie.expiresDate
            secure = cookie.isSecure
            name = cookie.name
            path = cookie.path
            value = cookie.value
            version = cookie.version
        }

        public var cookie: HTTPCookie? {
            return HTTPCookie(properties: [
                .domain: domain,
                .expires: expires as Any,
                .secure: secure,
                .name: name,
                .path: path,
                .value: value,
                .version: version
            ])
        }
    }

    public let id: Int
    public var email: String?
    public var feeders: [Feeder]

    public let register: Date?
    public var login: Date?

    public init(id: Int, email: String? = nil, feeders: [Feeder] = [], register: Date? = nil, login: Date? = nil) {
        self.id = id
        self.email = email
        self.feeders = feeders
        self.register = register
        self.login = login
    }
}

public class Feeder: Codable, ObservableObject {
    public let id: Int
    public var name: String? {
        willSet {
            objectWillChange.send()
        }
    }
    public var defaultAmount: Int? {
        willSet {
            objectWillChange.send()
        }
    }

    public init(id: Int, name: String? = nil, defaultAmount: Int? = nil) {
        self.id = id
        self.name = name
        self.defaultAmount = defaultAmount
    }
}

extension Feeder: Identifiable {}

/// A collection of ScheduleMeal ; for setting a new cat feeding plan.
/// Will behave mostly like an Array ; but not exactly
public struct ScheduledFeedingPlan: Codable {
    public static let maxNumberOfMeals = 10

    enum Errors: Error {
        case tooManyMeals
        case mealNotFound
        case alreadyExistentMeal
    }

    var meals: [ScheduledMeal]

    public static let empty = ScheduledFeedingPlan(meals: [])
    public static let testData = ScheduledFeedingPlan(meals: [
        ScheduledMeal(
            amount: try! Amount(value: 10),
            time: Time(hours: try! Hours(value: 6), minutes: try! Minutes(value: 0))
        ),
        ScheduledMeal(
            amount: try! Amount(value: 25),
            time: Time(hours: try! Hours(value: 12), minutes: try! Minutes(value: 30))
        )
    ])
}

/// Array like behaviors
extension ScheduledFeedingPlan: MutableCollection {
    public subscript(index: Int) -> ScheduledMeal {
        get {
            return meals[index]
        }
        set {
            meals[index] = newValue
        }
    }

    public subscript(safely index: Int) -> ScheduledMeal? {
        get {
            guard index >= 0 && index < meals.count else { return nil }
            return meals[index]
        }
        set {
            guard let newValue = newValue else { return }
            meals[index] = newValue
        }
    }

    public var count: Int {
        meals.count
    }

    public var countEnabled: Int {
        meals.filter({ $0.isEnabled }).count
    }

    public var amount: Int {
        meals.filter({ $0.isEnabled }).reduce(0, { $0 + $1.amount.value })
    }

    func index(of meal: ScheduledMeal) -> Int? {
        return meals.firstIndex(where: { $0.id == meal.id })
    }

    mutating public func add(_ meal: ScheduledMeal) throws {
        guard index(of: meal) == nil else {
            throw Errors.alreadyExistentMeal
        }
        meals.append(meal)
    }

    mutating public func remove(atOffsets offsets: IndexSet) {
        meals.remove(atOffsets: offsets)
    }
}

extension ScheduledFeedingPlan: RandomAccessCollection {
    public var startIndex: Int {
        meals.startIndex
    }

    public var endIndex: Int {
        meals.endIndex
    }

    public func makeIterator() -> IndexingIterator<[ScheduledMeal]> {
        meals.makeIterator()
    }

    public var underestimatedCount: Int {
        meals.underestimatedCount
    }

    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<ScheduledMeal>) throws -> R) rethrows -> R? {
        try meals.withContiguousStorageIfAvailable(body)
    }
}

/// A recurring meal, or a past meal
public struct ScheduledMeal: Codable, Equatable, Comparable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case amount = "quantity"
        case time = "time"
        case isEnabled = "enabled"
    }

    public let id = UUID()
    public var amount: Amount
    public var time: Time
    public var isEnabled: Bool

    public init(amount: Amount, time: Time, enabled: Bool = true) {
        self.amount = amount
        self.time = time
        self.isEnabled = enabled
    }

    public init(amount: Amount, date: Date, enabled: Bool) throws {
        let time = try Time(date: date)
        self.init(amount: amount, time: time, enabled: enabled)
    }

    public static func == (lhs: ScheduledMeal, rhs: ScheduledMeal) -> Bool {
        return lhs.time == rhs.time && lhs.amount == rhs.amount
    }

    public static func < (lhs: ScheduledMeal, rhs: ScheduledMeal) -> Bool {
        if lhs.time == rhs.time {
            return lhs.amount < rhs.amount
        }
        return lhs.time < rhs.time
    }
}

/// A one-shot meal, used to trigger
public struct Meal: Codable {
    enum CodingKeys: String, CodingKey {
        case amount = "quantity"
    }

    public let amount: Amount

    public init(amount: Amount) {
        self.amount = amount
    }
}

/// Declares a Hours/Minutes structure for meals. Since the machine does not change it's timezone, neither are those
/// The time MUST in the UTC timezone to be compliant with the machine's own timezone
public struct Time: Codable, Comparable {

    public var hours: Hours
    public var minutes: Minutes

    public init(hours: Hours, minutes: Minutes) {
        self.hours = hours
        self.minutes = minutes
    }

    public init(date: Date) throws {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hours: try Hours(value: components.hour ?? 0), minutes: try Minutes(value: components.minute ?? 0))
    }

    public var date: Date {
        get {
            // Create a date using Calendar components
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())

            // Set the time correctly
            components.hour = self.hours.value
            components.minute = self.minutes.value
            components.second = 0
            components.timeZone = TimeZone(identifier: "GMT")

            return Calendar.current.date(from: components)!
        }
        set {
            let date = Date(timeInterval: Double(-TimeZone.current.secondsFromGMT(for: newValue)), since: newValue)
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            self.hours = try! Hours(value: components.hour!)
            self.minutes = try! Minutes(value: components.minute!)
        }
    }

    public static func < (lhs: Time, rhs: Time) -> Bool {
        if lhs.hours == rhs.hours {
            return lhs.minutes < rhs.minutes
        }
        return lhs.hours < rhs.hours
    }
}

/// Bounds for hours (0-23)
public struct HoursBounds: IntegerBounds {
    public static let inboundMin = 0
    public static let outboundMax = 24
}

/// Bounds for minutes (0-59)
public struct MinutesBounds: IntegerBounds {
    public static let inboundMin = 0
    public static let outboundMax = 60
}

/// Bounds for amount (5-150)
public struct AmountBounds: IntegerBounds {
    public static let inboundMin = 5
    public static let outboundMax = 151
}

public typealias Hours = BoundedInteger<HoursBounds>
public typealias Minutes = BoundedInteger<MinutesBounds>
public typealias Amount = BoundedInteger<AmountBounds>

extension Amount {
    var kilogramsValue: Double {
        Double(value) / 1000
    }
}

/// A protocol that defines lower & upper bounds for an integer
public protocol IntegerBounds {
    static var inboundMin: Int { get }
    static var outboundMax: Int { get }
}

/// Define a structure for handling bounded integers. Requires bounds object to make it work.
public struct BoundedInteger<T: IntegerBounds>: Codable, Comparable {

    enum Errors: Error {
        case OutOfBounds
    }

    private var _value: Int
    public var value: Int {
        get {
            _value
        }
        set {
            _value = Swift.min(Self.max, Swift.max(Self.min, newValue))
        }
    }

    public init(value: Int) throws {
        guard value >= T.inboundMin && value < T.outboundMax else {
            throw Errors.OutOfBounds
        }

        self._value = value
    }

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(value: value)
    }

    public func encode(to encoder: Encoder) throws {
        var singleValue = encoder.singleValueContainer()
        try singleValue.encode(value)
    }

    public static func < (lhs: BoundedInteger, rhs: BoundedInteger) -> Bool {
        return lhs.value < rhs.value
    }

    public static var min: Int {
        return T.inboundMin
    }

    public static var max: Int {
        return T.outboundMax - 1
    }
}
