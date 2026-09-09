# Plan OpenPay — Frontend (app móvil `arjipagos`, Flutter)

> **Para qué es este documento:** dar a la app **el endpoint y los parámetros** con los que reportar
> al backend un pago hecho con OpenPay en **«Otros pagos» (emisor fiscal 2)**.
> **Fecha:** 03-sep-2026 · **Documento espejo:** `Plan OpenPay Backend.md`.

---

## 1. El reparto

| Quién | Qué hace |
|---|---|
| **La app** | Todo el pago: crea el cobro en OpenPay, muestra la pantalla, recibe el JSON de respuesta |
| **El backend** | **Sólo una cosa:** recibe ese JSON y lo registra igual que registra los de Adquira (ticket, estado de cuenta, bitácora, correo, push) |

El backend **no habla con OpenPay** y **no guarda ninguna llave**. Es el mismo reparto que ya
funciona con Adquira: la app paga, el backend registra.

**Dónde aplica:** sólo en **«Otros pagos» (emisor fiscal 2)**. «Pagos Pendientes» (emisor 1) sigue con
Adquira, sin ningún cambio.

---

## 2. El endpoint

```
POST  https://arjipagos.moriah.mx/api/v1/openpay/pago-realizado
Content-Type: application/json
```
- **Público**, sin token (igual que `/api/v1/pago-realizado`, el de Adquira). Si prefieres mandar el
  `Authorization: Bearer`, se acepta y se ignora.
- También admite `GET`, por simetría con el de Adquira.
- En desarrollo: el mismo host que ya usa la app, con la ruta `/api/v1/openpay/pago-realizado`.

### 2.1 Parámetros

| Campo | Tipo | Req. | Qué mandar |
|---|---|---|---|
| `referencia` | string | **sí** | Los ids de los cargos, **exactamente con el mismo formato que ya usas para Adquira**: `AppConstants.generarReferencia(ids)` → `5358A5359A5360` en Android, `5358I5359I5360` en iOS. El separador es lo que le dice al backend el canal |
| `transaction` | objeto | **sí** | **El JSON de OpenPay tal cual**, sin tocar ni renombrar nada. Si lo mandas en la raíz en vez de dentro de `transaction`, también se acepta |
| `emails_extra` | array de strings | no | Copias del correo de aviso, igual que en Adquira |

### 2.2 Ejemplo completo de petición

```json
{
  "referencia": "5358A5359A5360",
  "transaction": {
    "id": "tlxcm4vprtz74qoenuay",
    "status": "completed",
    "authorization": "801585",
    "amount": 3450.00,
    "currency": "MXN",
    "method": "card",
    "operation_date": "2026-09-03T10:22:41-06:00",
    "creation_date": "2026-09-03T10:22:33-06:00",
    "order_id": "5358A5359A5360",
    "error_message": null,
    "card": {
      "type": "debit",
      "brand": "mastercard",
      "card_number": "1881",
      "bank_name": "BBVA BANCOMER"
    }
  }
}
```

**Del JSON de OpenPay, el backend usa:** `status`, `id`, `authorization`, `amount`, `method`,
`operation_date` (o `creation_date` si falta), `error_message`, `card.type`, `card.brand`,
`card.card_number`, `card.bank_name`, `order_id`. **Manda el objeto entero de todos modos**: lo que no
use se guarda en la bitácora, y si OpenPay agrega campos nuevos no se rompe nada.

**Lo que decide si el pago se aplica es `status`:** `"completed"` se aplica, cualquier otra cosa se
registra como rechazo.

### 2.3 Lo que NO hay que mandar

- **El importe como dato de control.** El backend cobra lo que valen los cargos de la `referencia`,
  no lo que diga el JSON. `amount` viaja sólo como información.
- Llaves de OpenPay, ni públicas ni privadas.
- Nada de emisores: el backend resuelve el emisor fiscal desde los propios cargos, como hace hoy.

---

## 3. Asegurarse de que se cobró bien

Son dos comprobaciones distintas y las dos hacen falta. **«Cobrado bien» no es que OpenPay diga que
sí: es que OpenPay cobró Y el backend lo registró.**

### 3.1 Primero: que OpenPay realmente haya cobrado

Antes de decirle nada al usuario, revisa el JSON. **Que la pantalla de pago se haya cerrado no
significa que se cobró.**

| Comprobación | Qué exigir | Por qué |
|---|---|---|
| **Estado** | `status == "completed"` | Es el único estado que significa cobrado. Ver la tabla de abajo |
| **Autorización** | `authorization` presente y no vacía | Un cobro con tarjeta aprobado siempre trae número de autorización |
| **Sin error** | `error_message` nulo o vacío | Si trae texto, el cobro no pasó |
| **Importe** | `amount` == el total que seleccionó el usuario, **comparado a 2 decimales** | Si no coincide, algo se cobró mal: no lo des por bueno |
| **Referencia** | `order_id` == la `referencia` que generaste para **esos** cargos | Evita registrar un cobro contra los cargos equivocados |
| **Método** | `method == "card"` | Sólo se cobra con tarjeta |

Estados de OpenPay y qué significan:

| `status` | ¿Se cobró? | Qué hacer |
|---|---|---|
| `completed` | ✅ Sí | Reportar al backend y mostrar éxito |
| `failed` | ❌ No | Reportar al backend (queda el rechazo en bitácora) y ofrecer reintentar |
| `cancelled` | ❌ No | Igual que `failed` |
| `charge_pending` / `in_progress` | ⏳ Todavía no | **No mostrar éxito ni error.** No es un cobro cerrado |
| cualquier otro | ❓ | Trátalo como no cobrado y deja rastro en `AppLogger` |

