# NEXU VoiceDesk — Mobile Technical Assessment

> **Build a hands-free, voice-first task assistant for a field technician with gloves on.**

NEXU VoiceDesk is an accessible, voice-first task management application built in Flutter for field technicians (such as Ravi in a noisy, dusty workshop). The core "brain" is a 100% deterministic, rule-based Dart command engine written from scratch without any external AI service or cloud API keys.

---

## 1. Prerequisites & Setup

### Prerequisites
- **Flutter SDK**: `^3.24.0` (developed & verified on Flutter `3.38.7` / Dart `3.10.7`)
- **Android SDK**: Android API 21+ (for Android builds)
- **Web Browser**: Google Chrome or Microsoft Edge (for instant browser execution)

### Quick Run Steps

#### Run Web Build (Instant Local Testing)
```bash
flutter run -d chrome
```
Or view the pre-compiled web build:
```bash
flutter build web
```

#### Run on Android Device / Emulator
```bash
flutter run -d android
```

#### Run Automated Test Suite
To run all 19 automated tests (acceptance examples, edge cases, UI smoke, provider integration):
```bash
flutter test
```

To run static analysis:
```bash
flutter analyze
```

---

## 2. Architecture & State Management Choice

```
lib/
├── core/
│   ├── theme/app_theme.dart          # High-contrast industrial UI theme
│   └── constants/                    # Application configuration
├── models/
│   ├── command_intent.dart           # Intent taxonomy (ADD, COMPLETE, etc.)
│   ├── confidence_level.dart         # High, Medium, Low scoring
│   ├── conversation_state.dart       # Multi-turn state machine
│   ├── task_item.dart                # Task domain model
│   ├── parsed_command.dart           # Structured NLU token slots
│   ├── command_result.dart           # Pure execution output
│   └── undo_action.dart              # Reversible actions stack
├── engine/
│   ├── command_engine.dart           # Pure functions brain
│   ├── intent_classifier.dart        # Deterministic token & slot parser
│   └── date_time_parser.dart         # Relative date/time math against Demo Clock
├── services/
│   ├── storage_service.dart          # Local JSON persistence (SharedPreferences)
│   ├── tts_service.dart              # Speech synthesis & instant interruption
│   └── stt_service.dart              # Hold-to-talk speech recognition
├── providers/
│   └── assistant_provider.dart       # ChangeNotifier state coordinator
└── ui/
    ├── screens/
    │   ├── home_screen.dart          # Primary hands-free dashboard
    │   ├── settings_screen.dart      # Demo clock & speech preferences
    │   └── about_screen.dart         # Assessment & candidate information
    └── widgets/
        ├── hold_to_talk_button.dart  # Ergonomic bottom-right thumb button
        ├── simulated_voice_input.dart# Typed input with 1-tap Section 5 presets
        ├── understanding_panel.dart  # Real-time intent, slots, confidence badge & history
        ├── active_prompt_banner.dart # C2, C4, C5 confirmation banners
        ├── demo_clock_banner.dart    # Isolated reference clock display
        └── task_card.dart            # High-visibility task card with Active Context indicator
```

### Why Provider (`ChangeNotifier`)?
1. **Separation of Concerns**: The Command Engine is completely decoupled from Flutter UI widgets. It operates as a pure function:
   ```dart
   CommandResult result = CommandEngine.processInput(
     rawInput: text,
     currentTasks: tasks,
     conversationState: state,
     undoStack: undoStack,
     lastMentionedTaskId: contextId,
     demoClock: demoClock,
   );
   ```
2. **Predictable Unidirectional Data Flow**: State updates flow from `AssistantProvider` to reactive UI components. There are no side effects inside the parsing logic.
3. **Simulated Voice Parity**: Both real microphone audio streams and the typed "Simulated Voice" input pass through the exact same `submitCommand(rawInput)` method.

---

## 3. Section 10: Short Technical Explanation

