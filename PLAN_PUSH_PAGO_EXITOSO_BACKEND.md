# Encargo: push de "pago exitoso" tras un cobro de Adquira

> **Para el agente que trabaja en el repositorio del backend de ArjiPagos.**
> Redactado el 2026-08-25 desde el lado de la app móvil.

---

## Alcance — léelo antes de tocar nada

**Lo que te toca a ti:** que el backend mande una notificación push cuando un pago por Adquira se
confirma, con el contenido y el formato exactos de la sección 4.

**Lo que NO te toca:** la aplicación Flutter. La app tiene su propio repositorio y otra persona
se encarga de la mitad que navega a la pantalla del ticket. **No busques ni modifiques código
Flutter**, y no te bloquees si un nombre de este documento no aparece en tu proyecto: los
nombres de clases y pantallas que se mencionan son de la app y están aquí solo como contexto.

**Tu entregable es:** el push sale, con el payload correcto, en el momento correcto, una sola
vez por pago, y sin romper el flujo de pagos que ya funciona.

---

## Paso 0 — Casi todo lo que necesitas ya existe

Se echó un vistazo a tu repositorio antes de escribir esto. **No hay que construir el envío de
push desde cero**, y sería un error hacerlo: ya tienes la infraestructura y una convención
asentada. Verifica estos puntos y reutiliza lo que hay.

| Lo que ya existe | Para qué te sirve |
| --- | --- |
| `app/Services/Notificaciones/PushNotificationService.php` | El emisor. Ya tiene `enviarAlUsuario()`, `enviarAFamilia()`, y métodos por campaña: `notificarVencido()`, `notificarFacturaEnviada()`, `notificarBannerPublicado()` |
| `app/Jobs/Banners/EnviarPushBanner.php` | **El molde a copiar.** Job con `backoff()` de 1/5/15 min y comprobaciones antes de enviar |
| `EstadosCuentaAPIController::pagoRealizadoAdquira`, ruta `/pago-realizado` | El punto donde hoy se cierra el pago de Adquira |
| Tabla de dispositivos, vía `NotificacionController@registrarDispositivo` | Los tokens FCM del tutor |

**El camino natural** —y el que menos riesgo trae— es:

1. Añadir un método `notificarPagoExitoso(...)` a `PushNotificationService`, en la misma línea
   que `notificarBannerPublicado()`.
2. Despachar un job al estilo de `EnviarPushBanner`, para que un fallo de FCM no bloquee ni
   tumbe la respuesta del cobro (ver sección 7).
3. Llamarlo desde donde se confirma el pago.

### Las dos preguntas que siguen abiertas

Contéstalas leyendo el código y dilas en tu primer mensaje, **antes** de implementar:

1. **¿Adquira ofrece una notificación servidor-a-servidor, aparte de `/pago-realizado`?**

   Es la pregunta importante. El comentario de esa ruta dice que el callback llega *"GET o POST
   desde el navegador (web) / POST desde la app móvil"* — o sea, **depende del dispositivo del
   usuario**, no es un webhook puro entre servidores. Si el usuario cierra el navegador o pierde
   la red justo después de pagar, ese callback puede no llegar nunca… que es exactamente el
   escenario donde el push más falta hace.

   - Si Adquira **sí** ofrece aviso servidor-a-servidor: engancha ahí el envío. Es lo correcto.
   - Si **no** lo ofrece: engancha en `pagoRealizadoAdquira` y **dilo claramente**, porque
     entonces la función tiene un límite conocido —si no vuelve el callback, no hay push— y hay
     que decidir si se complementa con una tarea que reconcilie pagos pendientes de confirmar.

   **No lo des por hecho en ningún sentido: compruébalo en la documentación de Adquira o en la
   configuración del comercio.**

2. **¿El ticket ya existe en el momento en que se cierra el pago?** Si se genera con retraso, el
   push tiene que esperar: mandarlo antes llevaría al usuario a un pago sin ticket que ver.

---

## 1. Cuándo se manda el push

**Cuando el backend confirma el cobro con Adquira. NO cuando la app vuelve del WebView.**

Es la diferencia entre que la función sirva siempre o casi nunca. El retorno del WebView depende
de que el usuario no cierre la aplicación, no pierda la red y complete la redirección — y el caso
en que el push más se agradece es justo ese: el usuario pagó, se le cayó el internet, y quiere
saber si su pago se aplicó.

El punto exacto donde engancharlo es el mismo sitio donde hoy marcas el pago como aplicado y
generas el ticket.

---

## 2. A quién se le manda

A **todos los tokens FCM del tutor** dueño de esos pagos.

