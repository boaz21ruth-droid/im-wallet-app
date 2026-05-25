---
name: Modern Messenger System
colors:
  surface: '#f9f9fd'
  surface-dim: '#d9dade'
  surface-bright: '#f9f9fd'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f7'
  surface-container: '#ededf1'
  surface-container-high: '#e8e8ec'
  surface-container-highest: '#e2e2e6'
  on-surface: '#1a1c1f'
  on-surface-variant: '#414754'
  inverse-surface: '#2f3034'
  inverse-on-surface: '#f0f0f4'
  outline: '#717786'
  outline-variant: '#c0c6d6'
  surface-tint: '#005db7'
  primary: '#005bb3'
  on-primary: '#ffffff'
  primary-container: '#0073df'
  on-primary-container: '#fefcff'
  inverse-primary: '#a9c7ff'
  secondary: '#5c5f61'
  on-secondary: '#ffffff'
  secondary-container: '#e0e3e6'
  on-secondary-container: '#626567'
  tertiary: '#006b27'
  on-tertiary: '#ffffff'
  tertiary-container: '#008733'
  on-tertiary-container: '#f7fff2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d6e3ff'
  primary-fixed-dim: '#a9c7ff'
  on-primary-fixed: '#001b3d'
  on-primary-fixed-variant: '#00468c'
  secondary-fixed: '#e0e3e6'
  secondary-fixed-dim: '#c4c7ca'
  on-secondary-fixed: '#191c1e'
  on-secondary-fixed-variant: '#44474a'
  tertiary-fixed: '#72fe88'
  tertiary-fixed-dim: '#53e16f'
  on-tertiary-fixed: '#002107'
  on-tertiary-fixed-variant: '#00531c'
  background: '#f9f9fd'
  on-background: '#1a1c1f'
  surface-variant: '#e2e2e6'
typography:
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm-mobile:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-main: 16px
  gutter-chat: 12px
  bubble-padding-x: 12px
  bubble-padding-y: 8px
  avatar-size-md: 48px
  avatar-size-sm: 32px
---

## Brand & Style

The design system is centered on **human connection and frictionless utility**. It prioritizes high-speed information processing and emotional expression through a "Quiet Modernism" aesthetic. The interface recedes to let the conversation take center stage, utilizing a blend of **Minimalism** and **Corporate/Modern** movements.

The UI should evoke a sense of reliability and immediacy. Every interaction must feel snappy, with transitions that mimic physical inertia. We achieve this through generous whitespace, a restricted but vibrant color palette, and a focus on "squishy" tactile elements that feel responsive to touch.

## Colors

The palette is anchored by a vibrant **Messenger Blue** (#0084FF) to denote action and identity. 

- **Primary:** Used for outgoing message bubbles, primary action buttons, and active states.
- **Secondary:** A soft, cool grey used for incoming message bubbles and background surface separation.
- **Success (Tertiary):** A crisp green reserved for "Online" status indicators and delivery confirmations.
- **Neutral:** A deep charcoal for primary text to ensure maximum legibility without the harshness of pure black. 
- **Surface:** The foundation is pure white, with subtle shifts to light grey for "container-over-surface" hierarchy.

## Typography

This design system utilizes **Inter** exclusively to leverage its exceptional legibility and neutral, systematic character.

- **Navigation & Names:** Use `headline-sm` with a semi-bold weight to establish clear hierarchy in the chat list and conversation headers.
- **Messages:** Message bubbles use `body-md`. It is critical to maintain a 22px line-height to ensure multi-line messages remain readable.
- **Previews & Metadata:** Use `body-sm` in a muted grey hex for message previews in the list view. 
- **Timestamps:** Use `label-sm` for timestamps and status text, ensuring they are distinct from the primary conversation flow.

## Layout & Spacing

The system follows an **8pt fluid grid** model. On mobile, the standard horizontal margin is 16px. 

Within the chat interface:
- **Conversation Flow:** A 12px gutter exists between the avatar and the message bubble. 
- **Vertical Rhythm:** Consecutive messages from the same sender have a 4px gap, while messages between different senders have a 12px gap.
- **Safe Areas:** Bottom navigation bars and input fields must respect device-specific home indicators with a minimum of 24px bottom padding.

## Elevation & Depth

Hierarchy is established through **Tonal Layering** rather than heavy shadows.

- **Level 0 (Base):** Pure white background for the main chat thread.
- **Level 1 (Navigation/Input):** Sticky headers and the bottom message composer use a subtle backdrop blur (glassmorphism) with a 0.5px border bottom/top (#000000 10% opacity) to separate them from the scrolling content.
- **Level 2 (Overlays):** Context menus and search bars use a very soft, diffused ambient shadow (Y: 4, Blur: 12, Opacity: 5%) to appear lifted.
- **Message Bubbles:** These are strictly flat. Depth is conveyed through color contrast (Blue vs. Grey) rather than elevation.

## Shapes

The shape language is dominated by **asymmetric roundness**.

- **Message Bubbles:** Use a 20px corner radius. To create a "tail" effect without using actual tails, the corner adjacent to the screen edge (right for outgoing, left for incoming) can be reduced to 4px for the final message in a cluster.
- **Cards & Inputs:** Chat list items and the search bar use a consistent 12px radius.
- **Avatars:** Strictly circular (50% radius) to differentiate human elements from the UI's geometric containers.
- **Buttons:** Primary call-to-actions are pill-shaped (full radius) to encourage interaction.

## Components

### Chat Bubbles
- **Outgoing:** Background `primary`, Text `white`. Aligned to the right.
- **Incoming:** Background `secondary`, Text `neutral`. Aligned to the left.
- **Grouped:** Only the final bubble in a series shows the sender's avatar or name.

### Message List Items
- **Structure:** 48px circular avatar on the left, followed by a vertical stack (Name + Preview), and a right-aligned timestamp/unread indicator.
- **Interactive State:** A subtle #F0F2F5 background fill on press.

### Search Bar
- **Styling:** Inset appearance with a 12px radius. Use a "magnifying glass" icon and a light grey placeholder text.

### Bottom Navigation
- **Styling:** 3-5 icons maximum. Use active/inactive states through color (Primary vs. Muted Grey). Do not use labels if the icons are universally understood (e.g., Chat, People, Settings).

### Input Field
- **Design:** The message composer should grow vertically (up to 5 lines) before scrolling. It includes a "plus" icon for attachments and a "send" button that only turns `primary` blue when text is present.