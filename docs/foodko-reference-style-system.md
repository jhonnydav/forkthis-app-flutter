# FoodKo Reference UI Style System

Source: `codex-clipboard-1b529b2d-eeba-44be-ab84-fc6c3531980b.png`

This document extracts the visual system visible in the supplied reference. Color values are representative samples from the rendered image, so they should be treated as implementation tokens rather than original source-design values.

## 1. Visual Direction

The reference uses a warm, minimal food-commerce style:

- Warm off-white page canvas with bright white content surfaces.
- A vivid orange is the only dominant brand accent.
- Near-black typography creates a strong hierarchy without heavy decoration.
- Food photography carries most of the visual richness.
- Large rounded surfaces, restrained borders, and very soft shadows make the interface feel approachable.
- Dense transactional screens still preserve whitespace through consistent section gaps and compact type.
- Icons are simple outline icons; orange marks active, selected, or additive actions.
- There are no gradients. Color is flat and photography is saturated.

## 2. Color System

### Core palette

| Token | Value | Usage |
| --- | --- | --- |
| `brand.primary` | `#FB5702` | Primary buttons, selected tabs, add buttons, map pins, badges |
| `brand.primaryPressed` | `#DE4800` | Pressed and high-contrast orange state |
| `brand.primarySoft` | `#FFF0E8` | Selected backgrounds, subtle highlights, focus wash |
| `canvas.base` | `#F7F2ED` | App background and space between surfaces |
| `canvas.subtle` | `#FCF9F6` | Bottom navigation and secondary background areas |
| `surface.primary` | `#FCFBF9` | Cards, sheets, app bars, checkout panels |
| `surface.strong` | `#FFFFFF` | Inputs and image-backed information panels when extra separation is needed |
| `text.primary` | `#201E1F` | Titles, prices, totals, primary labels |
| `text.secondary` | `#6F6A66` | Supporting descriptions and metadata |
| `text.tertiary` | `#92908E` | Placeholder text and low-priority metadata |
| `border.subtle` | `#E8E0DA` | Input outlines, list dividers, quantity controls |
| `state.warning` | `#FBB20D` | Ratings and loyalty progress |
| `state.success` | `#6E9D35` | Delivered status and positive confirmation |
| `state.error` | `#C93824` | Destructive or failed states; not prominent in the reference |

### Color balance

- 70-75% warm canvas and whitespace.
- 15-20% white elevated surfaces.
- 5-10% orange brand actions and emphasis.
- Less than 5% status colors and decorative food colors.
- Keep orange localized. It should identify the next action, not tint entire screens.

### Contrast note

The sampled `#FB5702` has approximately `3.2:1` contrast against white. It works well for large bold button text and non-text controls, but it is below WCAG AA for small white text. For small labels on orange, use `#DE4800` or a darker tested orange; for orange text on white, use `#C93F00`.

## 3. Typography

The style is a rounded geometric sans similar to **Poppins**, **Manrope**, or **Avenir Next**. Use one family throughout; Poppins is the closest visual match.

| Style | Size / line height | Weight | Use |
| --- | --- | --- | --- |
| Display | `28 / 34` | 700 | Restaurant and product names |
| Screen title | `20 / 26` | 600 | App-bar and section-level titles |
| Section title | `16 / 22` | 600 | Categories, summaries, card headings |
| Card title | `15 / 20` | 600 | Product names and order labels |
| Body | `14 / 21` | 400 | Descriptions and form content |
| Body strong | `14 / 20` | 600 | Button labels and emphasized metadata |
| Meta | `12 / 17` | 400-500 | Delivery times, ratings, helper text |
| Micro | `10 / 14` | 500 | Badges and compact captions |
| Price | `18 / 24` | 700 | Product pricing and checkout totals |

Rules:

- Use sentence case, not all caps.
- Use `0` letter spacing.
- Limit most text blocks to two lines.
- Use weight and spacing for hierarchy; do not introduce extra colors or oversized type.

## 4. Spacing System

Use a 4-point base grid. The visible rhythm is built primarily from 8, 12, 16, 24, and 32 pixels.

| Token | Value | Typical use |
| --- | --- | --- |
| `space.1` | `4` | Icon-to-micro-label gap |
| `space.2` | `8` | Tight metadata, inline icon gap |
| `space.3` | `12` | Related controls, chip gaps |
| `space.4` | `16` | Card padding, mobile side padding, list row gaps |
| `space.5` | `20` | Comfortable horizontal screen inset |
| `space.6` | `24` | Section separation and large card padding |
| `space.8` | `32` | Major content-group separation |
| `space.10` | `40` | Hero-to-content separation |
| `space.12` | `48` | Large empty-state or campaign spacing |

### Consistency rules

