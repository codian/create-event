import Cocoa
import EventKit

class ViewController: NSViewController {

    @IBOutlet weak var textFieldTitle: NSTextField!
    @IBOutlet weak var pickerDate: NSDatePicker!
    @IBOutlet weak var popupButtonCalendar: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textFieldTitle.delegate = self
        pickerDate.dateValue = Date()
        updatePopupButtonCalendar()
    }
    
    @IBAction func onCalendarChanged(_ sender: Any) {
        if let item = popupButtonCalendar.selectedItem {
            let cal = EventStore.instance.calendars[item.tag]
            print("selected = \(cal.calendarIdentifier)")
            EventStore.instance.defaultCalendarId = cal.calendarIdentifier
        }
    }
    
    func updatePopupButtonCalendar() {
        popupButtonCalendar.removeAllItems()
        
        let defaultId = EventStore.instance.defaultCalendarId
        
        var sourceId = ""
        var calIndex = 0
        var itemIndex = 0
        var defaultIndex = -1
        for c in EventStore.instance.calendars {
            if sourceId != "" && sourceId != c.source.sourceIdentifier {
                let sep = NSMenuItem.separator()
                popupButtonCalendar.menu?.addItem(sep)
                itemIndex += 1
            }
            sourceId = c.source.sourceIdentifier
            
            let lastIndex = popupButtonCalendar.menu!.numberOfItems
            popupButtonCalendar.addItem(withTitle: c.title)
            let menuItem = popupButtonCalendar.menu!.item(at: lastIndex)!
            menuItem.tag = calIndex
            
            if c.calendarIdentifier == defaultId {
                defaultIndex = itemIndex
            }
            
            calIndex += 1
            itemIndex += 1
        }
        
        if defaultIndex >= 0 {
            print("SELECT \(defaultIndex)")
            popupButtonCalendar.selectItem(at: defaultIndex)
        } else {
            print("SELECT first")
            popupButtonCalendar.selectItem(at: 0)
        }
    }
    
    @IBAction func onClickAddButton(_ sender: Any) {
        createEvent()
    }
    
    func createEvent() {
        let title = textFieldTitle.stringValue
        if title == "" {
            showFailToCreateEventAlert(reason: "title is empty")
            textFieldTitle.becomeFirstResponder()
            return
        }
        
        let date = pickerDate.dateValue
        
        var created = false
        let item = popupButtonCalendar.selectedItem
        if item != nil && !item!.isSeparatorItem {
            let cal = EventStore.instance.calendars[item!.tag]
            created = EventStore.instance.createEvent(title: title, date: date, calendar: cal)
            if created {
                exitApp()
            } else {
                showFailToCreateEventAlert(reason: "Fail to create event")
                return 
            }
        } else {
            showFailToCreateEventAlert(reason: "calendar not specified")
            return
        }
    }
    
    func showFailToCreateEventAlert(reason: String) {
        let alert = NSAlert()
        alert.messageText = "Cannot create event"
        alert.informativeText = reason
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .critical
        alert.runModal()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        // super.cancelOperation(sender)
        
        exitApp()
    }
    
    func exitApp() {
        let app = NSApplication.shared()
        app.terminate(self)
    }
}

extension ViewController : NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        var retval = false
        
        if (commandSelector == #selector(insertNewline)) {
            retval = true
            createEvent()
        }
        
        return retval
    }
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        
        createEvent()
    }
}

