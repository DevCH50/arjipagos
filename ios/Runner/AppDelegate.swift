import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    // Asignar delegate de UNUserNotificationCenter antes de registrar para APNS.
    // Requerido para recibir notificaciones en foreground y que FCM dispare onMessage.
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // El messenger sale del registrar de la aplicación, que es como lo hace la
    // plantilla oficial de Flutter para este delegate
    // (`dev/integration_tests/ios_add2app_uiscene`). El bridge no expone un
    // `binaryMessenger` directo.
    registrarCanalDeBadge(engineBridge.applicationRegistrar.messenger())
  }

  /// Canal para apagar el globo rojo del icono desde Dart (`BadgeIconoApp`).
  ///
  /// El backend manda `aps.badge` en el payload de APNs, así que iOS enciende el
  /// contador solo; bajarlo es cosa de la app y hasta el 2026-08-27 nadie lo
  /// hacía, de ahí que el globo se quedara puesto para siempre.
  ///
  /// Se registra a mano en vez de con un paquete de terceros porque los que hay
  /// están sin mantener y esto son cuatro líneas.
  private func registrarCanalDeBadge(_ messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(
      name: "mx.moriah.arjipagos/badge",
      binaryMessenger: messenger
    ).setMethodCallHandler { call, result in
      guard call.method == "fijar" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let cantidad = max(0, (call.arguments as? [String: Any])?["cantidad"] as? Int ?? 0)

      if #available(iOS 16.0, *) {
        // A partir de iOS 16 el contador se fija por el centro de
        // notificaciones; `applicationIconBadgeNumber` quedó obsoleto en 17.
        UNUserNotificationCenter.current().setBadgeCount(cantidad) { error in
          if let error = error {
            print("=== BADGE ERROR: \(error.localizedDescription)")
          }
        }
      } else {
        UIApplication.shared.applicationIconBadgeNumber = cantidad
      }
      result(nil)
    }
  }

  // Muestra notificaciones como banner cuando la app está en foreground
  // y garantiza que FCM dispare FirebaseMessaging.onMessage en Dart.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  // Maneja errores de registro APNS para diagnóstico.
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("=== APNS ERROR: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
