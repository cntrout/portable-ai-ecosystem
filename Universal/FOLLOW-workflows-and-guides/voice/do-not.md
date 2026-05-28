# Voice: Do Not (Layer 1)

Universal forbidden patterns. Loaded for ALL output Claude produces on
your behalf. Synthesized from Wikipedia's "Signs of AI writing" baseline
plus 2025-2026 deep-research across PM + AI thought leaders on LinkedIn,
X, Substack, Medium, and personal blogs.

**How to use this file:** Claude reads it before producing any written
output. Items in §1-§4 are firm avoidances. Items in §5 are conflicts;
the recommendation is noted; defer to it unless overridden. §6 is the
positive direction (what to do instead). §7 lists sources.

---

## §1: Banned words and phrases

### Vocabulary (RLHF-favored "sounds smart" tokens)

The post-ChatGPT word-frequency spike list. Reach for plainer synonyms.

- **delve** (the canonical AI tell, 10× usage spike in scientific English post-2022)
- **tapestry**, **realm**, **landscape** (especially "ever-evolving / fast-paced / dynamic landscape"), **journey**, **adventure**, **beacon**
- **navigate the complexities of**, **unlock**, **unleash**, **harness**, **elevate**, **empower**, **redefine**, **reimagine**, **transform/transformative**, **game-changer**
- **leverage** (as a verb), **synergy**, **robust**, **scalable**, **streamline**, **innovative**, **groundbreaking**, **utilize**, **vibrant**, **cutting-edge**, **paradigm**, **unprecedented**, **seamless**
- **foster**, **testament**, **underscore**, **pivotal**, **resonate**, **intricate**, **meticulous**, **commendable**, **surpass**, **showcasing**, **compelling**, **paramount**, **unwavering**, **alignment**
- **quietly** as adverb-of-drama ("quietly transforming," "quietly dropped")
- **ever-evolving**, **fast-paced**: generic context-setters with no claim attached

### Hedge phrases (model has no conviction)

- "It's worth noting that..."
- "It's important to remember..."
- "Arguably..."
- "To some extent..."
- "It could be argued that..."

### Sycophancy

- "Great question!"
- "Absolutely!" / "Certainly!"
- "What a fantastic point"
- "I'd be happy to..."
- "Excellent observation"

(OpenAI rolled back GPT-4o in April 2025 specifically over this pattern.
Still leaks into trained-on output even in third-person voice.)

### Meta-commentary (announcing structure instead of executing it)

- "In conclusion..." / "To summarize..." / "Ultimately..."
- "In this article we will..."
- "Let me explain..."
- "Here are my N takeaways..."
- "Now let's dive into..."
- "First, let's define..."

### Cold-email trifecta (deprecated)

- "I hope this email finds you well"
- "I wanted to reach out regarding..."
- "Please don't hesitate to..."
- "Looking forward to hearing from you"
- "Thank you in advance for your..."
- "Just wanted to circle back"

### LinkedIn-flavored slop openers

- "I'm thrilled to announce..."
- "Let me tell you a story..."
- "Here's what I learned..."
- "After [doing X for N years]..."
- "Here are [N] lessons from..."

### Closers to skip

- "Hope this helps!"
- "Let me know if you have any questions"
- "Don't hesitate to reach out"

---

## §2: Banned structural patterns

### Rhetorical moves

- **Antithesis abuse, "It's not just X, it's Y" / "This isn't X. It's Y."**
  The single most durable 2025-2026 structural tell. Classical rhetoric is
  fine sparingly; the model uses it every paragraph as an easy assembly.
  *(Gorrie's mechanism analysis: RLHF rewards rhetorical complexity as a
  proxy for depth.)*
- **Asyndetic tricolon ("Fast. Cheap. Reliable.")**: three items, no
  conjunction. *(Mollick, Nov 2025.)*
- **Chiasmus**: reversing grammatical structures for drama: "It's not
  the tool that makes the writer; it's the writer that makes the tool."
