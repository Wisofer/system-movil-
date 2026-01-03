# 📱 Documento de Diseño - System Movil

## 🎯 Concepto de la Aplicación

**System Movil** es una plataforma de empleos y servicios locales para Nicaragua. Conecta a personas que buscan trabajo con empleadores que ofrecen oportunidades laborales, facilitando la búsqueda de empleo y la contratación de servicios profesionales.

### Propósito Principal
- **Para quienes buscan trabajo**: Encuentra oportunidades laborales cercanas a tu ubicación
- **Para empleadores**: Publica ofertas de trabajo y encuentra el talento que necesitas
- **Red social laboral**: Comparte publicaciones, conecta con profesionales y construye tu red

---

## 🎨 Paleta de Colores

### Colores Principales

#### 🔵 Color Primario - Azul Vibrante
Representa **confianza, estabilidad y modernidad**.

| Color | Código HEX | RGB | Uso |
|-------|------------|-----|-----|
| **Primary** | `#1976D2` | rgb(25, 118, 210) | Botones principales, elementos activos, links |
| **Primary Light** | `#42A5F5` | rgb(66, 165, 245) | Hover states, variantes claras |
| **Primary Dark** | `#1565C0` | rgb(21, 101, 192) | Estados presionados, énfasis |

#### 🟠 Color Secundario - Naranja Vibrante
Representa **energía y motivación**.

| Color | Código HEX | RGB | Uso |
|-------|------------|-----|-----|
| **Secondary** | `#FF6B35` | rgb(255, 107, 53) | Tags de tiempo, elementos destacados |
| **Secondary Light** | `#FF8A65` | rgb(255, 138, 101) | Hover states |
| **Secondary Dark** | `#E64A19` | rgb(230, 74, 25) | Estados presionados |

#### 🟢 Color de Éxito - Verde
Representa **crecimiento y logros**.

| Color | Código HEX | RGB | Uso |
|-------|------------|-----|-----|
| **Success** | `#28A745` | rgb(40, 167, 69) | Confirmaciones, estados exitosos |
| **Success Light** | `#5CB85C` | rgb(92, 184, 92) | Variantes claras |
| **Success Dark** | `#1E7E34` | rgb(30, 126, 52) | Estados presionados |

### Colores Neutros

| Color | Código HEX | RGB | Uso |
|-------|------------|-----|-----|
| **Background** | `#F5F5F5` | rgb(245, 245, 245) | Fondo principal de la app |
| **Surface** | `#FFFFFF` | rgb(255, 255, 255) | Cards, contenedores |
| **On Surface** | `#1A1A1A` | rgb(26, 26, 26) | Texto principal |
| **On Surface Variant** | `#666666` | rgb(102, 102, 102) | Texto secundario |
| **Outline** | `#E0E0E0` | rgb(224, 224, 224) | Bordes, separadores |

### Colores de Estado

| Color | Código HEX | RGB | Uso |
|-------|------------|-----|-----|
| **Warning** | `#FFC107` | rgb(255, 193, 7) | Advertencias |
| **Error** | `#E53E3E` | rgb(229, 62, 62) | Errores, tags urgentes |
| **Info** | `#17A2B8` | rgb(23, 162, 184) | Información |

### Colores Específicos para Tags

| Elemento | Color | Background | Uso |
|----------|------|-----------|-----|
| **Tag Urgente** | `#E53E3E` | `#FFEBEE` | Publicaciones urgentes |
| **Tag Categoría** | `#1976D2` | `#E3F2FD` | Categorías de trabajo |
| **Tag Tiempo** | `#FF6B35` | `#FFF3E0` | Información temporal |

---

## 📝 Tipografía

### Familia de Fuente
**Poppins** - Fuente moderna, legible y profesional de Google Fonts.

### Escala Tipográfica

