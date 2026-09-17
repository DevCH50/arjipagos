#import "GeneratedPluginRegistrant.h"

// `AppDelegate.swift` llama a `FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()`,
// así que Swift tiene que ver la cabecera del plugin.
//
// `<firebase_messaging/...>` es la ruta de CocoaPods. Con Swift Package Manager —que es como se
// integra Firebase aquí— esa ruta no existe y la cabecera solo se alcanza por el módulo Clang que
// genera el paquete. Se prueban las dos, igual que en el ejemplo oficial del plugin
// (`firebase_messaging/example/ios/Runner/Runner-Bridging-Header.h`).
#if __has_include(<firebase_messaging/FLTFirebaseMessagingPlugin.h>)
#import <firebase_messaging/FLTFirebaseMessagingPlugin.h>
#else
@import firebase_messaging;
#endif
