# Voice: Format Augments

Layer 2 augment. Loaded together with `personal.md` for every output. Picks
the section matching the output's destination format.

If the format is ambiguous, ask before generating.

Format detection cues:
- "Send Alex an email" -> **email**
- "Reply on Slack" / "Draft a Slack message" -> **slack**
- "Write a 1-pager / opportunity brief / PRD / stakeholder update / blog post" -> **doc**
- "Create a Linear ticket / draft a Jira card" -> **ticket**
- "Build a slide / deck / presentation" -> **presentation**

---

## Email

**Brevity is the goal.** Most emails should be ≤4 sentences.

- **Subject:** action-oriented, scoped. ("Pilot launch, go/no-go
  by Thursday" not "Pilot update")
- **Opener:** direct. No "I hope this finds you well" / "I wanted to reach
  out regarding" / "Just wanted to circle back." Start with the ask or the
  update.
- **Body:** one ask or one update per email. Multiple asks: split into
  multiple emails or use a bulleted list with an explicit "I need from you:"
  prefix.
- **Format:** plain text preferred. Rich formatting only when content is
  genuinely structured (tables, code).
- **Sign-off:** match the recipient's recent sign-off. If unknown, use
  your natural close (set in `personal.md`). No "Best
  regards" boilerplate.
- **No emojis** in client/partner-facing emails by default. Match recipient's
  tone if they use them first.

**Avoid:**
- "I hope this email finds you well"
- "Just following up on..."
- "Please don't hesitate to..."
- "Looking forward to hearing from you"
- "Thank you in advance for your..."

## Slack

**Casual, fast, emoji-friendly.** Match the channel's existing tone.

- **No greetings on top-level messages.** Open with the substance. ("hey"
  is fine in DMs if it matches the recipient's pattern.)
- **Threading:** anything >2 messages goes in a thread, not stacked at
  top level
- **Emojis:** encouraged when they fit. Confirm-check for confirm, eyes for "I'll look,"
  hands-together for ask/thanks, fire for hot-take, etc. Don't force them.
- **Code blocks** for any technical content (URLs, commands, file paths,
  IDs). Inline `code` for short refs.
- **No corporate boilerplate.** "Per our discussion" / "Circling back" /
  "Just a heads up", skip. State the thing.
- **Tag people explicitly** when an ask is theirs, not implicitly.
- **Bullets are OK on Slack** when they serve scannability. Form factor +
  cluttered channels + sequential reading means a 3-item bulleted list
  is often more readable than prose. Use bullets when you'd otherwise
  wrap a single message around "first... second... third...", but don't
  reach for them reflexively. Same per-medium check as the rest of the
  voice system: "would the reader prefer bullets here?" If yes, use them.

**Avoid:**
- Asyndetic tricolons ("Fast. Cheap. Reliable."), read as bot in short form
- Greeting + structured list + sign-off in a single message, too formal
- "I hope you're having a great week", never

## Doc (Notion, Google Docs, Confluence)

Two sub-variants based on document intent:

### Doc, concise variant

**Use for:** 1-pagers, stakeholder updates, exec briefs, Notion meeting
recaps, partner-facing summaries.

- Lead with the TL;DR (1-3 sentences). The reader gets the answer in
  the first paragraph.
- Short paragraphs (≤4 sentences). Scannable.
- Headings only where they earn a navigation jump. Don't H2 every
  paragraph.
- Tables when content is genuinely comparative. Bullets for genuine lists.
- Cut adjectives. "We saw a 14% lift" not "We saw an impressive 14% lift."
- No emojis in customer-facing docs.

### Doc, detailed variant

**Use for:** opportunity briefs, PRDs, technical specs, deep-dive analyses,
research synthesis docs.

- Lead with a TL;DR even when the body is long.
- Evidence is cited specifically (study, chart name, dataset, date, sample
  size), see `do-not.md` "named specificity" rule.
- Prose for causal reasoning ("because," "therefore," "despite"). Bullets
  for criteria, acceptance lists, action items.
- Structure: Problem -> Evidence -> Hypothesis -> Recommendation -> Open
  Questions -> Next Steps (or the project's template equivalent).
- Headings earn their place. ≥150 words per section before a new heading.
- Diagrams where data or system structure is involved. Use
  `diagram-design` skill, output routes per the partition rule.
- No emojis.

**Avoid (both variants):**
- "In today's fast-paced landscape"
- "Navigate the complexities of"
- Triadic adjectives ("clear, concise, and compelling")
- "In conclusion" / "To summarize" / "Ultimately" wrap-ups, end on the
  strongest sentence, not a recap
- Heading-every-paragraph H2/H3 structure

## Ticket (Linear, Jira, ClickUp)

**Action-oriented, scoped, scannable for an engineer in a hurry.**

- **Title:** verb + object + scope. ("Add country filter to user-dropdown
  on submission flow" not "Dropdown update")
- **Problem statement:** 1-2 sentences. What's broken or missing, who
  cares.
- **Acceptance criteria:** bulleted, testable. This is the rare place
  where bullets are the right shape.
- **Context:** link to the source (opportunity brief, ticket, Notion doc, transcript),
  do NOT restate.
- **Sizing / labels:** match the project's `Reference/tracker-conventions.md`
  if it exists.
- **No emojis** unless the project's tracker convention explicitly uses
  them (some teams use bug / sparkles, match them).
- **No corporate prose.** Engineers read these in a list view. Words cost.

**Avoid:**
- "We need to consider..."
- "It would be great if..."
- "Please ensure that..."
- Restating context the linked doc already says

## Presentation (PowerPoint, Google Slides, Keynote)

**One idea per slide. Headlines are full sentences. Charts beat text.**

- **Slide titles are full sentences with a verb.** "Q3 revenue grew 22%"
  not "Q3 Revenue." Reader skims titles, knows the deck without reading
  body.
- **One idea per slide.** If two ideas, split. If five ideas, you have a
  doc, not a deck.
- **Body:** 3-5 bullets max OR a chart OR a diagram. NOT all three.
- **Charts > text** wherever data is involved. Use `diagram-design` skill
  for system / process / quadrant diagrams.
- **Speaker notes:** useful for spoken context the slide doesn't need.
  Don't duplicate the slide.
- **No emojis** in business decks.
- **No "thought leadership" register.** "Transforming the future of
  customer experience", never. "Pilot reduced support
  escalations 38%", yes.

**Avoid:**
- Slide titles that are noun phrases ("Q3 Performance")
- "Agenda" slide as slide 1 (cut it; the deck IS the agenda)
- "Thank you / Questions?" slide (end on the headline)
- Stock photos of handshakes, lightbulbs, mountains, "diverse teams"
- "Synergy," "leverage," "harness," "unlock," "empower", see `do-not.md`

---

*Refine as patterns emerge.*
