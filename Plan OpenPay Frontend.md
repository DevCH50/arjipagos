# Plan OpenPay — Frontend (app móvil `arjipagos`, Flutter)

> **Para qué es este documento:** describir cómo cobra la app en **«Otros pagos» (emisor fiscal 2)**
> con el «Botón de pago» de OpenPay.
> **Fecha:** 24-sep-2026 · **Estado:** implementado en la app; **pendiente de que el backend se
> despliegue** (ver §7). **Documento espejo:** `Plan OpenPay Backend.md`, en el repo de ArjiApp.
>
> ⚠️ Esto **reemplaza la versión del 3-sep-2026**, que describía un reparto que no se puede hacer.
> La original está en `otros/planes_anteriores/`, y el §8 explica qué cambió y por qué.

---

## 1. El reparto

| Quién | Qué hace |
|---|---|
| **La app** | Pide la URL del cobro, abre el formulario de OpenPay en su WebView y recoge el resultado cuando OpenPay le devuelve el control |
| **El backend** | Crea el cobro en OpenPay con la llave privada, y al volver el tutor consulta el cargo y lo registra igual que los de Adquira (ticket, estado de cuenta, bitácora, correo, push) |
| **OpenPay** | Todo el cobro: pinta el formulario, pide la tarjeta, la autoriza y redirige de vuelta |

**Dónde aplica:** sólo en **«Otros pagos» (emisor fiscal 2)**. «Pagos Pendientes» (emisor 1) sigue
con Adquira, **sin un solo cambio**, y hay tests que lo vigilan.

**Es la misma forma que Adquira.** La app manda unos parámetros, la pasarela hace el cobro entero y
devuelve el control a una URL de retorno nuestra que responde `{success, message}`. Lo único que
cambia son el endpoint y los parámetros.

### Por qué la app no llama a OpenPay directamente

Porque crear el cobro se firma con la **llave privada**. La documentación del botón de pago
(`documents.openpay.mx/docs/boton-de-pago`, pestaña «API») lo dice literalmente:

> Genera tu Botón de pago. Utiliza tu **llave privada (PRIVATE_API_KEY)** la cual te fue asignada al
> crear tu cuenta en la Plataforma de Openpay. **HEADER PRIVATE_API_KEY**

Una `sk_…` dentro del APK se saca con `unzip` y `strings`. Con ella se pueden crear cargos, **hacer
devoluciones** y leer los clientes del comercio. Por eso la guarda el servidor, que es exactamente
el mismo sitio donde ya vive el secreto de cualquier otra integración.

---

## 2. Lo que hace la app, paso a paso

```
App                        Backend                      OpenPay
 │                            │                            │
 │ POST /api/v1/openpay/crear-cargo   (Bearer del tutor)    │
 │  { "referencia": "5358A5359A5360" }                      │
 ├───────────────────────────>│                            │
 │                            │ POST /v1/{MID}/checkouts   │
 │                            │  (llave privada)           │
 │                            ├───────────────────────────>│
 │                            │<── checkout_link ──────────│
 │<── { success, url, order_id, importe } ──────────────────│
 │                            │                            │
 │ WebView GET <url>  ──────────────────────────────────────>
 │            (el tutor teclea su tarjeta en OpenPay)       │
 │<── redirección a /api/v1/openpay/pago-realizado?id=… ────│
 │                            │ consulta el cargo          │
 │                            ├───────────────────────────>│
 │                            │ marca pagos, ticket,       │
 │                            │ correo y push              │
 │<── { "success": true, "message": "…" } ──────────────────│
 │   (lo detecta WebViewScripts.detectarRespuestaJson)      │
```

### 2.1 Crear el cobro

```
POST  https://arjipagos.moriah.mx/api/v1/openpay/crear-cargo
Authorization: Bearer <token del tutor>
Content-Type: application/json
```

| Campo | Tipo | Req. | Qué se manda |
|---|---|---|---|
| `referencia` | string | **sí** | Los ids de los cargos con el **mismo formato de siempre**: `PoliticaEmisor.generarReferencia(ids)` → `5358A5359A5360` en Android, `5358I5359I5360` en iOS. El separador es lo que le dice al backend el canal |
| `emails_extra` | array | no | Copias del correo de aviso, igual que en Adquira |

