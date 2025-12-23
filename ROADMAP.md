# Sometimes — Future Roadmap

A living document for features that preserve the app's philosophy: **serendipity over optimization**.

---

## Year-End Anthology

**Concept**: At year's end, users receive a beautifully typeset PDF/chapbook of the poems that "found them" throughout the year.

**Implementation**:
- Generate anthology from user's favorites (those with `SaveContext`)
- Include delivery context: "This found you on a rainy Tuesday morning in March"
- Chronological or seasonal organization
- Export as PDF with proper typography (Georgia, generous margins)
- Optional: physical print partnership (see Chapbook section)

**Data Required**: Already captured via `SaveContext` — weather, timeOfDay, season, dayOfWeek, savedAt

**Complexity**: Medium — PDF generation, export UI, typography

---

## Seasonal Drops

**Concept**: Time-limited collections that appear during specific windows, adding freshness without gamification.

**Examples**:
- "Winter Evenings" (Dec 1–Jan 31): 20 poems for long nights
- "Spring Awakening" (Mar 20–Apr 30): 15 poems of renewal
- "Summer Reading" (Jun 21–Aug 31): Longer, contemplative pieces

**Implementation**:
- `PoemCollection` and `UnlockCondition` models already in place
- Add `collections` field to poems.json entries
- Scoring gives small bonus (+5) to in-season collection poems
- No UI fanfare — poems simply become eligible during window
- Archive shows subtle indicator: "From Winter Evenings"

**Complexity**: Low — infrastructure exists, needs content curation + minor UI

---

## Physical Chapbook Partnership

**Concept**: Partnership with letterpress/indie publisher to offer annual "Sometimes Anthology" as physical object.

**Implementation**:
- Curated selection of year's most-delivered poems
- User-personalized option: their favorites + contexts
- Print-on-demand via partner (Blurb, Lulu, or indie press)
- Revenue share supports app + pays poets' estates where applicable

**User Flow**:
1. "Create Your Anthology" appears in December
2. Select poems from favorites (or use all)
3. Preview typeset layout
4. Purchase through partner (app takes commission)

**Complexity**: High — requires partnership, print integration, payment handling

---

## Poem Annotations

**Concept**: Users can add a personal note to favorited poems — a journal entry of what it meant in that moment.

**Implementation**:
- Add `userNote: String?` to `DeliveredPoemEntity`
- Small "Add Note" button in poem detail (only for favorites)
- Notes included in Year-End Anthology
- Never synced, never analyzed — purely personal

**Data Model Change**:
```swift
// In DeliveredPoemEntity
var userNote: String?
var noteAddedAt: Date?
```

**Complexity**: Low — simple text field, persisted locally

---

## Anti-Widget

**Concept**: Home screen widget that embodies "an app that doesn't want your attention."

**Three States**:
1. **Empty** (default): Just the word "Sometimes" — no poem, no urgency
2. **Active** (after delivery): First line of today's poem, fades after 4 hours
3. **Read** (after tap): Small dot indicating poem was opened, then returns to empty

**Implementation**:
- WidgetKit extension with three sizes
- Shared App Group for poem data
- Timeline: refresh on delivery, return to empty after 4 hours
- No deep linking spam — tapping opens archive, not poem

**Complexity**: Medium — requires Xcode target setup, App Group, timeline logic

---

## Poet Deep Dives

**Concept**: After receiving 5+ poems from one poet, unlock a brief bio/context.

**Implementation**:
- Track poet delivery count in `PoemStore`
- Unlock threshold: 5 poems from same poet
- Bio appears as footer in poem detail: "Emily Dickinson (1830–1886) wrote nearly 1,800 poems..."
- No gamification UI — information simply becomes available

**Data Required**: Poet bios (separate JSON or embedded), delivery tracking

**Complexity**: Low-Medium — tracking exists, needs bio content + conditional UI

---

## Quiet Notifications

**Concept**: Notification that doesn't demand attention — appears silently, no badge.

**Implementation**:
- Already using `.passive` interruption level ✓
- Consider: notification grouping by week
- Consider: notification summary ("3 poems arrived this week")
- Badge always 0 — no red dot anxiety

**Complexity**: Already implemented — refinements only

---

## Priority Order

1. **Poem Annotations** — Low effort, high personal value
2. **Seasonal Drops** — Infrastructure ready, needs content
3. **Anti-Widget** — Medium effort, high visibility
4. **Year-End Anthology** — High value, medium effort
5. **Poet Deep Dives** — Content-dependent, low urgency
6. **Physical Chapbook** — Partnership-dependent, long-term

---

*"The best features are the ones you forget are there."*
