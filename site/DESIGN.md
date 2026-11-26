---
name: RbxMulti Website
description: A clear product page for the RbxMulti macOS app.
colors:
  primary: "#a324b9"
  secondary: "#d52cf0"
  neutral-bg: "#f8f9fc"
  neutral-surface: "#ffffff"
  neutral-text: "#191c22"
  neutral-muted: "#626a78"
  neutral-border: "#e5e8ee"
  footer: "#171a20"
  desktop-surface: "#e4eaf1"
typography:
  display:
    fontFamily: "Plus Jakarta Sans, Inter, sans-serif"
    fontSize: "clamp(42px, 7.1vw, 88px)"
    fontWeight: 800
    lineHeight: 1.04
    letterSpacing: "-0.052em"
  body:
    fontFamily: "Plus Jakarta Sans, Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.8
  label:
    fontFamily: "Inter, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    letterSpacing: "0.12em"
rounded:
  sm: "8px"
  window: "10px"
  md: "14px"
  device: "21px"
  lg: "20px"
  pill: "999px"
spacing:
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "36px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#ffffff"
    rounded: "{rounded.pill}"
    padding: "15px 25px"
  button-primary-hover:
    backgroundColor: "#9120aa"
  card-release:
    backgroundColor: "{colors.neutral-surface}"
    textColor: "{colors.neutral-text}"
    rounded: "{rounded.lg}"
    padding: "19px 21px 22px"
---

# Design System: RbxMulti Website

## Overview

**Creative North Star: "A clear path to launch."**

The site follows the clean, light product-page reference the owner selected. It opens with the app identity and one direct action, explains the real product in a feature showcase, then presents actual releases and support links. The visual identity belongs to this website; the native macOS app keeps its existing system appearance.

The supplied RbxMulti icon anchors the page. Large black headlines, quiet neutrals, and purple-pink accents carry through the RbxMulti interface without adding claims or decorative noise.

**Key Characteristics:**
- Light canvas with sparse ambient particles
- Large, balanced headlines and readable body copy
- Purple-pink actions and violet details sampled from the RbxMulti interface
- A Studio Display behind a MacBook Pro, each showing the owner’s actual RbxMulti window screenshot
- Scroll-triggered entrance: the display slides in from the left and the MacBook Pro from the right; neither device floats continuously

## Colors

The palette pairs cool light surfaces and dark text with an accessible purple-pink action color and a brighter magenta accent from the app UI.

### Primary
- **Rbx Accent**: used for primary actions, links, and selected headline emphasis.

### Secondary
- **App Magenta**: used for smaller interface accents.

### Neutral
- **Cool Paper**: page background.
- **White Surface**: feature showcase and release cards.
- **Ink**: headlines and key labels.
- **Muted Slate**: secondary copy.
- **Soft Divider**: borders and separators.
- **Charcoal Footer**: footer surface.

## Typography

**Display Font:** Plus Jakarta Sans (with Inter, sans-serif fallbacks)
**Body Font:** Plus Jakarta Sans (with Inter and system sans-serif fallbacks)
**Label/Mono Font:** Inter, sans-serif for compact navigation and uppercase labels.

**Character:** Rounded, modern display headlines pair with clear body copy and compact interface labels.

### Hierarchy
- **Display** (800, 42–88px, 1.04): animated hero headline.
- **Headline** (800, 36–58px, 1.12): section titles.
- **Title** (700–800, 16–25px): preview window and release cards.
- **Body** (400, 14–18px, up to about 70ch): descriptions and help copy.
- **Label** (600–700, 12px): navigation, release tags, and supporting status.

## Layout

Use centered content containers with generous space between sections. The desktop navigation stays at the top; narrow screens replace links with an accessible menu. The showcase and release cards reduce to a single-column or compact two-column arrangement on phones. The mobile navigation keeps the direct download action visible.

## Elevation & Depth

Depth comes from subtle neutral borders and soft, offset shadows under the device showcase and release cards. Keep accents flat; reserve hover lift for interactive cards and buttons.

### Shadow Vocabulary
- **Showcase**: `0 20px 30px rgba(23,31,43,.14)` with a softer foreground shadow under the laptop.
- **Release card**: `0 8px 25px rgba(36,47,68,.035)`.

## Shapes

Cards use softly rounded corners (14–20px), the Studio Display and MacBook Pro use rounded aluminum frames, and compact actions use full pills. Fine neutral borders separate surfaces without heavy outlines.

## Components

### Buttons
- **Primary:** purple-pink pill with white text, 15px × 25px padding, and a small lift on hover.
- **Focus:** visible purple-pink outline with offset for keyboard users.
- **Text actions:** purple-pink or slate links with underlines on hover.

### Cards
- **Release cards:** white surfaces with a small icon illustration, release label, version, system requirement, and direct release link.
- **Archive card:** compact text-led surface with a round external-link action.

### Device Showcase
- **Frame:** layered device images cropped from the owner-provided reference, with the Studio Display behind a notched MacBook Pro. Keep the MacBook's slim silver base visible without drawing a keyboard.
- **Interface:** show the owner-provided RbxMulti app screenshot on both screens; do not recreate the interface. The MacBook screen uses the owner's supplied space-station wallpaper crop, with a simple camera notch and no media controls.
- **Motion:** when a section enters the viewport, reveal it; reset it after it leaves so the entrance replays on the next scroll into view. The Studio Display slides from the left and MacBook Pro from the right. Respect reduced-motion settings; no continuous looping or floating.

### Navigation
- **Desktop:** compact translucent light header, brand at left, section links and download action at right.
- **Mobile:** menu button reveals the same links; Escape and link selection close the menu.

## Do's and Don'ts

### Do:
- **Do** keep release versions and links tied to actual GitHub releases.
- **Do** label the HTML interface preview as illustrative.
- **Do** keep keyboard focus visible and honor reduced-motion preferences.

### Don't:
- **Don't** claim that a running player process means the game is connected.
- **Don't** add promises about preventing idle timeouts or guaranteeing rejoining.
- **Don't** use Roblox assets or imply affiliation with Roblox.
