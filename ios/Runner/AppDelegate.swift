import UIKit
import Flutter
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      let options: UNAuthorizationOptions = [.alert, .badge, .sound]

      UNUserNotificationCenter.current().requestAuthorization(
        options: options
      ) { granted, error in

        if let error = error {
          print("Push permission error: \(error)")
        }

        print("Push permission granted: \(granted)")
      }
    } else {
      let settings = UIUserNotificationSettings(
        types: [.alert, .badge, .sound],
        categories: nil
      )

      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.alert, .badge, .sound])
  }
}