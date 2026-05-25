---
name: Modern Messenger
colors:
  surface: '#101415'
  surface-dim: '#101415'
  surface-bright: '#363a3b'
  surface-container-lowest: '#0b0f10'
  surface-container-low: '#191c1e'
  surface-container: '#1d2022'
  surface-container-high: '#272a2c'
  surface-container-highest: '#323537'
  on-surface: '#e0e3e5'
  on-surface-variant: '#c2c6d6'
  inverse-surface: '#e0e3e5'
  inverse-on-surface: '#2d3133'
  outline: '#8c909f'
  outline-variant: '#424754'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e6a'
  primary-container: '#4d8eff'
  on-primary-container: '#00285d'
  inverse-primary: '#005ac2'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#ffb786'
  on-tertiary: '#502400'
  tertiary-container: '#df7412'
  on-tertiary-container: '#461f00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#004395'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdcc6'
  tertiary-fixed-dim: '#ffb786'
  on-tertiary-fixed: '#311400'
  on-tertiary-fixed-variant: '#723600'
  background: '#101415'
  on-background: '#e0e3e5'
  surface-variant: '#323537'
typography:
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style
The design system embodies a **Modern / Corporate** aesthetic with a refined, dark-mode focus. It is designed for high-velocity communication, targeting professional teams and tech-savvy individuals who prioritize focus and clarity. The UI evokes a sense of calm efficiency through a "deep-space" canvas, where content is the protagonist. 

The style utilizes a **Tonal Layering** approach within a dark environment, replacing traditional shadows with subtle shifts in surface luminance to indicate hierarchy. The atmosphere is sophisticated, technical, and precise, ensuring that the interface remains unobtrusive during long periods of use while maintaining high accessibility standards.

## Colors
The palette is centered around a "True Dark" foundation to maximize OLED efficiency and minimize eye strain. 

- **Primary Blue (#3B82F6):** A vibrant, high-contrast blue used for action states, mentions, and active indicators. It is tuned to remain legible against near-black backgrounds.
- **Surface Strategy:** We use a tiered grayscale system. The base background is nearly black (`#0A0A0A`). Primary surfaces (like chat lists or sidebars) use `#121212`. Interactive containers (like message bubbles or input fields) use `#1E1E1E`.
- **Typography Colors:** Primary text uses a high-tint white (`#F8FAFC`) at 90% opacity for comfort, while secondary text uses 60% opacity to establish clear information hierarchy.

## Typography
The typography system balances modern sans-serifs with a technical monospaced font for metadata.

- **Headlines:** Uses **Manrope** for its balanced, modern proportions and excellent legibility at larger scales.
- **Body:** Uses **Inter** as the workhorse for messaging. It is highly legible and provides a neutral, functional tone.
- **Labels:** Uses **JetBrains Mono** for timestamps, file sizes, and status indicators, providing a subtle "pro-tool" aesthetic that differentiates data from conversation.

## Layout & Spacing
This design system utilizes a **Fluid Grid** approach with a modular 4px base unit. 

- **Desktop:** A 3-column layout (Navigation, Conversation List, Active Chat) with fixed-width sidebars and a fluid central messaging area. 
- **Mobile:** A single-column view with a 16px safe-area margin. 
- **Rhythm:** Messaging bubbles use an 8px vertical gap to group sender blocks, with 16px gaps between different senders. Content padding within containers is strictly maintained at 12px or 16px to ensure a spacious, premium feel despite the dark palette.

## Elevation & Depth
In this dark-mode implementation, elevation is communicated through **Luminance and Low-Contrast Outlines** rather than heavy shadows.

- **Level 0 (Base):** The canvas background (`#0A0A0A`).
- **Level 1 (Default Surface):** Main UI containers use `#121212`.
- **Level 2 (Raised):** Overlays, cards, and message bubbles use `#1E1E1E`. 
- **Stroke Accents:** To maintain definition between dark layers, use a subtle 1px border of `#2A2A2A` (or 10% white opacity) on all Level 2 elements. This "ghost border" technique provides necessary contrast without the visual weight of light-mode shadows.

## Shapes
The shape language is **Rounded**, conveying a friendly yet professional demeanor.

- **Buttons & Inputs:** Standard 0.5rem (8px) radius.
- **Message Bubbles:** 1rem (16px) for the outer corners, with the corner adjacent to the sender tail reduced to 4px to provide directional cues.
- **Avatars:** Strictly circular (full-round) to stand out against the geometric grid of the layout.

## Components
- **Buttons:** Primary buttons are solid Blue (#3B82F6) with white text. Secondary buttons use a ghost style with the Primary Blue outline or a subtle gray fill (`#2A2A2A`).
- **Message Bubbles:** Incoming messages use the `surface-container` color. Outgoing messages use the Primary Blue to clearly distinguish the user's voice.
- **Input Fields:** Search and message inputs use a slightly darker-than-surface background with a 1px `surface-container-high` border. On focus, the border transitions to Primary Blue.
- **Chips:** Used for channel tags or status. These use a low-opacity primary tint (e.g., Blue at 15% opacity) with a solid colored label to maintain readability without overwhelming the dark background.
- **Lists:** Active states in the sidebar should use a "pill" highlight with the `surface-container-high` color and a 4px vertical "accent bar" of the Primary Blue on the leading edge.