| Estilo | Tamaño | Peso | Letter Spacing | Uso |
|--------|--------|------|----------------|-----|
| **H1** | 32px | Bold (700) | -0.5 | Títulos principales de pantalla |
| **H2** | 24px | Semi-Bold (600) | -0.25 | Títulos de sección |
| **H3** | 18px | Medium (500) | 0 | Subtítulos |
| **Body** | 16px | Regular (400) | 0.15 | Texto del cuerpo principal |
| **Caption** | 14px | Regular (400) | 0.25 | Texto secundario, descripciones |
| **Small** | 12px | Regular (400) | 0.4 | Texto muy pequeño, metadata |
| **Button** | 16px | Semi-Bold (600) | 0.5 | Texto de botones |
| **Label** | 14px | Medium (500) | 0.1 | Labels de formularios |
| **Link** | 14px | Medium (500) | 0.25 | Enlaces, texto clickeable |

---

## 🧭 Navegación (Navbar)

### Componente
**SalomonBottomBar** - Barra de navegación inferior moderna y elegante.

### Características del Navbar

#### Diseño Visual
- **Posición**: Barra inferior fija
- **Forma**: Bordes superiores redondeados (20px radius)
- **Elevación**: Sombra suave con blur de 20px
- **Padding**: 20px horizontal, 20px vertical
- **Fondo**: Color de superficie del tema (blanco en modo claro, gris oscuro en modo oscuro)

#### Ítems de Navegación

| Índice | Icono | Título | Pantalla |
|--------|-------|--------|----------|
| **0** | `home_15` / `home_2` | Encuéntrame | Home/Feed |
| **1** | `briefcase5` / `briefcase` | Negocios | Trabajos/Business |
| **2** | `message5` / `message` | Mensajes | Chat/Mensajes |
| **3** | `setting_5` / `setting_2` | Configuración | Settings |

#### Estados Visuales

**Ítem Seleccionado:**
- Color: Color primario (`#1976D2`)
- Icono: Versión rellena (ej: `home_15`, `briefcase5`)
- Texto: Semi-Bold (600), color primario

**Ítem No Seleccionado:**
- **Modo Claro**: Color gris (`onSurfaceVariant`)
- **Modo Oscuro**: Blanco con opacidad 0.7
- Icono: Versión outline (ej: `home_2`, `briefcase`)
- Texto: Medium (500)

#### Badge de Notificaciones
El ícono de mensajes incluye un badge con contador de mensajes no leídos:
- **Diseño**: Gradiente rojo (`#E53E3E` → `#C53030`)
- **Posición**: Esquina superior derecha del ícono
- **Forma**: Cápsula redondeada (10px radius)
- **Borde**: Blanco (modo claro) o color de superficie (modo oscuro)
- **Sombra**: Rojo con opacidad 0.3
- **Texto**: Blanco, 10px, Bold (700)
- **Máximo**: Muestra "99+" si hay más de 99 mensajes

---

## 🃏 Cards y Componentes

### Service Card (Card de Trabajo)

#### Estructura
```
┌─────────────────────────────────────┐
│ [Imagen/Video]                       │
│                                      │
├─────────────────────────────────────┤
│ [Avatar] Nombre Usuario             │
│ [Tag Urgente] [Tag Categoría]      │
│ Título del Trabajo                  │
│ Descripción...                      │
│ [Tag Tiempo] Ubicación              │
│ [Botón Contactar] [Botón Guardar]  │
└─────────────────────────────────────┘
```

#### Características
- **Fondo**: Blanco (`#FFFFFF`)
- **Elevación**: 2px
- **Border Radius**: 16px
- **Sombra**: Color outline con opacidad baja
- **Padding**: 16px horizontal, 8px vertical
- **Márgenes**: 16px horizontal, 8px vertical entre cards

#### Elementos Internos

**Header de Card:**
- Avatar del usuario (circular, 40px)
- Nombre del usuario (H3, color onSurface)
- Tags de estado (urgente, categoría) con colores específicos

**Contenido:**
- Título (H3, bold)
- Descripción (Body, color onSurfaceVariant)
- Tags informativos (tiempo, ubicación)

**Footer:**
- Botones de acción (Contactar, Guardar)
- Iconos con Iconsax

