# Mora Studio · Cotizador 3D

Calculadora de costos y presupuestos de impresión 3D.
Funciona en cualquier celular o PC. Los datos quedan en **Supabase** (PostgreSQL) y la página se publica gratis en **GitHub Pages**.

## Archivos

| Archivo | Para qué |
|---|---|
| `index.html` | La app completa |
| `config.js` | URL y clave de tu Supabase (**editar**) |
| `supabase.sql` | Crea las tablas, la seguridad y el tiempo real |
| `supabase-v2.sql` | Agrega clientes, pedidos y formas de pago (correr después de `supabase.sql`) |
| `manifest.webmanifest`, `icon-*.png` | Para instalarla como app en el celu |

## 1. Supabase (base de datos), unos 10 minutos

1. Entrá a <https://supabase.com>, creá una cuenta y un **New project** (región *São Paulo*, la más cercana). Guardá la contraseña de la base.
2. En el menú, abrí **SQL Editor → New query**, pegá todo `supabase.sql` y tocá **Run**. Tiene que decir *Success*. Después hacé lo mismo con `supabase-v2.sql`.
3. En **Authentication → Users → Add user → Create new user**:
   - Creá tu usuario (email + contraseña) y tildá **Auto Confirm User**.
   - Repetí para la otra persona.
4. En **Authentication → Sign In / Providers**, desactivá **Allow new users to sign up**. Así nadie más puede crearse una cuenta.
5. En **Project Settings → API** (o botón **Connect**), copiá:
   - **Project URL**
   - **anon / publishable key** (¡no la *service_role*!)
6. Pegá los dos datos en `config.js`.

## 2. GitHub Pages (publicar la página), unos 5 minutos

1. En GitHub, creá un repo nuevo (ej: `mora-cotizador`). Puede ser **Public** o, con cuenta Pro, privado.
2. Subí todos los archivos de esta carpeta (**Add file → Upload files**).
3. En **Settings → Pages**, elegí *Source: Deploy from a branch*, *Branch: main / (root)* y tocá **Save**.
4. En 1 o 2 minutos queda en: `https://TU-USUARIO.github.io/mora-cotizador/`

## 3. Usarla en cualquier dispositivo

- Abrí el link y entrá con tu email y contraseña. La sesión queda guardada.
- **Android (Chrome):** menú ⋮ → *Agregar a pantalla principal* (o *Instalar app*).
- **iPhone (Safari):** compartir → *Agregar a inicio*.
- Lo que carga una persona aparece al instante en el dispositivo de la otra.

## Flujo de pedidos

**Presupuestado** → (el cliente confirma) **A fabricar** → **Imprimiendo** → **Listo** → **Entregado**

- La pestaña **Pedidos** muestra lo que hay que fabricar, ordenado por fecha de entrega, con el filamento total necesario y las horas de impresión.
- Cada pedido guarda la forma de pago (MP Mili, MP Lucas o Efectivo), lo cobrado y el saldo.
- Los clientes se crean solos al guardar un presupuesto. En **Clientes** podés agregar su WhatsApp e Instagram.

## Seguridad

- La *anon key* es pública por diseño: sin iniciar sesión no se puede leer ni escribir nada (reglas RLS).
- Solo existen los usuarios que crees a mano en el paso 1.3.
- Para agregar o sacar a alguien, usá **Authentication → Users**.

## Consultas útiles (SQL Editor)

```sql
-- Ventas por mes
select date_trunc('month', fecha) as mes, count(*) as pedidos,
       sum(precio) as vendido, sum(ganancia) as ganancia
from presupuestos
where estado in ('aceptado','entregado')
group by 1 order by 1 desc;

-- Quién cargó más presupuestos
select creado_por, count(*) from presupuestos group by 1;
```

## Cómo calcula

- **Material** = gramos × (precio rollo ÷ gramos del rollo)
- **Luz** = horas × watts ÷ 1000 × precio kWh
- **Desgaste** = horas × (precio impresora ÷ vida útil + mantenimiento/h)
- **Mano de obra / Diseño** = minutos ÷ 60 × valor hora
- **Costo real** = subtotal + merma %
- **Precio de venta** = costo real ÷ (1 − ganancia % − comisión %)
