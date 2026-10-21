# RbxMulti native interface

The interface is a quiet macOS utility: account identity and process status come first, with diagnostic activity on a separate tab. The UI/UX Pro Max and Impeccable refinement pass preserves native controls and restrained purple accents.

## Visual rules

- System typography: 25-point page title, 17-point section emphasis, 15-point account names, 13-point body, and 11–12-point supporting text.
- Semantic macOS backgrounds, separators, and primary text support light and dark appearances. Secondary text uses 0.38 white in light mode and 0.70 white in dark mode.
- Use 24-point outer gutters, 48-point account avatars, and 14-point group/avatar corner radii. Keep account rows together in one bordered surface rather than individual cards.
- Start at 720 × 610; support a 620 × 510 minimum window. Long names truncate without pushing actions offscreen.
- Use native buttons, toggles, menus, focus behavior, and explicit accessibility labels for icon-only actions. Confirm player-closing and link-restoration actions.

## Behavior and language

- Run as a menu-bar utility. Manual opening and Show accounts present the window. Roblox URL delivery hides it, including on cold launch. Closing the window leaves the launcher and players running.
- Player running means the process exists; it does not assert that a game connection is healthy. Warn separately about identity changes and loss of session isolation after an update.
- Keep account names and avatars prominent. Missing identity data gets a neutral fallback, not a fabricated username.
- Keep diagnostics in Activity. Add account reveals short browser-login guidance rather than creating an empty account slot.
- Persist Keep Mac awake. Quit stops the manager’s wake assertion but does not terminate players.

## Verification

Window-policy and actual macOS URL-delivery fixtures cover manual open, cold/warm links, close-to-background, and explicit reopening. Native render fixtures cover dark, compact light, and empty states; a live installed-app inspection covers real names and avatars. Web-only design detectors do not apply to these SwiftUI/AppKit views.