### Shared Post Card (Card de Publicación Compartida)

#### Características Especiales
- **Diseño tipo Facebook/LinkedIn**: Feed social con interacciones
- **Reacciones**: Like, Love, Laugh, Wow, Sad, Angry
- **Comentarios**: Sistema de comentarios anidados
- **Compartir**: Opción de compartir publicaciones
- **Guardar**: Marcar como favorito

#### Elementos Visuales
- **Imagen principal**: Aspect ratio 16:9, con visor estilo Facebook
- **Avatar del autor**: Circular, 48px
- **Badge de reacciones**: Contador con gradiente
- **Botones de interacción**: Diseño moderno con iconos Iconsax

---

## 🎭 Temas (Light & Dark)

### Modo Claro (Light Theme)

#### Colores Base
- **Background**: `#F5F5F5` (Gris muy claro)
- **Surface**: `#FFFFFF` (Blanco)
- **On Surface**: `#1A1A1A` (Casi negro)
- **On Surface Variant**: `#666666` (Gris medio)

#### AppBar
- **Fondo**: Blanco
- **Texto**: Casi negro
- **Elevación**: 0 (sin sombra)
- **Status Bar**: Iconos oscuros

#### Cards
- **Fondo**: Blanco
- **Elevación**: 2px
- **Sombra**: Gris claro con opacidad baja

### Modo Oscuro (Dark Theme)

#### Colores Base
- **Background**: `#121212` (Casi negro)
- **Surface**: `#1A1A1A` (Gris muy oscuro)
- **On Surface**: `#FFFFFF` (Blanco)
- **On Surface Variant**: Blanco con opacidad 0.7

#### AppBar
- **Fondo**: `#1A1A1A`
- **Texto**: Blanco
- **Elevación**: 0
- **Status Bar**: Iconos claros

#### Cards
- **Fondo**: `#1A1A1A`
- **Elevación**: 4px
- **Sombra**: Negro con opacidad alta

---

## 🎯 Componentes de UI

### Botones

#### Elevated Button (Botón Principal)
- **Fondo**: Color primario (`#1976D2`)
- **Texto**: Blanco
- **Elevación**: 2px
- **Border Radius**: 12px
- **Tipografía**: Button style (16px, Semi-Bold)
- **Padding**: Automático según contenido

#### Text Button (Botón Secundario)
- **Fondo**: Transparente
- **Texto**: Color primario
- **Tipografía**: Link style (14px, Medium)
- **Sin elevación**

### Inputs y Formularios

#### Text Field
- **Border Radius**: 12px
- **Borde**: Color outline (`#E0E0E0`)
- **Label**: Color onSurfaceVariant
- **Texto**: Color onSurface
- **Focus**: Color primario

### Tags y Badges

#### Tag Urgente
- **Texto**: Rojo (`#E53E3E`)
- **Fondo**: Rosa claro (`#FFEBEE`)
- **Border Radius**: 8px
- **Padding**: 6px horizontal, 4px vertical

#### Tag Categoría
- **Texto**: Azul (`#1976D2`)
- **Fondo**: Azul muy claro (`#E3F2FD`)
- **Border Radius**: 8px
- **Padding**: 6px horizontal, 4px vertical

#### Tag Tiempo
- **Texto**: Naranja (`#FF6B35`)
- **Fondo**: Naranja muy claro (`#FFF3E0`)
- **Border Radius**: 8px
- **Padding**: 6px horizontal, 4px vertical

---

## 📐 Espaciado y Layout

### Sistema de Espaciado
- **Base Unit**: 4px
- **Espaciado estándar**: 8px, 12px, 16px, 20px, 24px, 32px

### Márgenes y Padding

| Elemento | Padding Horizontal | Padding Vertical | Margin |
|----------|-------------------|------------------|--------|
| **Card** | 16px | 8px | 16px horizontal, 8px vertical |
| **Navbar** | 20px | 20px | - |
| **AppBar** | 16px | - | - |
| **Botones** | 16px | 12px | - |

### Border Radius

