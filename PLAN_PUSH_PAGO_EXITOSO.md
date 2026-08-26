# Push de "pago exitoso" que lleva al ticket

> Redactado el 2026-08-25. Nada de esto está implementado todavía.
>
> **Objetivo:** cuando un pago por Adquira se confirma, al tutor le llega una notificación
> diciendo que el pago fue exitoso, y al tocarla la app lo lleva a **Pagos Realizados**, al
> alumno que corresponde, para que vea su ticket.

---

## 0. Lo primero: esto tiene dos mitades, y una es de la app

El backend **solo** puede mandar el push. Que el toque lleve a Pagos Realizados es trabajo de la
app, y hoy **no existe**.

Peor: hoy la app hace lo contrario de lo que queremos. `NotificacionBloc` escucha
`onMessageOpenedApp` **sin filtrar nada** y navega a la pantalla de Notificaciones ante
*cualquier* toque:

```dart
.listen((_) {
  add(const NotificacionAbiertaDesdeBackgroundEvent());   // ← sin mirar el payload
});
```

Si el backend manda el push de pago hoy mismo, el usuario acabaría en **Notificaciones**, no en
su ticket. Por eso este documento lleva la sección 6: lo que hay que cambiar en la app. Sin esa
parte, el backend puede hacer su trabajo perfecto y el objetivo no se cumple.

**Lo que sí se garantiza desde el minuto uno:** nada se rompe. Si el push no llega —usuario sin
permiso de notificaciones, sin red, token caducado—, el flujo actual sigue igual: el usuario
vuelve del WebView y la app refresca sus estados de cuenta. El push es un atajo, **nunca el
único camino** al ticket.

---

## 1. Cuándo se manda

**Cuando el backend confirma el cobro con Adquira, no cuando la app vuelve del WebView.**

Es la diferencia entre que funcione siempre o casi nunca. El retorno del WebView depende de que
el usuario no cierre la app, no pierda la red y complete la redirección. La confirmación
servidor-a-servidor de Adquira no depende de nada de eso — y es justo el caso en que el push más
sirve: el usuario pagó, se le fue el internet, y quiere saber si se aplicó.

Punto exacto: el mismo lugar donde hoy se marca el pago como aplicado y se genera el ticket. Si
el ticket no existe todavía, **esperar a tenerlo**: mandar el push antes dejaría al usuario
tocando una notificación que lo lleva a un pago sin ticket.

---

## 2. A quién se le manda

A **todos los tokens FCM del tutor** dueño de esos pagos, usando la tabla que ya alimenta
`POST /api/v1/dispositivo/registrar`.

Un tutor puede tener varios dispositivos (teléfono y tablet). Se manda a todos. Si FCM responde
`UNREGISTERED` o `INVALID_ARGUMENT` para un token, **borrarlo** de la tabla: es un dispositivo
donde la app ya no está.

---

## 3. Cómo se sabe a qué alumno apuntar

La app arma la `referencia` de Adquira con los ids de los pagos separados por `D`:

```
5358D5359D5360
```

Cada uno es un `estado_de_cuenta.id`, y cada estado de cuenta cuelga de un alumno. El backend
resuelve el alumno desde ahí.

**Caso a contemplar:** una misma referencia puede mezclar pagos de **dos alumnos distintos** —el
carrito lo permite—. Regla:

- Todos los pagos son del mismo alumno → mandar `alumno_id` con ese alumno.
- Hay más de un alumno → **omitir `alumno_id`** y mandar el texto en plural. La app abrirá Pagos
  Realizados sin desplazarse a nadie en concreto, que es lo correcto: no hay un único alumno al
  que llevar.

No inventar un alumno "principal": llevaría al usuario al alumno equivocado, que es peor que no
llevarlo a ninguno.

---

## 4. El payload exacto

Hay que mandar **`notification` y `data` a la vez**:

- `notification` — para que el globo se muestre solo. En iOS un mensaje solo-datos **no muestra
  nada**, y en Android la app solo pinta una notificación local cuando el mensaje es solo-datos.
  Mandando `notification` se cubren las dos plataformas sin duplicados.
- `data` — es lo único que sobrevive al toque y lo que la app lee para navegar.

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
      "ticket_id":    "7635",
      "ticket_folio": "T007641",
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

### Reglas del payload — no son opcionales

| Regla | Por qué |
| --- | --- |
| **Todos los valores de `data` son STRING** | FCM rechaza el mensaje si mandas un número o un booleano. `"alumno_id": 1234` falla; `"alumno_id": "1234"` no |
| **`campania` = `"pago"` y `accion` = `"pago_exitoso"`** | Es la convención que la app **ya usa** para los banners (`campania: "banner"`, `accion: "refrescar_banners"`). Respetarla es lo que permite que cada pantalla reconozca lo suyo y **no se pisen entre ellas** |
| **`channel_id` = `arjipagos_notif`** | Es el canal que la app crea. Con otro valor, Android usa el canal por omisión y se pierden el sonido y la prioridad alta |
| **`title` y `message` van también dentro de `data`** | La app da **prioridad a `data` sobre `notification`** para el contenido, porque el backend a veces manda un título genérico. Si solo van en `notification`, la lista de Notificaciones puede quedar en blanco |
| **No mandar `ticket_url` en el payload** | Es una URL con datos del pago y el push viaja por Google. La app ya tiene la URL en la respuesta de Pagos Realizados; con `alumno_id` le basta para encontrarla |
| **Nada de HTML en `notification.body`** | Se muestra crudo. En `data.message` sí se tolera, porque la app le quita el marcado |

