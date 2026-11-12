# Notes that can be spoken

Write the words the presenter can actually say. Notes are neither a paper abstract nor a production log. Put animation implementation, estimated duration, comments, sources, and review questions in project metadata or review files, not in the spoken script.

## Voice and length

Start from plain verbs, short clauses, and natural transitions. Use contractions where they fit the speaker. Prefer “Now the model answers other harmful questions, too” to “The harm extends beyond replication of the provided example.” Keep the important method term; simplify the sentence around it.

Short ordinary slides need less script than a narrated animation. Calibrate to the speaker's accepted examples and rehearsal pace instead of imposing the same word count on every slide. A long script on a simple claim creates fatigue; a long moving demonstration may need enough narration to guide each stage.

Use numbers in the form the speaker finds easiest to scan. This profile prefers numerals. Expand an acronym when the audience first needs it, then use the short form consistently. Do not replace an actual method name with an emoji. Scientific pronunciation and proper nouns should be checked against the source, not guessed from transcription errors.

## A useful slide opening

Most evidence slides need three beats:

1. **Orient:** say what the audience is looking at.
2. **Guide:** point out the relevant comparison or sequence.
3. **Conclude:** state the consequence.

For example:

> Here we plot the safety score as the answer unfolds. The higher the line, the safer the response so far. Notice how the score drops when the answer starts giving harmful details.

For a table:

> Look at the two highlighted rows. Our method keeps safety high, while the capability scores stay comparable.

This gives the audience a reading task without narrating every cell. Use the same approach for plots, screenshots, attention maps, and multi-step training diagrams. Let the relevant visual appear before referring to it.

## Transitions are part of the explanation

Read the preceding and following notes before editing one slide. A sentence moved by the speaker may already solve the next transition. Do not reinsert it just because an older version had it there.

| Abrupt or formal | More natural direction |
|---|---|
| “Our first work is Safety Basin.” | “Let’s start by measuring how finetuning changes safety. That led us to the safety basin.” |
| “We now ask how architecture can help, across two practical visual challenges.” | “That finishes the safety part. Next, let’s look at how the model itself handles difficult visual inputs.” |
| “We move to scaling model capabilities.” | “We have looked at the architecture. Now let’s turn to the two resources that shape what it can do: data and compute.” |
| “Repeating this as the response grows…” | “We check again as the answer gets longer.” |
| “One label for the whole response misses what is happening inside it.” | “But an answer can start safely and turn harmful halfway through.” |
| “To earn a good reward, the model has to change course.” | “The model gets a better reward when it catches the mistake and corrects itself.” |

These are patterns, not required scripts. Keep each transition scientifically faithful. Do not claim one paper's mechanism solves another paper's problem just to make the story sound smooth.

## Questions, humor, and emphasis

Use a question when it exposes a real gap: “So does safer just mean saying no more often?” Then answer it with the evidence. Avoid constant rhetorical questions or a fake objection followed by “No” on every slide. A direct sentence is often cleaner.

A brief joke can relax an opening or acknowledgements transition. It should not obscure the stakes or require the audience to know an inside story. After a joke, return to the argument quickly.

Vary takeaway openings: “To wrap up this work…”, “The main result is…”, “Together, these experiments show…”. Avoid beginning every slide with “We propose” or “We show.” Keep strong, accurate verbs for contributions: discover, establish, unify, develop, demonstrate. “Explain” is not automatically weak; choose the verb that describes the actual intellectual contribution.

## Scope without deflating the result

Give a short affirmative contribution first, then its boundary. For an agent-safety question:

> This work gives us a foundation for safer model adaptation and reasoning. Agent systems add tool access and long action chains, so the next step is to apply those ideas at that level too.

This is clearer than either “No, we did not solve it” or a claim that a model-level defense solves every agent failure. Match the confidence to the evidence. Distinguish historical SOTA, tested families, average guarantees, and future proposals.

## Keynote formatting and the dark-mode notes issue

Use 25 pt presenter notes for this profile. Keep selective bold emphasis sparse and applied as actual rich text when the authoring route supports it; do not leave Markdown delimiters as visible speech text in Keynote.

Keynote's presenter-notes pane can adapt **native black** text to a readable light appearance in dark mode. During the source project, forcing an off-white or archived RGB color made notes appear dark and unreadable. The tested repair was to set the notes color through Keynote to native black, then inspect the actual lower notes pane.

Practical procedure:

1. Preserve the spoken content and current formatting before modifying color.
2. Test one representative slide through the native Keynote route available on that machine.
3. Confirm the rendered notes are readable in the user's actual editing pane. Do not infer visibility solely from stored RGB values or a slide screenshot.
4. Apply the verified notes style consistently, then spot-check ordinary, bold, and long notes.

If native UI inspection is unavailable, state that limitation and use a user-confirmed test rather than claiming the appearance is verified. This historical workaround is an application-specific behavior to validate, not a general instruction to make dark-slide text black.

## Comments and rehearsal

When asked to resolve comments in notes, separate comments from spoken content, apply content edits where requested, then remove the resolved comments. Keep unfinished issues in the review record. Do not leave alternate drafts, timing estimates, animation instructions, or sources in the final speaking script.

Estimate duration from current spoken words and rehearsal speed. Add only required waits that do not overlap narration. Revise the slowest sections rather than uniformly shortening every note. If a video begins before its explanation, move its cue or shorten the lead-in; if it waits too long, remove an unnecessary hold.