**El importe NO se manda, y es deliberado.** Lo calcula el servidor a partir de los cargos que
nombra la referencia. Es el único dato que un teléfono no puede falsear: si viajara desde la app,
una versión manipulada podría pedir cobrar un peso por una colegiatura.

Respuesta buena (200):

```json
{
  "success": true,
  "url": "https://sandbox-api.openpay.mx/ck/Cb0EJHFIp2aG",
  "order_id": "5358A5359A5360-N1758700000000",
  "importe": 3450.00
}
```

`order_id` lleva el sufijo `-N<marca de tiempo>` porque OpenPay exige que sea **único entre todas
las transacciones del comercio**: sin él, reintentar tras una tarjeta rechazada sería rechazado por
duplicado.

### 2.2 Abrir el formulario

La app abre esa `url` en el WebView **con un GET y sin ninguna cabecera**. Nada de `Authorization`:
es un dominio de OpenPay, y mandarle el token del tutor sería entregarle a un tercero la credencial
con la que se lee su estado de cuenta y sus facturas.

### 2.3 El retorno

Lo hace OpenPay solo, redirigiendo a
`https://arjipagos.moriah.mx/api/v1/openpay/pago-realizado?id={charge_id}` — que es el `redirect_url`
que el backend le dio al crear el cobro. **La app no llama a nada aquí**; el WebView aterriza y ya.

El backend **no se cree la URL**: consulta el cargo con su llave privada y decide con ese `status`,
no con lo que venga en el query string. Responde siempre 200:

```json
{ "success": true, "message": "Pagos agregados correctamente" }
```

| Caso | `success` | Qué significa |
|---|---|---|
| Pagado y aplicado | `true` | Todo bien |
| Reintento de algo ya aplicado | `true` | «Este pago ya estaba registrado». No crea un segundo ticket |
| Rechazado | `false` | El `error_message` de OpenPay |
| Pagado, pero sin identificar los cargos | `false` | ⚠️ **El dinero SÍ salió.** El mensaje dice «no vuelvas a pagar» y hay que mostrarlo tal cual |

**Es el mismo contrato que Adquira**, así que lo reconocen `WebViewScripts.detectarRespuestaJson` y
`PagoResponseHandler.procesarJson()` **sin ningún cambio**.

---

## 3. Cómo quedó en el código

| Archivo | Qué hace |
|---|---|
| `lib/src/data/api/pasarela_pago.dart` | `enum PasarelaPago { adquira, openpay }` |
| `lib/src/data/api/configuracion_adquira.dart` | Campo `pasarela`. `ef1` → adquira, `ef2` → openpay |
| `lib/src/data/dataSource/remote/services/OpenpayService.dart` | `crearCargo(referencia)` |
| `lib/src/domain/models/OpenpayCheckout.dart` | `{url, orderId, importe}` |
| `lib/src/presentation/pages/carrito/bloc/CarritoBloc.dart` | `_onPagar` bifurca: `_cobrarPorAdquira` / `_cobrarPorOpenpay` |
| `lib/src/presentation/pages/pago_webview/peticion_webview.dart` | Decide GET o POST, y con qué cabeceras |
| `lib/src/data/api/endpoints.dart` | `openpayCrearCargo`, `openpayUrlRetorno` |

**Añadir una pasarela nueva es una entrada más en el `switch` de `_onPagar` y un valor más en el
enum.** No hay que tocar pantallas ni widgets.

### Las tres cosas que no se pueden deshacer

1. **`params` vacío significa «cargar con GET».** Es la señal que distingue las dos pasarelas dentro
   del WebView, y evitó meter un campo nuevo en `PagoWebViewArgs` y tocar `carrito_body.dart`. Si
   algún día OpenPay necesitara parámetros, hay que cambiar la señal, no rellenarlos a medias.
