# EM Code Studio — App Flutter (CRM)

Aplicación Flutter multiplataforma para gestionar un estudio creativo **ficticio**: clientes, proyectos, servicios, cobros y estadísticas. Proyecto realizado durante la formación; los clientes, DNIs y datos económicos son de prueba.

## Funcionalidades

- **Login** con Supabase Auth (correo y contraseña).
- **Panel de inicio** con indicadores reales (proyectos, montos y saldos).
- **Clientes y proyectos**: alta, edición, búsqueda y estados; portal del cliente con mensajes.
- **Servicios** con administración y carga de imágenes a Supabase Storage.
- **Estadísticas** con gráficos (`fl_chart`) e informes PDF imprimibles.
- **Extras**: selector de imágenes, geolocalización, apertura de enlaces y exportación a PDF.

## Configuración (importante)

Las credenciales de Supabase **no están en el repositorio**. Se leen con `--dart-define` desde variables de entorno:

1. Copia `.env.example` a `.env` y rellena tus propios valores (`.env` está ignorado por Git).
2. Ejecuta pasando esos valores:

```bash
flutter pub get
flutter run ^
  --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY ^
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
```

En PowerShell:

```powershell
flutter run `
  --dart-define=SUPABASE_URL="https://TU_PROYECTO.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="TU_ANON_KEY" `
  --dart-define=SUPABASE_PUBLISHABLE_KEY="TU_PUBLISHABLE_KEY"
```

Si no pasas las credenciales, la app avisará con un mensaje claro en lugar de usar claves ajenas.

> Nota de seguridad: usa siempre el **anon/publishable key**, nunca el `service_role key`. Activa Row Level Security (RLS) en Supabase antes de usar la app con datos reales.

## Tecnologías

`Flutter` · `Dart` · `Supabase` (Auth, Storage, Postgres) · `fl_chart` · `pdf` / `printing` · `image_picker` · `geolocator`