Si alguna comprobación de la tabla falla con `status: completed`, **no muestres éxito**: manda el
JSON al backend igual —para que quede el rastro— y enseña «Estamos verificando tu pago; no vuelvas a
pagar».

### 3.2 Después: que el backend lo haya registrado

Aquí está el riesgo de verdad. Si OpenPay cobró y el aviso nunca llega al backend, **el dinero salió
y el cargo sigue apareciendo como pendiente**. Es lo mismo que pasa hoy con Adquira, y se evita así:

1. **Guarda el JSON en disco antes de la primera llamada.** Si el sistema mata la app, no se pierde.
2. **Llama al endpoint en cuanto tengas el JSON**, antes de navegar o cerrar la pantalla.
3. **Sólo das el pago por registrado cuando llegue `success: true`.** Ni antes, ni por el hecho de
   que la petición no diera error.
4. **Reintenta** mientras no haya respuesta: espera creciente, por ejemplo `2, 5, 10, 20, 30` segundos.
   Un timeout **no** significa que no llegó.
5. Si se agotan los reintentos, **conserva el JSON** y vuelve a intentarlo **al abrir la app**. Bórralo
   sólo cuando el backend confirme.
6. Mientras tanto, el mensaje es «Recibimos tu pago, lo estamos registrando. **No vuelvas a pagar.**»

> ✅ **Reintentar es seguro.** El backend sólo aplica cargos que sigan pendientes: si el aviso ya se
> había registrado, no crea un segundo ticket y responde `success: true` con «Este pago ya estaba
> registrado». Puedes reintentar sin miedo a cobrar dos veces. *(Está en el §3.1 del plan de backend;
> si ese filtro no se implementa, los reintentos SÍ duplicarían el ticket.)*

### 3.3 Lo que nunca hay que hacer

- Dar por pagado algo que no traiga `status: "completed"`.
- Dar por registrado un cobro sin haber recibido `success: true`.
- Decir «rechazado» cuando el dinero salió: si `status` es `completed`, el mensaje nunca es de error,
  aunque el backend responda `success: false` (ese caso es «lo recibimos pero no lo identificamos»).
- Borrar el JSON guardado antes de la confirmación.

---

## 4. La respuesta

Siempre **200** (o **302** si el canal es web). **Nunca 4xx ni 5xx**, igual que el de Adquira.

```json
{ "success": true, "message": "Pagos agregados correctamente" }
```

| Caso | `success` | `message` |
|---|---|---|
| Pagado y aplicado | `true` | «Pagos agregados correctamente» |
| Pagado, pero no se identificaron los cargos | `false` | «El pago se procesó pero no pudimos identificar los cargos. Comunícate con el colegio; no vuelvas a pagar.» |
| Rechazado | `false` | el `error_message` que vino de OpenPay |

- El JSON **siempre trae `success` y `message`**, que es justo lo que busca
  `WebViewScripts.detectarRespuestaJson` si decides cargarlo dentro del WebView, o lo que lee
  `PagoResponseHandler.procesarJson()` si lo llamas por `http`. **Cualquiera de los dos caminos
  sirve**: el contrato es el mismo.
- ⚠️ El segundo caso trae `success: false` **pero el dinero sí salió**. Muestra ese `message` tal
  cual: decirle «rechazado» a quien ya pagó lo empuja a pagar dos veces.

---

## 5. Cómo comprobar que jala

1. Cobra en el **sandbox** de OpenPay desde «Otros pagos» y llama al endpoint con el JSON recibido.
2. En el back-office, el cargo debe quedar **pagado**, con su ticket y su folio.
3. La forma de pago tiene que salir bien: **débito → 28, crédito → 04**. Es lo que se timbra después
   en el CFDI, así que conviene mirarlo.
4. Debe llegar el correo de aviso y el push de «pago recibido».
5. Repite con una tarjeta rechazada (`4222222222222220`): el estado de cuenta **no debe cambiar**.
6. Repite con una referencia inventada y un pago aprobado: no debe crearse ningún ticket, y el
   mensaje que recibes **no debe decir «rechazado»**.
7. **Corta la red justo después de cobrar** y deja que la app reintente: el cargo debe quedar
   registrado **una sola vez**, sin ticket duplicado.
8. **Manda el mismo aviso dos veces a propósito**: la segunda vez el backend debe responder
   `success: true` sin crear otro ticket.
9. Prueba una tarjeta que deje el cobro en `charge_pending`: la app **no** debe mostrar éxito.
10. Paga algo en **«Pagos Pendientes» por Adquira**: tiene que seguir funcionando igual que siempre.

Tarjetas de prueba de OpenPay (vigencia: cualquier fecha futura; CVV 3 dígitos, 4 en AMEX):
**aprueban** `4111111111111111` (Visa débito), `5105105105105100` (MasterCard crédito),
`345678000000007` (AMEX); **rechazan** `4222222222222220`, `4000000000000069` (expirada),
`4444444444444448` (sin fondos).

---

## 6. Si aun así se pierde el aviso

Con lo del §3.2 es difícil, pero puede pasar (el usuario desinstala la app, por ejemplo). En ese caso
**el cobro queda hecho y sin aplicar**, y hay que aplicarlo a mano desde el back-office. Es lo mismo
que ocurre hoy con Adquira. Si sucede, el dato que necesita administración es el `id` del cargo de
OpenPay y la `referencia`: consérvalos en el log de la app.

---

## 7. Lo que necesito de ti

Un **ejemplo real del JSON** que OpenPay le devuelve a la app en sandbox. Con eso confirmo el mapeo
contra la realidad y no contra el ejemplo de la documentación.