2. **Al GET de OpenPay no se le manda ninguna cabecera.** Ver §2.2. Test:
   `test/unit/pago_webview/peticion_webview_test.dart`.
3. **Una respuesta sin la clave `success` no se cree.** Laravel contesta los errores de framework
   con `{"message": "The POST method is not supported for route…"}`, y ese texto no se le enseña a
   un padre que quiere pagar. Solo se muestra el `message` cuando viene con `success`, que es lo que
   manda siempre el controlador de OpenPay.

---

## 4. Lo que el emisor 1 NO pierde

Adquira sigue exactamente igual: mismo endpoint, mismos parámetros, mismo POST con formulario,
mismo `Authorization`. El código de `_onPagar` se movió tal cual a `_cobrarPorAdquira`, sin tocar
una línea. Hay un test que lo comprueba y que además exige que **el emisor 1 no pase por OpenPay ni
una sola vez** (`test/unit/blocs/carrito_pasarela_test.dart`).

`ConfiguracionAdquira.ef2` **conserva `esProvisional: true`** aunque ya no cobre por Adquira. Sus
campos de Adquira quedan inertes, pero siguen siendo prestados del emisor 1: la marca es la red de
seguridad del día que alguien devuelva este emisor a Adquira sin cambiar el `idexpress`, que haría
que el dinero volviera a entrar en la cuenta equivocada sin que nada fallara.

---

## 5. Tests

| Archivo | Qué cubre |
|---|---|
| `test/unit/services/openpay_service_test.dart` | El contrato de `crear-cargo`: que viaje la referencia y el Bearer, que **no** viaje el importe, que los errores del backend se muestren tal cual, que los de framework no, y que ninguna excepción de red llegue cruda |
| `test/unit/blocs/carrito_pasarela_test.dart` | Que cada emisor cobre por su pasarela, que EF1 no toque OpenPay, y que un fallo al crear el cobro **no** navegue al WebView |
| `test/unit/pago_webview/peticion_webview_test.dart` | GET vs POST, y que el token no llegue a OpenPay |

---

## 6. Cómo comprobar que jala

1. Cobra en el **sandbox** desde «Otros pagos» con `4111111111111111` (Visa débito, aprueba).
2. En el back-office, el cargo debe quedar **pagado**, con su ticket y su folio.
3. La forma de pago: **débito → 28, crédito → 04**. Es lo que se timbra en el CFDI.
4. Deben llegar el correo de aviso y el push de «pago recibido».
5. Repite con `4222222222222220` (rechaza): el estado de cuenta **no** debe cambiar.
6. Vuelve a abrir la URL de retorno con el mismo `id`: debe responder «Este pago ya estaba
   registrado» y **no** crear un segundo ticket.
7. Paga algo en **«Pagos Pendientes» por Adquira**: tiene que seguir funcionando igual que siempre.
8. Comprueba los dos temas y las dos plataformas: la pantalla del WebView es la misma de Adquira, así
   que lo que cambia es el contenido que pinta OpenPay.

Tarjetas de prueba de OpenPay (cualquier fecha futura; CVV 3 dígitos, 4 en AMEX):
**aprueban** `4111111111111111`, `5105105105105100`, `345678000000007`;
**rechazan** `4222222222222220`, `4000000000000069` (expirada), `4444444444444448` (sin fondos).

---

## 7. 🔴 Lo que falta, y no es de la app

**El backend está desplegado y responde.** Probado en el Oppo el **24-sep-2026** con CATutorM30,
pulsando Pagar sobre un cargo real del emisor 2 (FUTBOL TIGRES, $3,500):

```
POST /api/v1/openpay/crear-cargo  → 422
{"success":false,"message":"Estos cargos no se cobran por esta vía. Vuelve a cargar la pantalla…"}
```

La app hizo su parte entera: referencia `30355A0`, Bearer, sin importe, y al recibir el rechazo
enseñó el mensaje del backend en un `AlertDialog` **sin navegar al WebView**. El freno está en el
servidor, y son tres cosas:

1. **`OPENPAY_EMISORES=2` en el `.env`** (y `php artisan config:clear`). Ese 422 lo produce
   `cobraPorOpenpay()` cuando el emisor no está en `config('openpay.emisores')`.
2. `OPENPAY_MERCHANT_ID`, `OPENPAY_PRIVATE_KEY`, `OPENPAY_PUBLIC_KEY` y `OPENPAY_SANDBOX=true`.
   Sin llaves, `crearCargo` responde 503 con un mensaje claro en vez de fallar a medias.
3. Commitear los archivos de OpenPay, que en el repo de ArjiApp siguen sin versionar.

### ⚠️ Dos ramas del retorno que dejan colgada a la app

`pagoRealizadoOpenpay` llama a `responder(esWeb: true, …)` **a pelo** cuando no llega `id` y cuando
falla `consultarCargo`. Comprobado con curl: las dos contestan **302 al portal web** en lugar del
`{success, message}`. En el móvil eso deja al tutor en la pantalla de login del portal, dentro del
WebView del pago, sin saber si le cobraron. Deberían resolver el canal como la rama de rechazado,
con `ReferenciaOpenpay::canalDesde`.

### 🔑 Las llaves: dónde van cuando lleguen

**Solo en el `.env` del backend** (`ArjiApp/.env` y el del servidor). **En este repo no va ni una**,
y hay que dejarlo así. Comprobado el 24-sep-2026:
`grep -rniE "sk_|pk_|merchant_id|private_key" lib/ test/` no devuelve nada.

Las cinco variables ya existen en el `.env` local; faltan las tres credenciales:

| Variable | Local al 24-sep | Qué poner |
| --- | --- | --- |
| `OPENPAY_SANDBOX` | `true` ✅ | `true` para probar, `false` en producción |
| `OPENPAY_MERCHANT_ID` | **vacía** | Id del comercio, `^[a-z0-9]+$` |
| `OPENPAY_PRIVATE_KEY` | **vacía** | Empieza por `sk_`. La secreta |
| `OPENPAY_PUBLIC_KEY` | **vacía** | Empieza por `pk_` |
| `OPENPAY_EMISORES` | `2` ✅ | Dejar `2` |

Se sacan de `sandbox-dashboard.openpay.mx` → engranaje → **«Credenciales de API»**. Después,
`php artisan config:clear` (o `config:cache` si el despliegue lo usa), y **repetirlo en el servidor**.

Con las llaves vacías `crearCargo` responde **503**. El **422** de hoy es otra cosa: el emisor no
está en `config('openpay.emisores')` del servidor. Eso va primero.

El procedimiento completo, con cómo verificarlo en el Oppo, está en `/home/carlos/CONTEXTO.md` §6-ter.

### Y el endpoint que usa el backend no es el que pide este plan

`OpenpayClient` pega hoy a `POST /v1/{merchant}/charges` (el modo redirección clásico, que devuelve
`payment_method.url`), no a `POST /v1/{merchant}/checkouts` (el botón de pago, que devuelve
`checkout_link`). **Desde la app da igual** —en los dos casos recibe una URL que abrir—, pero el
cambio, si se quiere, es ahí.

---

## 8. Qué cambió respecto al plan del 3-sep, y por qué

| El plan original decía | Por qué no |
|---|---|
| «La app crea el cobro en OpenPay» | Exige la llave privada en el APK. Ver §1 |
| «El backend no guarda ninguna llave» | Las guarda, en `config/openpay.php`, y es lo correcto |
| «La app manda el JSON `transaction` al backend» | La app **nunca ve** ese objeto: en el botón de pago sólo recibe una URL antes de pagar y una redirección después. El backend lo consulta él mismo con su llave |
| «La app verifica `status`, `authorization`, `amount`, `order_id`» | Lo hace el servidor, contra OpenPay. Una comprobación en el cliente no vale de nada: quien manipule la app la quita |
| «Guarda el JSON en disco y reintenta con espera creciente» | No hay nada que reintentar: quien registra el pago es el backend, en la misma redirección |
| «Necesito un ejemplo real del JSON de sandbox» | Ya no hace falta: ese JSON lo maneja el backend |