Ya tienes la tabla: es la que alimenta `POST /api/v1/dispositivo/registrar` y limpia
`POST /api/v1/dispositivo/eliminar`. Un tutor puede tener varios dispositivos (teléfono y
tablet); se manda a todos.

**Higiene obligatoria:** si FCM responde `UNREGISTERED` o `INVALID_ARGUMENT` para un token,
**bórralo** de la tabla. Es un dispositivo donde la app ya no está instalada, y arrastrarlo hace
que cada envío falle para siempre.

---

## 3. Cómo saber a qué alumno corresponde el pago

La app arma la `referencia` que se manda a Adquira concatenando los ids de los pagos con una `D`:

```
5358D5359D5360
```

Cada número es un `estado_de_cuenta.id`, y cada estado de cuenta cuelga de un alumno. De ahí
resuelves el alumno.

### El caso que hay que contemplar

El carrito de la app **permite pagar a dos alumnos distintos en una sola operación**, así que una
misma referencia puede mezclar alumnos. Regla:

| Situación | Qué mandar |
| --- | --- |
| Todos los pagos son del mismo alumno | `alumno_id` con ese alumno, y su nombre en el texto |
| La referencia mezcla varios alumnos | **Omite `alumno_id`** por completo y redacta el texto en plural |

**No inventes un alumno "principal"** cuando hay varios. La app usa ese dato para desplazarse
hasta la ficha del alumno; con un valor equivocado llevaría al usuario al alumno que no es, y eso
es peor que no llevarlo a ninguno. Si `alumno_id` no viene, la app simplemente abre la pantalla
de Pagos Realizados sin desplazarse, que es el comportamiento correcto.

---

## 4. El payload exacto

Hay que mandar **`notification` y `data` a la vez**. No es redundancia:

- Sin `notification`, **iOS no muestra ningún globo** (un mensaje solo-datos no se despliega).
- Con `notification`, Android lo muestra solo, y la app sabe no pintar una notificación local
  encima. Si mandas solo datos, la pinta ella. Cualquiera de las dos vías funciona, pero mandar
  ambas cosas es lo que cubre iOS y Android sin duplicados.
- `data` es lo único que sobrevive al toque del usuario, y es de donde la app lee a dónde navegar.

```json
{
  "message": {
    "token": "<token FCM del dispositivo>",

    "notification": {
      "title": "¡Pago recibido!",
      "body": "Tu pago de $9,770.00 de LEAH se aplicó correctamente. Toca para ver tu ticket."
    },

    "data": {
      "campania":     "pago",
      "accion":       "pago_exitoso",
      "alumno_id":    "1234",
      "ciclo_id":     "2026",
      "pago_ids":     "5358,5359,5360",
      "ticket_folio": "T7773",
      "referencia":   "5358D5359D5360",
      "title":        "¡Pago recibido!",
      "message":      "Tu pago de $9,770.00 de LEAH se aplicó correctamente."
    },

    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "arjipagos_notif",
        "sound": "notif_sound"
      }
    },

    "apns": {
      "headers": { "apns-priority": "10" },
      "payload": { "aps": { "sound": "default", "badge": 1 } }
    }
  }
}
```

### Reglas del payload — ninguna es opcional

| Regla | Por qué |
| --- | --- |
| **Todos los valores de `data` son STRING** | FCM rechaza el mensaje completo si mandas un número o un booleano. `"alumno_id": 1234` falla; `"alumno_id": "1234"` no. Es el error nº 1 en este tipo de integración |
| **`campania` = `"pago"`, `accion` = `"pago_exitoso"`** | La app **ya usa esta convención** para otra campaña: los banners llegan con `campania: "banner"` y `accion: "refrescar_banners"`, y cada pantalla solo reacciona a lo suyo. Si te sales de la convención, el push acabará atendido por la pantalla equivocada |
| **`channel_id` = `arjipagos_notif`** | Es el canal que la app crea en Android, con sonido propio e importancia alta. Con cualquier otro valor, Android cae al canal por omisión y el aviso sale mudo y sin prioridad |
| **`title` y `message` también dentro de `data`** | La app da prioridad al contenido de `data` sobre el de `notification`. Si el texto solo viaja en `notification`, el registro que queda dentro de la app puede quedarse en blanco |
| **NO mandes `ticket_url`** | Es una URL con datos del pago, y el push viaja por los servidores de Google. La app ya recibe esa URL por su API autenticada; con `alumno_id` le sobra para encontrar el ticket |
| **Nada de HTML en `notification.body`** | Se muestra crudo, con las etiquetas a la vista. En `data.message` sí se tolera, porque la app le quita el marcado antes de mostrarlo |

---

## 5. Reglas de negocio

### 5.1 Una sola notificación por pago