- Screen horizontal inset: `20px`; allow `16px` on narrow devices.
- Card internal padding: `16px`; use `20-24px` for checkout and profile summaries.
- Gap between cards: `16px`.
- Gap between major sections: `24-32px`.
- Heading to supporting copy: `8px`.
- Supporting copy to controls: `16-20px`.
- List row vertical padding: `12-16px`.
- Fixed bottom CTA clearance: content bottom padding equals CTA height + navigation/safe area + `24px`.
- Avoid arbitrary values such as 13, 18, 22, or 27 unless aligning an image crop.

## 5. Shape, Border, and Elevation

| Element | Radius | Border / elevation |
| --- | --- | --- |
| Large card or bottom sheet | `22-24px` | Soft shadow, no visible border |
| Standard card | `16-20px` | `1px #E8E0DA` or a soft shadow, not both strongly |
| Primary button | `12-14px` | Flat orange fill |
| Input / search field | `12px` | White fill or `1px #E8E0DA` |
| Chip / segmented tab | `18-999px` | Soft neutral fill; selected item orange |
| Thumbnail | `12-16px` | Image clipped to shape |
| Icon action | Circle | `40-44px` touch target |

Recommended shadows:

```text
card:       0 8 24 rgba(48, 34, 24, 0.08)
floating:   0 12 30 rgba(48, 34, 24, 0.12)
bottom nav: 0 -6 24 rgba(48, 34, 24, 0.06)
```

Shadows should be warm gray, broad, and low-opacity. Avoid sharp black drop shadows.

## 6. Layout Patterns

### App bars

- Height: `56-64px` plus the platform safe area.
- Back action at the leading edge; one or two utilities at the trailing edge.
- Transparent or surface-colored at rest.
- On scroll, transition to a white/warm-white bar with a subtle bottom shadow.

### Cards and sheets

- Content is grouped into one clear surface, not nested cards.
- Image-first product cards use a strong crop, followed by title, metadata, price, and action.
- Bottom sheets overlap hero imagery with a `22-24px` top radius.
- Checkout and profile cards use dividers only where they improve scanning.

### Buttons

- Primary: full-width orange fill, white semibold text, `48-52px` height.
- Secondary: white or transparent with a subtle border and dark text.
- Add action: `36-40px` orange circular icon button.
- Text and icons remain centered; loading states do not change the button dimensions.

### Inputs and controls

- Search field height: `44-48px`.
- Quantity stepper height: `40-44px`, with equal-width minus/value/plus areas.
- Radio selection uses an orange outer ring and orange center dot.
- Chips use neutral fills and dark text; selected chips switch to orange with white text.

### Bottom navigation

- Height: `72-80px` plus safe area.
- Five evenly distributed destinations.
- `22-24px` outline icons with `11-12px` labels.
- Active icon and label are orange; inactive items are near-black/gray.
- Badges are small orange circles with white numerals and must not shift icon alignment.

## 7. Image Direction

- Use bright, appetizing food photography with true-to-life color.
- Prefer clean warm-white, pale stone, wood, or brand-orange backgrounds.
- Use close framing so the product is immediately identifiable.
- Keep important food details away from overlaid controls and clipped corners.
- Use `cover` for hero media and `contain` or a carefully art-directed crop for isolated menu items.
- Do not add dark overlays unless required for readable text.

## 8. Motion and Interaction

- Page transition: `220-300ms`, ease-out, with a subtle horizontal slide and fade.
- Card/row press: scale to `0.98` for `100-140ms`.
- Bottom-sheet entry: `300-360ms` using a decelerating curve.
- Cart add feedback: quick scale pulse and badge count cross-fade.
- Scroll app bar: background/shadow fade over `160-220ms`.
- Respect reduced-motion preferences and keep navigation usable without animation.

## 9. Component Inventory

The reference establishes these reusable components:

- Back/title/action app bar
- Search field and separate filter button
- Map pin and floating food marker
- Restaurant hero sheet
- Category chip row
- Full-width primary CTA
- Promotional offer panel
- Loyalty progress card
- Payment method radio row
- Checkout cost summary
- Order status and order-history card
- Product detail hero with quantity stepper
- Profile summary and address block
- Category tile grid
- Menu row with image, price, and add action
- Recommendation card
- Five-item bottom navigation with badge

## 10. Implementation Guardrails

- Start every screen with the same `20px` horizontal inset and 4-point spacing scale.
- Use one card radius family and one button radius family across the product.
- Use orange only for selection, active navigation, important status, and primary actions.
- Keep one obvious primary CTA per viewport.
- Maintain minimum `44x44px` touch targets.
- Do not place a card inside another card.
- Keep fixed CTAs above the bottom navigation and platform safe area.
- Validate every screen at narrow mobile, large mobile, tablet, and desktop/web preview widths.