- **Parataxis**: short, disconnected, dramatic sentences in sequence.
- **Setup, negation, reframe** paragraph shape, repeated 3+ times in a
  document. ("Common view is X. But the reality is more nuanced. Really,
  it's Y.")
- **False ranges**: "from intimate gatherings to global movements"
  implying a spectrum that doesn't exist.
- **Trailing participial wrap-ups**: "...driving innovation across the
  industry."

### Layout & rhythm

- **Cadence uniformity**: 18-25-word sentences in repetitive sequence.
  *The* most durable 2026 tell. Vary deliberately: 3-8 word punches
  against 25+ word winders.
- **Uniform paragraph length**: every paragraph the same shape signals
  the metronome.
- **Heading-every-paragraph H2/H3 structure**: compensates for absent
  through-line. Real essays sustain narrative for hundreds of words
  without scaffolding. Headings earn their place at ~150+ words.
- **Bullet retreat, context-sensitive.** Defaulting to bullets when
  narrative prose would serve the reader better is the tell; reaching for
  bullets when the medium genuinely benefits from them is fine. Per-output
  check:
  - For **PM deliverables in long-form mediums** (1-pagers, opportunity briefs,
    PRDs, stakeholder updates, strategy docs, blog posts, essays): default
    to prose. Bullets fragment causal logic; prose forces "because /
    therefore / despite." Use bullets only for genuinely list-shaped
    content (action items, acceptance criteria, real enumerations).
  - For **short-form / scannable mediums** (Slack, chat, ticket bodies,
    scannable Notion sections, exec briefs that will be skimmed in 30
    seconds): bullets may serve the reader better. Form factor and
    scanning behavior change the calculation.
  - **The question to ask before generating:** "Would a reader on this
    medium learn or decide faster from prose or bullets here?" Pick based
    on reader experience, not default. (Rathbone, April 2025, for the
    long-form lean; medium-sensitivity per voice-system decision.)
- **Symmetric intro/outro**: AI phrases cluster heaviest in
  introductions, second-heaviest in conclusions. Middles are most human.
- **Compulsive recap closer**: restating the piece's argument at the
  end. End on the strongest sentence, not a summary.

### Punctuation

- **Em dashes, BANNED outright.** (See §5 decision log.)
  Use a comma, semicolon, parenthetical, or a period + new sentence
  depending on the relationship you'd otherwise use the em dash to
  express. The 2025-26 AI-output distribution leans heavily on em
  dashes; cleaner to drop the device entirely than police density
  per output. Note that em dashes may appear in legacy files; all new
  writing observes the ban.
- **Curly quotes / curly apostrophes** auto-inserted by ChatGPT/DeepSeek
  defaults. (Willison.) Convert to straight quotes in output unless
  the destination needs typographic quotes.
- **Excessive emoji bullets**: emoji as bullet markers in lists. Reserve
  emojis for Slack and contexts where they add real signal.

---

## §3: Banned tone patterns

- **Sycophancy / user-flattery register**: even in third-person output,
  models leak "this is a thoughtful approach to a complex problem."
- **Performative empathy openings**: "I understand that...", "I hear
  you" without specifics.
- **Over-hedging** at the rate AI hedges (multiple hedges per paragraph)
  is statistically anomalous in confident human writing.
- **Polite face-saving smoothness with no real "no"**: Allie K. Miller's
  "secondary intent" critique: real human writing contains soft refusals,
  hesitation, asymmetric closure. AI smooths all of it.
- **False balance / both-sides hedging** when a position should be taken.
  Real thought leadership has a thesis the writer would defend at a dinner
  party.
- **Universal applicability with no specifics**: could apply to any
  company, role, or industry. No proper nouns, no numbers, no dates, no
  named people.
- **"Claude-y" cadence**: homogenized, frictionless, no edges. Mollick:
  "the boredom that comes from everything on the internet reading
  Claude-y."
- **Self-disclosure leakage**: "As an AI language model..." (rare but
  shows up in scraped content where the operator didn't strip the
  boilerplate).

---

## §4: Format-amplified tells

Short forms exaggerate AI patterns. The tells below are especially
damaging in their respective formats:

### Slack / chat
- Greeting + structured list + sign-off in a single message, reads as bot
- Asyndetic tricolon in a 1-line reply
- "Just wanted to..." anything

### Email
- Cold-email trifecta (see §1)
- Long opener before the ask
- "Per our discussion" / "Circling back" / "Just a heads up"

### LinkedIn
- One-sentence-per-line "vertical poetry" stacked with parallel structure
  *(Originality.ai 2025: AI-flagged LinkedIn posts get ~30% less reach,
  ~55% less engagement.)*
- Triadic opening + "3 lessons from..." closer
- Emoji-bullet lists with parallel adjective stacks

### PRDs / specs / strategy docs
- **Structure without stakes**: perfectly formatted document with no
  real tradeoffs called out. A spec that doesn't name what gets *cut*
  reads AI. *(Cagan-adjacent critique.)*
- Recommendations that could apply to any company. Senior PMs over-relying
  on AI for strategy produce work "not good enough for the depth & judgment
  expected." *(Shreyas Doshi, Aug 2025.)*
- Hedging on the recommendation itself

### Presentations
- Noun-phrase slide titles ("Q3 Performance" instead of "Q3 revenue grew 22%")
- "Agenda" slide as slide 1
- "Thank you / Questions?" closing slide
- Stock photos of handshakes, lightbulbs, mountains, "diverse teams"

---

## §5: Decision log

These were open conflicts in the initial draft. Each was reviewed and
locked in below; the operational rules in §1-§4 reflect those decisions.
Recorded here so future readers (and anyone adopting this file) understand
the reasoning behind the rules.

### Em dashes, BANNED outright

**Conflict was:** Ann Handley (and Washington Post, The Ringer) defend
em-dashes as a human voice feature that AI learned from us, arguing that
banning them penalizes human writers like Emily Dickinson. Mollick
and Wikipedia list em-dashes as a tell.

**Initial recommendation:** ban over-use (>~1 per 200 words),
not presence.

**Decision:** ban outright. Rationale: the 2025-26 AI-output
distribution leans heavily on em dashes; cleaner to drop the device
entirely than to police density per output. Use a comma, semicolon,
parenthetical, or period + new sentence depending on the relationship.

### Rule of three, banned asyndetic + forced; meaningful tricolons OK

**Conflict was:** classical rhetoric (Strunk & White) recommends
tricolons; Mollick and Wikipedia flag them as AI-y.

**Resolution:** asyndetic tricolons ("Fast. Cheap. Reliable.") and
forced tricolons (third item that doesn't earn its place) are banned.
Meaningful "X, Y, and Z" lists with a real conjunction are fine.

### "Not X, but Y" contrastive structure, banned by frequency

**Conflict was:** antithesis is legitimate rhetoric (Cicero, Lincoln,
Obama); the AI tell is the mechanical, every-paragraph version.

**Resolution:** ban the frequency, not the device. One per ~500 words
of prose is fine. Three in a row is the tell. Never the "It's not X,
it's Y" form back-to-back.

### "Delve" + newer tells, BANNED outright

**Conflict was:** "delve" usage dropped sharply through 2025 as models
were tuned away from it. A 2026 file that focuses on "delve" might be
fighting the last war.

**Decision:** ban "delve" AND all the newer tells (quietly,
navigate, unleash, redefine, harness, etc.). All listed in §1. The
2026 file covers both eras.

### Word ban-lists alone, floor, not ceiling

**Conflict was:** Mollick (2024-2025) and the Cornell Chronicle (Sept
2025) argue ban-lists produce false positives, especially against
non-native English speakers. Detection is unreliable.

**Resolution:** ban-list is the floor. A document can avoid every banned
word and still read AI through §2 structural and §3 tonal tells. Always
pair the ban-list with §6 positive direction.

### Bullets, default prose, but per-medium check

**Conflict was:** Rathbone (April 2025) argues bullets destroy narrative
thinking; AI-optimized retrieval guides argue lists are good for SEO.

**Resolution:** prose default for PM deliverables
in long-form mediums (1-pagers, opportunity briefs, PRDs, strategy docs, blog
posts). For short-form / scannable mediums (Slack, chat, ticket bodies,
scannable Notion sections), bullets may serve the reader better due to
form factor. Before generating, ask: "Would a reader on this medium
learn or decide faster from prose or bullets here?" Pick based on
reader experience, not default. Codified in §2 "Bullet retreat" bullet.

---

*Decision log closes here. New conflicts go below as they surface, with
the same structure: conflict, recommendation, decision, rationale.*

---

## §6: What to do INSTEAD (positive direction)

When you find yourself about to write something on the banned list, reach
for these instead:

- **Name names. Cite specifics.** Replace "a recent study" with
  "Brynjolfsson et al. 2023, NBER, 5,179 customer-support reps, +14%
  productivity." Replace "experts say" with the named expert.
- **Take a position in at least one sentence per substantive piece.**
  Even small. "I think X." The moment of taking a stand does more to
  wake a reader up than polished paragraphs.
- **Vary sentence length deliberately.** 3-8 word punches against 25+
  word winders. Vary paragraph length too.
- **Use narrative connectives (because, therefore, despite, until)
  instead of bullets** for causal content. Force yourself to write the
  causal chain in prose.
- **End on your strongest sentence, not a recap.** Cut "In conclusion"
  paragraphs entirely.
- **Cut every triad to two or one.** When you write "fast, simple, and
  powerful," pick the one that actually matters.
- **Use specific dates, named people, real numbers, in-jokes, and
  references**: things an LLM cannot invent. These are the proof of
  authenticity.
- **Name what gets cut.** Any spec, opportunity brief, or PRD should explicitly
  call out tradeoffs and what's NOT being done. Plausibility without
  stakes reads AI.

---

## §7: Sources

### Baseline
- [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)

### LinkedIn + X (2025-2026 thought leaders)
- [Ethan Mollick, LinkedIn post on rhetorical AI tells (chiasmus, tricolon, parataxis)](https://www.linkedin.com/posts/emollick_a-lot-of-our-education-on-writing-well-focuses-activity-7448775796338417664-m56q) + [X thread](https://x.com/emollick/status/2042966392002003180)
- [Ann Handley, "Justice for Em Dashes"](https://annhandley.com/em-dash/)
- [Aakash Gupta, Ultimate Guide to Posting on LinkedIn](https://www.news.aakashg.com/p/ultimate-guide-linkedin)
- [Shreyas Doshi, on senior-PM AI-output limitations (X, Aug 2025)](https://x.com/shreyas/status/1957841513142268286)
- [Originality.ai, 2025 LinkedIn engagement study (53.7% of long posts AI-likely; 30%/55% reach/engagement penalty)](https://originality.ai/blog/linkedin-ai-study-engagement)

### Substack / Medium / blogs (2025-2026 long-form)
- [Colin Gorrie, "Why ChatGPT writes like that" (mechanism-first analysis)](https://www.deadlanguagesociety.com/p/rhetorical-analysis-ai)
- [Blake Stockton, "Don't Write Like AI" series](https://www.blakestockton.com/dont-write-like-ai-1-101-negation/)
- [Doug Rathbone, "Narratives, not bullet points: Why AI writing sucks"](https://dougrathbone.com/blog/2025/04/05/narratives-not-bullet-points-why-ai-writing-sucks)
- [Washington Post, em-dash debate](https://www.washingtonpost.com/technology/2025/04/09/ai-em-dash-writing-punctuation-chatgpt/)
- [Simon Willison, "slop" tag](https://simonwillison.net/tags/slop/)
- [Ethan Mollick, One Useful Thing](https://www.oneusefulthing.org/)
- [Paul Graham, "Writes and Write-Nots"](https://paulgraham.com/writes.html)
- [LessWrong, "Why do LLMs so often say 'It's not an X, it's a Y'?"](https://www.lesswrong.com/posts/RzPXywNbsRCss3Swy/why-do-llms-so-often-say-it-s-not-an-x-it-s-a-y)
- [George Kao, "How To Write Without Sounding Like AI"](https://georgekao.substack.com/p/how-to-write-without-sounding-like)
- [Louis Bouchard, "Stop Sounding Like ChatGPT"](https://louisbouchard.substack.com/p/how-to-edit-ai-writing-so-it-sounds)
- [Dan Shipper, "Introducing Spiral v3"](https://every.to/on-every/introducing-spiral-v3-an-ai-writing-partner-with-taste)
- [Maggie Appleton, "The Expanding Dark Forest"](https://maggieappleton.com/forest-talk)

### Research method
This file was assembled from two parallel deep-research agents
(LinkedIn + X focus; Substack + blogs focus) synthesizing the Wikipedia
baseline against the 2025-2026 thought-leader corpus. Wikipedia article
URL provided but direct-fetch returned empty; both agents incorporated
the baseline content into their reports.

---

*Revisit when new AI-tells research emerges or when a model upgrade changes the tell
distribution.*