---

## 5. Reglas de negocio

### 5.1 Una notificación por pago, y solo una

Adquira puede repetir la confirmación —reintentos, doble entrega—. El backend **debe** llevar
marca de que ya notificó esa `referencia` y no volver a mandarla. Recibir tres veces "pagaste"
por un solo pago asusta al usuario y le hace pensar que le cobraron de más.

Sugerencia: una columna `notificado_at` en el registro del pago, o una tabla de idempotencia con
la `referencia` como clave única.

### 5.2 Solo cuando el pago fue exitoso

Nada de push para pagos rechazados, pendientes o cancelados. Este canal es para la buena noticia.
Los fallos ya se ven en la pantalla del WebView.

### 5.3 Que también quede en la lista de Notificaciones

Se recomienda crear el registro en la tabla de notificaciones del usuario, igual que con las
demás. Así el aviso queda consultable después, y el contador de no leídas cuadra. Si no se hace,
el push es un globo que se pierde en cuanto se descarta.

### 5.4 El texto

Que diga el importe y el nombre del alumno. *"Tu pago de $9,770.00 de LEAH se aplicó
correctamente."* es útil; *"Pago procesado"* no dice nada. Con varios alumnos, plural:
*"Tu pago de $19,540.00 se aplicó correctamente."*

---

## 6. Lo que hay que hacer en la APP (no es del backend, pero sin esto no funciona)

> **HECHO el 2026-08-25.** Los cinco puntos están implementados y con tests. Lo
> único que no se ha podido comprobar en dispositivo es el viaje completo, porque
> **hace falta que el backend mande el push de verdad**: los tres canales se
> prueban con streams inyectados, igual que en `BannerBloc`.
>
> **`ticket_id` llega y se ignora a propósito.** La app no maneja ese
> identificador en ninguna parte —`EstadoDeCuenta` solo conoce `ticketFolio`, que
> es además lo que se le enseña al usuario—. Guardarlo sin usarlo sería dejar
> basura. `ticket_folio` sí se usa: marca los renglones de ese ticket, que suelen
> ser **varios** porque un folio cubre todos los pagos que entraron en el cobro.

1. **Que `NotificacionBloc` deje de tragarse todos los toques.** Debe ignorar los mensajes con
   `campania == "pago"`, igual que `BannerBloc` ya ignora lo que no es suyo con `_esDeBanners()`.
   **Este es el cambio que evita romper lo que hay**: sin él, el push de pago lleva a
   Notificaciones y el resto sobra.
2. **Un manejador nuevo del push de pago**, con los tres casos que ya usan Banners y
   Notificaciones: app en primer plano (`onMessage`), app en segundo plano
   (`onMessageOpenedApp`) y app cerrada (`getInitialMessage`).
3. **Navegar a `edo_cta_pagados`** con `restorablePushNamed` —nunca montando un segundo `MyApp`,
   ver `CLAUDE.md`— y refrescar `EdoCtaPagadosBloc` antes de pintar, porque el pago es de hace
   segundos y la lista en memoria todavía no lo tiene. **Con dos guardas** (añadidas al
   implementarlo): no navegar encima de `pago_webview` —el push llega al confirmar el cobro y el
   usuario puede seguir en la página del banco— ni apilar una segunda copia de la pantalla si ya
   está arriba. Se consulta el mismo `RutaActualObserver` que usa el cerrojo biométrico.
4. **Desplazarse hasta el alumno de `alumno_id`.** Las tarjetas ya nacen abiertas
   (`initiallyExpanded: true`), así que basta con hacer scroll hasta la suya y, si acaso,
   resaltarla un momento. Si no viene `alumno_id`, se abre la pantalla y ya.
5. **Tests** de los tres casos y del filtrado por `campania`, más verificación en dispositivo con
   la app abierta, en segundo plano y cerrada.

---

## 7. Resumen para el backend

| # | Qué | Prioridad |
| --- | --- | --- |
| 1 | Mandar el push al **confirmar el cobro con Adquira**, no al volver del WebView | Bloqueante |
| 2 | Resolver el alumno desde los ids de la `referencia`; omitir `alumno_id` si hay varios | Bloqueante |
| 3 | Enviar a **todos** los tokens FCM del tutor, y borrar los que FCM rechace | Bloqueante |
| 4 | Usar el payload de la sección 4, con `data` **todo en string** | Bloqueante |
| 5 | `campania: "pago"` + `accion: "pago_exitoso"` — la convención que ya existe | Bloqueante |
| 6 | `channel_id: "arjipagos_notif"` | Alta |
| 7 | Idempotencia: una sola notificación por `referencia` | Alta |
| 8 | Solo pagos exitosos | Alta |
| 9 | Crear también el registro en la lista de notificaciones | Media |
| 10 | Texto con importe y nombre del alumno | Media |

## 8. Preguntas para el backend

1. **¿Adquira notifica al servidor por su cuenta** (webhook / confirmación servidor-a-servidor),
   o el backend solo se entera cuando la app llama a `/pago/verificar/{referencia}`? De esto
   depende todo el punto 1: si no hay aviso de Adquira, el push solo podrá salir cuando la app
   pregunte, y se pierde la mayor ventaja.
2. **¿El ticket se genera en el mismo momento en que se aplica el pago**, o va con retraso? Si va
   con retraso, el push debe esperar a que exista.
3. **¿Hay ya una tabla de notificaciones por usuario** donde encaje el punto 5.3, o habría que
   crear el registro aparte?
