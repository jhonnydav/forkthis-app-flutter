# Client Feedback Implementation Matrix

Source: `Discovery Product Requirement .csv.zip`, response submitted 2026-08-02.

This matrix distinguishes confirmed product decisions from tentative answers and content-delivery dependencies. The 2026-08-06 client answers confirm `ForkThis!` as the prototype name and positive momentum mechanics as part of the product feel.

| Client feedback | Product interpretation | Flutter status |
| --- | --- | --- |
| Organized, polished, inviting | Clear hierarchy, guided first-use experience, warm visual system | Implemented; guided tour added in this pass |
| No existing brand assets | Use approved project palette and bundled type | Implemented |
| Clean lines, vivid food photos, contrasting colors, bold consistent text | Photography-led restaurant and recipe UI | Implemented |
| Avoid bare, overly feminine, cluttered, or glitchy UI | Dense but calm transactional screens, no decorative dashboard clutter | Implemented |
| Real everyday food and people | Use supplied real-food photography; do not invent founder/person imagery | Implemented for food; people imagery awaits approved assets |
| No single priority audience | Keep everyday, metabolic, surgical, and post-op paths available | Implemented |
| First minute should feel organized and inviting | Auto-start a short, skippable tour on first Home arrival | Implemented in this pass |
| Recipes/orders and macros are the core | Keep fast hacks above the fold and show full nutrition on detail | Implemented; recipe macro completeness added in this pass |
| Healthy meals feel unappealing or out of reach | Lead with recognizable meals and realistic swaps | Implemented |
| 150-300 launch recipes | UI/data model must scale; actual approved content must be supplied | Data dependency; no fake recipes added |
| 30+ launch restaurants | Restaurant-first browse must handle 30+ entries | Implemented with a 32-item scale fixture; approved launch list still required |
| Organize by restaurant | Eat Out defaults to restaurant browse | Implemented |
| Every entry has macros, photo, and restaurant specifications | Required fields and visible nutrition details | Implemented in this pass |
| Possibly gender | Tentative, with no stated personalization purpose | Pending client confirmation; not collected |
| Medical context is optional and educational | Separate `No` and `Prefer not to say`; explain purpose and local storage | Implemented in this pass |
| Go straight to the app and walk through important features | Sub-second transition to Home, then auto-start tour | Implemented in this pass |
| Encouraging friend plus knowledgeable coach | Warm action-focused copy without false clinical claims | Implemented |
| Welcome users back without guilt | Return-after-lapse copy celebrates the comeback and offers one useful order/recipe | Implemented |
| Streaks, badges, and points fit if encouraging | Positive-only momentum points and behavior badges; no broken-streak or missed-day penalty language | Implemented |
| Avoid before/after photos and strict diet-culture language | Prohibited copy/image audit | Implemented; covered by regression test |
| Platform name | Brand the prototype as `ForkThis!` | Implemented |
| Founder presence is uncertain | Do not add founder names/photos as approved content | Pending client confirmation |
| If founders appear, use a short mission/accessibility bio | Add a neutral mission page without unapproved identities | Implemented in this pass |
| Avoid MyFitnessPal-style clutter and instability | Focused navigation, real empty/error states, large-text smoke tests | Implemented |

## Remaining External Inputs

- Approved launch restaurant list and the final 30+ restaurant content set.
- The 150-300 launch recipes with reviewed nutrition values and photography.
- Decision on whether gender has a real personalization purpose.
- Decision and approved copy/assets for founder presence.
- Production notification schedule, legal copy, and release permission strategy.

## 2026-08-06 Client Direction Update

The product's single job is now to guide users through real-life "ForkThis!" moments: eating out, cravings, low time, calories left, and returning after falling off track. The prototype should respond like an encouraging friend after a gap, with useful next meals and momentum language rather than guilt.

Implementation notes:

- `ForkThis!` is the app-facing name.
- Return-after-lapse copy says "You are back!!" and offers a new menu suggestion or recipe.
- Momentum points and badges are allowed, but only as positive reinforcement.
- Missed days never reset progress or create broken-streak language.
