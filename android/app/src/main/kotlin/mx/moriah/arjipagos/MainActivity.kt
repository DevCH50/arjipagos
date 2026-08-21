package mx.moriah.arjipagos

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

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
 */
class MainActivity : FlutterActivity() {

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
        }
    }
}
