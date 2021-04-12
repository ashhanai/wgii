class ViewModel: Activable {
    private var hasBeenActive = false
    var isActive = false {
        didSet {
            if isActive {
                if !hasBeenActive { didBecomeActiveFirstTime() }
                didBecomeActive()
                hasBeenActive = true
            } else {
                didBecomeInactive()
            }
        }
    }

    func didBecomeActive() {}
    func didBecomeActiveFirstTime() {}
    func didBecomeInactive() {}
}

protocol Activable: AnyObject {
    var isActive: Bool { get set }
}