| Elemento | Radius |
|----------|--------|
| **Cards** | 16px |
| **Botones** | 12px |
| **Tags** | 8px |
| **Navbar** | 20px (superior) |
| **Inputs** | 12px |

---

## 🎬 Animaciones y Transiciones

### Transiciones de Navegación
- **Duración**: 300ms
- **Curva**: `Curves.easeInOut`
- **Tipo**: PageView con animación suave

### Efectos Visuales
- **Shimmer**: Loading skeletons elegantes
- **Lottie**: Animaciones para estados vacíos
- **Animate Do**: Animaciones de entrada para elementos

---

## 🖼️ Iconografía

### Librería Principal
**Iconsax** - Iconos modernos, elegantes y consistentes.

### Estilos de Iconos
- **Outline**: Estados no seleccionados
- **Bold/Filled**: Estados seleccionados o activos
- **Tamaño estándar**: 24px
- **Color**: Sigue el sistema de colores del tema

### Iconos Principales
- `home_15` / `home_2` - Inicio
- `briefcase5` / `briefcase` - Trabajos
- `message5` / `message` - Mensajes
- `setting_5` / `setting_2` - Configuración
- `heart` / `heart5` - Favoritos
- `bookmark` / `bookmark5` - Guardar
- `share` - Compartir
- `location` - Ubicación
- `time` - Tiempo

---

## 📱 Responsive Design

### Breakpoints
- **Mobile**: < 600px (Diseño principal)
- **Tablet**: 600px - 1200px (Futuro)
- **Desktop**: > 1200px (Futuro)

### Orientación
- **Principal**: Portrait (Vertical)
- **Restricción**: Solo vertical en móviles

---

## 🎨 Guía de Estilo Visual

### Principios de Diseño

1. **Modernidad**: Diseño limpio y contemporáneo
2. **Legibilidad**: Alto contraste, tipografía clara
3. **Consistencia**: Mismos estilos en toda la app
4. **Accesibilidad**: Colores con buen contraste (WCAG AA)
5. **Profesionalismo**: Estética corporativa pero amigable

### Jerarquía Visual

1. **Primario**: Color azul para acciones principales
2. **Secundario**: Color naranja para elementos destacados
3. **Neutro**: Grises para texto y fondos
4. **Estado**: Verde (éxito), Rojo (error), Amarillo (advertencia)

### Espaciado Visual
- **Agrupación**: Elementos relacionados juntos
- **Separación**: Espacio claro entre secciones
- **Respiración**: No saturar con información

---

## 📊 Resumen de Especificaciones

### Paleta de Colores
- ✅ 3 colores principales (Azul, Naranja, Verde)
- ✅ Sistema de colores neutros completo
- ✅ Colores de estado (Error, Warning, Info)
- ✅ Soporte para modo claro y oscuro

### Tipografía
- ✅ Fuente Poppins (Google Fonts)
- ✅ 9 estilos tipográficos definidos
- ✅ Escala consistente y legible

### Componentes
- ✅ Navbar moderno con SalomonBottomBar
- ✅ Cards con diseño limpio
- ✅ Sistema de tags y badges
- ✅ Botones con estilos definidos

### Tema
- ✅ Modo claro completo
- ✅ Modo oscuro completo
- ✅ Transiciones suaves entre temas

---

## 🚀 Tecnologías de Diseño

### Librerías Utilizadas
- **Google Fonts**: Tipografía Poppins
- **Iconsax**: Iconografía moderna
- **Salomon Bottom Bar**: Navbar elegante
- **Shimmer**: Loading states
- **Lottie**: Animaciones
- **Glassmorphism**: Efectos visuales (opcional)

---

## 📝 Notas Finales

Este documento describe el sistema de diseño completo de **Encuéntrame**. Todos los componentes deben seguir estas especificaciones para mantener la consistencia visual y la experiencia de usuario óptima.

**Última actualización**: 2024
**Versión del documento**: 1.0

---

*Documento creado para el proyecto Encuéntrame - Plataforma de Empleos en Nicaragua*

