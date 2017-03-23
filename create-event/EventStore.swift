import Foundation
import EventKit

private let _SingletonSharedInstance = EventStore()

class EventStore {
    let eventStore = EKEventStore()
    public var calendars = [EKCalendar]()
    
    class var instance : EventStore {
        return _SingletonSharedInstance
    }
    
    var defaultCalendarId: String {
        get {
            var cid = UserDefaults.standard.string(forKey: "default-calendar-id")
            if cid == nil {
                cid = eventStore.defaultCalendarForNewEvents.calendarIdentifier
                UserDefaults.standard.set(cid, forKey: "default-calendar-id")
            }
            return cid!
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "default-calendar-id")
            UserDefaults.standard.synchronize()
        }
    }
    
    init() {
        if !requestAccess() {
            print("ACCESS - ACCESS LONG")
            let sharedWorkspace = NSWorkspace.shared()
            sharedWorkspace.openFile("/Applications/System Preferences.app")
            exit(0)
        }
        
        refreshCalendars()
    }
    
    func requestAccess() -> Bool {
        let sema = DispatchSemaphore(value: 0)
        var hasAccess = false
        
        eventStore.requestAccess(to: .event,
                                 completion: { (granted:Bool, error:Error?) in
                                    hasAccess = granted
                                    sema.signal()
        })
        _ = sema.wait(timeout: .distantFuture)
        return hasAccess
    }
    
    public func refreshCalendars() {
        calendars = eventStore.calendars(for: .event)
        var order = [String]()
        for c in calendars {
            order.append(c.calendarIdentifier)
        }
        calendars.sort(by: { (a: EKCalendar, b: EKCalendar) -> Bool in
            if a.source.title == b.source.title {
                return order.index(of: a.calendarIdentifier)! > order.index(of: b.calendarIdentifier)!
            } else {
                return a.source.sourceIdentifier > b.source.sourceIdentifier
            }
        })
    }
    
    public func createEvent(title: String, date: Date, calendar: EKCalendar) -> Bool {
        // create all day event
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = title
        newEvent.calendar = calendar
        newEvent.isAllDay = true
        newEvent.startDate = date
        newEvent.endDate = date
        
        // alarm at 10 AM
        if newEvent.alarms != nil {
            for a in newEvent.alarms! {
                newEvent.removeAlarm(a)
            }
        }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let alarmDate = Calendar.current.date(byAdding: .hour, value: 10, to: startOfDay)!
        let alarm = EKAlarm(absoluteDate: alarmDate)
        newEvent.addAlarm(alarm)
        
        do {
            try eventStore.save(newEvent, span: .futureEvents, commit: true)
            return true
        } catch {
            return false
        }
    }
}

