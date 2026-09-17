import Flutter
import UIKit
import FirebaseCore
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    // El delegate de UNUserNotificationCenter es el propio plugin de Firebase Messaging, no esta
    // clase. Es lo que pide su README para apps con UIScene: los plugins se registran DESPUÉS de
    // este método y Apple exige el delegate antes de que termine.
    //
    // NO volver a `UNUserNotificationCenter.current().delegate = self` con un `willPresent`
    // propio. El plugin ve que `self` es un `FlutterAppDelegate`, no se pone de delegate y confía
    // en que Flutter le reenvíe la llamada; un `willPresent` sobrescrito corta ese reenvío y
    // `FirebaseMessaging.onMessage` no llega nunca a Dart con la app abierta. Así estuvo hasta el
    // 2026-09-17: en iPhone el push de pago no refrescaba el estado de cuenta ni añadía el aviso.
    //
    // Cómo se presenta el banner en primer plano lo decide Dart con
    // `setForegroundNotificationPresentationOptions` (`FcmService.configurarHandlers`).
    FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()
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

  // Maneja errores de registro APNS para diagnóstico.
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("=== APNS ERROR: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
