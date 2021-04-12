import UIKit
import Firebase
import Swinject

@main
final class AppDelegate: UIResponder {
	var window: UIWindow?
    var assembler: Assembler!
}

extension AppDelegate: UIApplicationDelegate {
	func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()

        assembler = appAssembler()

        window = UIWindow()
        window?.rootViewController = assembler.resolver.resolve(GasPriceViewController.self)
        window?.makeKeyAndVisible()

        registerPushNotifications(for: application)

        return true
    }

    private func requestRemoteNotificationPermission() {
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    private func registerPushNotifications(for application: UIApplication) {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.alert, .badge])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard
            let deviceToken = fcmToken,
            let setDeviceToken = assembler.resolver.resolve(UserUseCase.SetDeviceToken.self)
        else { return }

        _ = setDeviceToken(deviceToken)
            .subscribe()
    }
}