### 1. Step-by-Step Trace of `"move it to Friday at 10"`
When Ravi speaks `"move it to Friday at 10"`:
1. **Interruption**: Any active TTS playback is immediately terminated via `ttsService.stop()`.
2. **Normalization**: Input is lowercased and stripped of extraneous punctuation: `"move it to friday at 10"`.
3. **Intent Classification**: The regex pattern `^(?:move|reschedule)\s+(.+?)\s+to\s+(.+)$` matches:
   - Target query: `"it"`
   - Target date/time substring: `"friday at 10"`
4. **Context Resolution (Rule C3)**: `"it"` refers to `lastMentionedTaskId`. The engine retrieves the active task (e.g. `"buy cable"`).
5. **DateTime Parsing**:
   - Reference clock is the **Demo Clock** (`Wed, 11 Nov 2026, 10:00 AM`).
   - `"Friday"` resolves to Friday of the current week: `13 Nov 2026`.
   - `"at 10"` resolves to `10:00 AM`.
   - Resulting timestamp: `2026-11-13 10:00`.
6. **Past Time Check (Rule C2)**: Evaluates whether `2026-11-13 10:00 < demoClock`. Since it is in the future, it proceeds without clarification.
7. **Execution**:
   - The task's `dueDateTime` is updated.
   - An `UndoAction` of type `rescheduled` containing the old due date is pushed to the 5-item undo stack.
   - `lastMentionedTaskId` is updated to this task ID.
8. **Feedback & Persistence**:
   - Visual result: `"Last task rescheduled to Fri 13 Nov, 10:00 AM."`
   - Spoken aloud via TTS.
   - Understanding Panel logs intent `RESCHEDULE`, Confidence `High`, Target `it`.

---

### 2. How Does Your Parser Decide the Intent & Avoid Wrong Guesses?
1. **Multi-Turn State Guard First**: Before evaluating generic commands, the parser checks if the assistant is awaiting an active clarification (`PastTimeConfirmation`, `DeleteConfirmation`, or `AmbiguityResolution`). In these states, words like `"yes"`, `"no"`, or candidate names/indices (`"one"`, `"vendor"`) are mapped directly to state actions.
2. **Acoustic Pre-Processing & Prefix Stripping**:
   - Cleans conversational filler: `"i said ..."`, `"please ..."`, `"can you ..."`, `"i want to ..."`.
   - Normalizes common speech recognition transcription slips: `"tas"` / `"taks"` -> `"task"`, `"col"` -> `"call"`, `"vender"` -> `"vendor"`, `"tomorow"` -> `"tomorrow"`.
3. **Flexible Intent Discriminators**:
   - `ADD`: Supports `"add task ..."` as well as variations like `"add tas name call vendor"`, `"create task ..."`, `"remind me to ..."`, or natural action imperatives (`"call vendor tomorrow"`, `"buy cable tomorrow at 5 pm high priority"`).
   - `COMPLETE`: Handles `"mark [target] done"`, `"mark done [target]"`, `"complete [target]"`, `"finish [target]"`, `"done with [target]"`, and `"check off [target]"`.
   - `RESCHEDULE`: Handles `"move [target] to [time]"`, `"reschedule ..."`, `"postpone ..."`, `"shift ..."`, `"change ..."`.
   - `DELETE`: Handles `"delete [target]"`, `"remove ..."`, `"discard ..."`, `"erase ..."`, `"cancel ..."`.
   - `LIST`: Handles `"what is due today"`, `"what tasks do i have"`, `"show tasks"`, `"list tasks"`, `"tasks today"`.
   - `UNDO`: Handles `"undo that"`, `"undo"`, `"revert that"`, `"take that back"`.
4. **Strict Fallback (Rule C6)**: If a sentence lacks these grammatical patterns and contains unknown vocabulary (e.g. `"make coffee fly to the moon"`), the intent is classified as `UNKNOWN`, confidence is assigned **`Low`**, no state modification occurs, and the system prompts the user to rephrase.

---

### 3. Handling the Word "it" and the "Which one?" Conversation State
- **"it" / "that" Context (Rule C3)**:
  - We maintain an explicit `lastMentionedTaskId` in state.
  - On the UI, the matching task card displays a distinctive **`ACTIVE CONTEXT ("it" / "that")`** pill with a target icon.
  - If Ravi uses `"it"` when no task exists, the assistant safely asks: *"Which task do you want to move?"*
