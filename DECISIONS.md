# DECISIONS.md — Architecture & Design Decisions

This document records key design decisions, trade-offs, and resolutions where requirements were ambiguous, subtle, or where multiple business rules interacted.

---

### Decision 1: Rule C1 (Defaults) vs. Rule C2 (Past Time) Interaction
* **Context**: When a user speaks a command without specifying a date or time (e.g. `add task call vendor`), Rule C1 dictates that the due date defaults to **today** and the due time defaults to **9:00 AM**. However, on the assessment Demo Clock (**Wednesday, 11 November 2026, 10:00 AM**), 9:00 AM has already elapsed.
* **The Conflict / Ambiguity**: Should the engine assume the technician meant the next business day immediately, or should Rule C2 take precedence over the default?
* **What We Chose**:
  1. We execute the rules in a strict, deterministic sequence:
     - Apply Rule C1: Date = today (11 Nov), Time = 9:00 AM, Priority = Normal (`usedDefaults = true`, Confidence: `Medium`).
     - Apply Rule C2: Evaluate `scheduledDue < demoClock`. Because `11 Nov 09:00 < 11 Nov 10:00`, the task is **not saved**.
  2. The assistant enters `ConversationStatus.awaitingPastTimeConfirmation` and poses the required prompt:
     `"That time has passed. Move it to tomorrow?"`
  3. If the user answers affirmative (`"yes"`, `"yeah"`, `"confirm"` or taps `[Yes, Move to Tomorrow]`), the engine shifts the date to tomorrow (12 Nov) while preserving the 9:00 AM time, saves the task, and confirms aloud.
  4. If the user answers negative (`"no"`, `"cancel"`), the pending task is safely discarded.
* **Why**: This prevents silent assumptions, gives full transparency to the field technician, and exactly reproduces Acceptance Example 2.

---

### Decision 2: Rule C3 (Context Memory for "it" / "that") Resolution & Fallbacks
* **Context**: Technicians working with dirty gloves frequently use pronouns such as `"move it to Friday at 10"` or `"delete that"`.
* **The Conflict / Ambiguity**: What constitutes the "last task" when tasks are added, deleted, or listed? What happens if the context pointer is null (e.g. at app launch or after deleting all tasks)?
* **What We Chose**:
  1. We maintain an explicit `lastMentionedTaskId` in the state.
  2. The pointer is automatically updated whenever:
     - A task is created via `ADD`.
     - A task is modified via `COMPLETE` or `RESCHEDULE`.
     - An ambiguous option is resolved via `SELECT_OPTION`.
     - A single task is returned from a `LIST` query.
  3. On the UI, the task matching `lastMentionedTaskId` displays an **`ACTIVE CONTEXT ("it" / "that")`** blue badge with a GPS target icon. This provides instant visual clarity to the user.
  4. If the user says `"move it..."` and `lastMentionedTaskId` is null (or list is empty), the engine safely returns:
     `"Which task do you want to move?"` with `wasExecuted: false`.
* **Why**: Technicians in high-stress workshops should never have to wonder which task the system will act on. Visual context indicators coupled with spoken clarification prevent destructive mistakes.

---

### Decision 3: Rule C5 (Delete Safety Confirmation & 8-Second Timeout) Execution
* **Context**: Deleting a task is a destructive operation. Rule C5 mandates voice confirmation (`"yes"` / `"no"`) or tap confirmation, with a mandatory 8-second auto-cancel timeout.
* **The Conflict / Ambiguity**: What happens if the technician is in a noisy workshop where the phone cannot detect a soft `"no"`, or if the technician gets distracted?
* **What We Chose**:
  1. A dedicated `Timer.periodic(const Duration(seconds: 1))` is initialized the instant a `DELETE` intent is classified.
  2. A reactive `deleteCountdownSeconds` badge (`8s`, `7s`, `6s`...) is rendered on the screen alongside large, glove-friendly tap buttons: `[Yes, Delete]` and `[Cancel]`.
  3. If the user responds with `"yes"`, deletion proceeds immediately and is pushed to the Undo stack.
  4. If 8 seconds elapse without input, the timer terminates, sets conversation state back to `idle`, logs the timeout in the Understanding Panel, and speaks:
     `"No answer received. Deletion cancelled."`
  5. The timeout is also fully tested in our test suite.
* **Why**: Ravi should never lose work due to ambient factory noise. The 8-second safety window guarantees fail-safe behavior.

---

### Decision 4: Rule C6 (Confidence Scorer & Vocabulary Isolation)
* **Context**: Rule C6 defines:
  - **High**: Every word matched a known pattern.
  - **Medium**: Defaults (C1) were used.
  - **Low**: Unknown words or no intent found. On Low, take no action and ask to rephrase.
* **The Conflict / Ambiguity**: How should natural language task titles (e.g. "buy cable", "clean motor") be distinguished from unrecognized gibberish (e.g. "make coffee fly to the moon") without a cloud NLP model?
* **What We Chose**:
  1. We curated a domain-specific technician vocabulary covering intent trigger keywords, date/time phrases, priorities, and common workshop items (`cable`, `pump`, `vendor`, `motor`, `wire`, `drill`, etc.).
  2. For `ADD` commands, syntax tokens (prefix, date, time, priority) are extracted first. If any default was used (e.g. missing date, missing time, or missing priority), confidence is graded as **Medium**.
  3. If all slots were explicitly provided and matched the grammar, confidence is **High**.
  4. If a sentence contains non-task intents or unrecognized patterns (e.g. `"make coffee fly to the moon"`), confidence is scored as **Low**, no action is taken, and the assistant responds:
     `"I didn't understand that. Please try rephrasing."`
* **Why**: This fulfills Section 5 Example 8 and ensures deterministic behavior without AI API keys.

---

### Decision 5: Acoustic Noise Normalization & Conversational Preprocessing
* **Context**: When field technicians speak into the microphone (or when speech-to-text engines transcribe noisy workshop audio), acoustic slips occur frequently (e.g. `"tas"` instead of `"task"`, `"col"` instead of `"call"`, `"vender"` instead of `"vendor"`). In addition, technicians often precede commands with conversational phrasing such as `"i said add..."` or `"can you please..."`.
* **The Conflict / Ambiguity**: Should a rule-based parser reject any sentence that doesn't exactly match textbook syntax, or should it preprocess and normalize acoustic slips?
* **What We Chose**:
  1. We implemented a deterministic acoustic normalization pipeline before grammar matching that transforms known phoneme and transcription slips (`"tas"`, `"taks"` -> `"task"`, `"vender"` -> `"vendor"`, etc.).
  2. We strip leading conversational preambles (`"i said"`, `"please"`, `"can you"`, `"i want to"`).
  3. This enables flexible phrasing like `"i said add tas name call vendor"` to successfully map to ADD `"call vendor"`, while still preserving strict Low confidence rejection for truly out-of-domain nonsense (`"make coffee fly to the moon"`).
* **Why**: A real-world hands-free tool for a field technician must be resilient to acoustic variations and natural speech without requiring cloud AI models.


