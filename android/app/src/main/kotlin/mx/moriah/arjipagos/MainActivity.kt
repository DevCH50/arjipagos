package mx.moriah.arjipagos

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad única que hospeda el motor de Flutter.
 *
 * Lleva la guarda estándar contra el *launcher relaunch bug* de Android, que se
 * dispara cuando la app abre una aplicación ajena y el usuario regresa por el
 * icono del launcher:
 *
 *  1. Al abrir el ticket, el diálogo "Abrir con" (`ResolverActivity`) se apila
 *     DENTRO de nuestra tarea — comprobado en dispositivo: la tarea pasa de
 *     `sz=1` a `sz=2`. Ocurre porque `open_filex` y `share_plus` lanzan el
 *     intent sin `FLAG_ACTIVITY_NEW_TASK`.
 *  2. Si el usuario vuelve por el icono del launcher, Android entrega
 *     `MAIN/LAUNCHER` con `FLAG_ACTIVITY_RESET_TASK_IF_NEEDED`. Como
 *     `MainActivity` ya no está arriba, el `launchMode="singleTop"` del
 *     manifest no aplica y el sistema puede crear una SEGUNDA instancia.
 *  3. Instancia nueva = motor de Flutter nuevo = pila de navegación con una
 *     sola ruta. El atrás no tiene a dónde volver y cierra la app.
 *
 * La guarda descarta esa instancia nueva y deja viva la que ya tiene el estado
 * del usuario. Protege toda la app, no solo el ticket: el compartir de Facturas
 * y el WebView de pago tienen la misma exposición.
 *
 * ## Por qué `FlutterFragmentActivity` y no `FlutterActivity`
 *
 * El bloqueo biométrico (`local_auth`) muestra un `BiometricPrompt` de
 * androidx, y ese componente **exige una `FragmentActivity`** para poder
 * adjuntar su fragmento de diálogo. Con `FlutterActivity` a secas, la llamada
 * revienta en tiempo de ejecución.
 *
 * El cambio es solo la clase base: `isTaskRoot`, `intent` y el
 * `launchMode="singleTop"` del manifest se comportan exactamente igual, así que
 * la guarda de arriba sigue intacta. Aun así **hay que volver a probarla a mano**
 * después de tocar este archivo: abrir un ticket, aceptar el diálogo "Abrir con",
 * volver por el icono del launcher y comprobar que el atrás no cierra la app.
 *
 * ## Edge-to-edge (Android 15, SDK 35)
 *
 * Play Console avisa «Es posible que la vista de extremo a extremo no funcione
 * para todos los usuarios» mientras la app no llame a `enableEdgeToEdge()`
 * nativo. El `SystemChrome.setEnabledSystemUIMode(edgeToEdge)` de `main.dart`
 * hace lo mismo en la práctica, pero Play no lo ve: lo que revisa es la
 * `Activity`. Siguió saliendo en la 1.0.33+42 por eso.
 *
 * Antes no se podía: `FlutterActivity` extiende `android.app.Activity`, y
 * `enableEdgeToEdge()` es de `ComponentActivity`. Desde que la base es
 * `FlutterFragmentActivity` (que sí desciende de `ComponentActivity`), sí.
 *
 * Va **después** de `super.onCreate`: ahí dentro Flutter cambia del tema del
 * splash al normal, y tocar la ventana antes podría dejar ese cambio atrás.
 * Hay test guardián: `test/unit/edge_to_edge_android_test.dart`.
 */
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Se llama siempre primero: omitirlo lanza SuperNotCalledException.
        super.onCreate(savedInstanceState)

        val relanzadaDesdeElLauncher =
            intent.action == Intent.ACTION_MAIN &&
                intent.hasCategory(Intent.CATEGORY_LAUNCHER)

        // No somos la raíz de la tarea: ya existe una instancia con el estado
        // del usuario más abajo en la pila. Esta sobra.
        if (!isTaskRoot && relanzadaDesdeElLauncher) {
            finish()
            return
        }

        enableEdgeToEdge()
    }

    /**
     * Canal mínimo para que Dart conozca la versión de Android (`SDK_INT`).
     *
     * Lo necesita el bloqueo biométrico: por debajo de Android 11 (API 30),
     * androidx.biometric 1.1.0 pide el PIN del aparato con una pantalla aparte
     * que se abre **duplicada** (comprobado en el emulador de Android 7 el
     * 2026-11-18). Ver `ReglaBiometriaAndroid.dart`. Se usa este canal en vez
     * de añadir `device_info_plus` solo por un número.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_PLATAFORMA)
            .setMethodCallHandler { llamada, resultado ->
                if (llamada.method == "sdkInt") {
                    resultado.success(Build.VERSION.SDK_INT)
                } else {
                    resultado.notImplemented()
                }
            }
    }

    private companion object {
        const val CANAL_PLATAFORMA = "mx.moriah.arjipagos/plataforma"
    }
}