- **Ambiguity ("Which one?", Rule C4)**:
  - If a title query matches 2 or more tasks (e.g. `"call"` matches `"call Ravi"` and `"call vendor"`), the engine halts execution.
  - Conversation status shifts to `ConversationStatus.awaitingAmbiguityResolution`.
  - Assistant asks: *"Which one?"*.
  - The system accepts voice input (`"one"`, `"two"`, `"the first"`, `"the second"`) or tap selection on the candidate task buttons shown in the `ActivePromptBanner`.

---

### 4. What Happens If the User Speaks While the App Is Still Speaking?
- **Zero-Latency Audio Interruption**: Both `startListening()` (triggered on hold-to-talk press) and `submitCommand(text)` call `await ttsService.stop()`.
- The native TTS audio playback engine is immediately cut off before speech recognition begins or new logic processes. This prevents the microphone from picking up the app's own voice (eliminating acoustic feedback loops).

---

### 5. What Would You Change to Support Hindi or Kannada Commands?
1. **Locale-Aware Tokenizer**:
   - Add dictionary maps for Hindi (e.g. `"कल"` -> tomorrow, `"आज"` -> today, `"जोड़ो"` -> add, `"हटाओ"` -> delete, `"हाँ"` / `"नहीं"` -> yes/no) and Kannada (e.g. `"ನಾಳೆ"` -> tomorrow, `"ಇವತ್ತು"` -> today, `"ಸೇರಿಸಿ"` -> add, `"ತೆಗೆದುಹಾಕಿ"` -> delete, `"ಹೌದು"` / `"ಇಲ್ಲ"` -> yes/no).
2. **STT Language Code**:
   - Pass locale identifiers to `speech_to_text`: `hi_IN` for Hindi, `kn_IN` for Kannada.
3. **TTS Synthesis Voice**:
   - Configure `flutter_tts.setLanguage("hi-IN")` and `flutter_tts.setLanguage("kn-IN")`.
4. **SOV (Subject-Object-Verb) Grammar Parser**:
   - English follows SVO (e.g. `"add task [title] [time]"`), whereas Hindi and Kannada follow SOV (e.g. `"[time] [title] जोड़ो"` / `"[time] [title] ಸೇರಿಸಿ"`). The regular expression parser would evaluate verb suffixes rather than prefixes.

---

### 6. Parts Built Yourself vs. Third-Party Code & AI Tools (Honest Disclosure)
- **Built 100% By Hand**:
  - Entire Command Engine (`lib/engine/command_engine.dart`)
  - Intent Classifier & Grammar Parser (`lib/engine/intent_classifier.dart`)
  - Relative DateTime Parser against Demo Clock (`lib/engine/date_time_parser.dart`)
  - Multi-Turn Conversation State Machine (Past Time, Ambiguity, 8s Delete Countdown)
  - 19 Automated Tests in `test/`
  - High-contrast accessible UI components and Understanding Panel.
- **Third-Party Packages Used**:
  - `speech_to_text`: Android/iOS/Web platform speech audio stream wrapper.
  - `flutter_tts`: Platform speech synthesizer.
  - `shared_preferences`: Key-value local storage serialization.
  - `provider`: InheritedWidget state management.
  - `intl`: Standardized datetime formatting.
  - `uuid`: RFC4122 unique ID generation for task entities.
- **AI Tools Disclosure**:
  - An AI coding assistant was used for scaffolding boilerplate files, verifying syntax compatibility across Flutter 3.38, and formatting markdown tables. All algorithmic logic, grammar rules, and state machines were authored and validated against the assessment specification.

---

## 4. Known Limitations
1. **Fixed Technician Vocabulary**: While the title parser dynamically accepts any custom task name, confidence scoring is calibrated around workshop vocabulary (`cable`, `vendor`, `pump`, `motor`, etc.). Extra domain nouns can be registered in `_knownVocabulary`.
2. **Desktop Microphone Plugins**: On Windows desktop, speech recognition requires Windows SAPI / Media Speech features. On browsers and mobile (Android/iOS), speech recognition works natively. The Simulated Voice bar provides 100% functional parity across all platforms.