Adquira puede repetir la confirmación: reintentos, doble entrega, reenvíos manuales. **Tiene que
haber idempotencia.**

Sugerencia: una columna `notificado_at` en el registro del pago, o una tabla con la `referencia`
como clave única. Antes de enviar, comprueba; después de enviar, marca.

Sin esto, al usuario le llegan tres avisos por un solo pago y lo primero que piensa es que le
cobraron tres veces. Es de los pocos fallos de esta función que generan una llamada al colegio.

### 5.2 Solo pagos exitosos

Nada de push para pagos rechazados, pendientes, en revisión o cancelados. Este canal es
únicamente para confirmar que el dinero se aplicó. Los fallos ya se le muestran al usuario en la
pantalla del navegador de pago.

### 5.3 Que quede también en la lista de Notificaciones

La app tiene una pantalla de Notificaciones con contador de no leídas, y tu backend ya la
alimenta (`NotificacionController`). Crea ahí el registro además de mandar el push, igual que
hacen las demás campañas. Así el aviso se puede consultar después y el contador cuadra. Sin eso,
el push es un globo que desaparece en cuanto el usuario lo descarta.

### 5.4 El texto

Que diga **el importe y el nombre del alumno**:

- Bien: *"Tu pago de $9,770.00 de LEAH se aplicó correctamente."*
- Mal: *"Pago procesado"* — no le dice nada a quien tiene tres hijos en el colegio.
- Varios alumnos: *"Tu pago de $19,540.00 se aplicó correctamente."*

---

## 6. Contexto: qué hará la app con esto

**Esto NO lo implementas tú.** Está aquí para que entiendas por qué el payload es como es.

Al recibir el push, la app abrirá la pantalla de **Pagos Realizados** y se desplazará hasta la
ficha del alumno indicado en `alumno_id`, donde el usuario verá su pago con un botón para abrir
el ticket. Si `alumno_id` no viene, abre la pantalla sin desplazarse.

Esa mitad está pendiente en el repositorio de la app y la hace otra persona. **Las dos mitades son
independientes:** puedes implementar y probar la tuya sin esperar a nadie.

---

## 7. Lo que NO se puede romper

El flujo de pago actual **tiene que seguir funcionando exactamente igual** para quien no reciba el
push, y son muchos casos reales: usuario que denegó el permiso de notificaciones, sin red en ese
momento, token de FCM caducado, o iOS con las notificaciones desactivadas para la app.

Regla práctica: **el push es un atajo, nunca el único camino al ticket.** Si el envío falla, se
registra en el log y el pago sigue su curso con normalidad. Un error mandando la notificación
**jamás** debe hacer fallar la transacción ni la respuesta al cliente — envuélvelo de forma que
no pueda tumbar el proceso de cobro.

---

## 8. Resumen de tareas

| # | Qué | Prioridad |
| --- | --- | --- |
| 0 | Responder las dos preguntas abiertas del paso 0 | **Primero** |
| 1 | Enganchar el envío a la confirmación del cobro, reutilizando `PushNotificationService` y un job al estilo de `EnviarPushBanner` | Bloqueante |
| 2 | Resolver el alumno desde los ids de la `referencia`; omitirlo si hay varios | Bloqueante |
| 3 | Enviar a todos los tokens FCM del tutor y borrar los que FCM rechace | Bloqueante |
| 4 | Payload de la sección 4, con `data` **todo en string** | Bloqueante |
| 5 | `campania: "pago"` + `accion: "pago_exitoso"` | Bloqueante |
| 6 | El envío no puede tumbar la transacción si falla | Bloqueante |
| 7 | Idempotencia: una notificación por `referencia` | Alta |
| 8 | `channel_id: "arjipagos_notif"` | Alta |
| 9 | Solo pagos exitosos | Alta |
| 10 | Registrar también en la lista de notificaciones | Media |
| 11 | Texto con importe y nombre del alumno | Media |

---

## 9. Cómo comprobar que quedó bien

1. Un pago real de prueba con **un solo alumno** → llega un push, con el importe y el nombre
   correctos, y `data.alumno_id` es el de ese alumno.
2. Un pago con **dos alumnos** → llega un push, el texto va en plural y **`alumno_id` no viene**.
3. **Reenviar dos veces la confirmación de Adquira** → llega **un solo** push.
4. Un pago **rechazado** → no llega ningún push.
5. Un usuario con **dos dispositivos** → llega a los dos.
6. Un token **inválido a propósito** → el envío falla para ese token, el token se borra de la
   tabla, y el pago se completa igualmente sin error para el usuario.
7. Verifica en el JSON enviado que **todos** los valores de `data` son cadenas de texto.
