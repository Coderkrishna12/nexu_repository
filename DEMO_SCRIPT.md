# DEMO_SCRIPT.md — 3 to 7 Minute Video Recording Guide

This step-by-step script is tailored for your **3–7 minute demo video** submission required by **Section 8 (Item 7)**.

---

## Pre-Recording Checklist
1. Open the app on your browser or device (`flutter run -d chrome`).
2. Verify the Demo Clock banner displays: `DEMO CLOCK: Wed 11 Nov 2026, 10:00 AM`.
3. If tasks exist from earlier testing, go to **Settings (Menu -> Settings)** and tap **Reset to Assessment Default** or **Clear All Tasks & History**.
4. Test that your system audio can capture both your voice and the app's TTS audio output.

---

## Video Timeline & Script

### 0:00 – 0:45 | Intro & About Screen
- **Action**: Start screen recording. Open the app's top-right overflow menu and tap **About NEXU**.
- **Spoken Script**:
  > *"Hi everyone, my name is [Your Name]. This is my submission for the NEXU VoiceDesk Mobile Developer assessment, received on 11 November 2026 at 14:02 IST.*
  > *NEXU VoiceDesk is designed for Ravi, a field technician working in a noisy workshop with gloves on. He cannot use a fine touchscreen, so this app is voice-first.*
  > *Most importantly, the core 'brain' is 100% pure, deterministic Dart code written from scratch without any cloud AI services or API keys."*
- **Action**: Return to the Home Screen.

---

### 0:45 – 1:30 | Demo Clock & Sentence 1 (ADD with High Confidence)
- **Action**: Point out the **DEMO CLOCK** banner at the top (`Wed 11 Nov 2026, 10:00 AM`).
- **Spoken Script**:
  > *"All relative dates like 'today', 'tomorrow', and 'Friday at 10' resolve against our isolated Demo Clock, not the phone's real system time.*
  > *Now, let's test Sentence 1 using the real microphone via our large hold-to-talk thumb button."*
- **Action**: Hold the bottom-right circular microphone button and speak clearly:
  > **`"add task buy cable tomorrow at 5 pm high priority"`**
- **Action**: Release the button.
- **What to highlight on screen**:
  1. The live speech transcript appeared as you spoke.
  2. The assistant speaks back: *"Added 'buy cable', due Thu 12 Nov, 5:00 PM, High priority."*
  3. Show the **Understanding Panel**:
     - User Said: `"add task buy cable tomorrow at 5 pm high priority"`
     - Intent: `ADD`
     - Extracted values: `Title: buy cable`, `Date: Thu 12 Nov`, `Time: 5:00 PM`, `Priority: High`
     - Confidence badge: **`HIGH`** (green), because every slot was explicit and matched known patterns.
  4. Point to the task card created in the list below.

---

### 1:30 – 2:45 | Sentence 2 & Sentence 4 (Ambiguity "Which one?")
- **Action**: Use the Simulated Voice box (or voice) to create two tasks containing the word "call" to set up the ambiguity test:
  1. Speak or type: `"add task call Ravi tomorrow at 2 pm"`
  2. Speak or type: `"add task call vendor"` *(Notice Rule C2 fires asking "That time has passed. Move it to tomorrow?" -> Tap "Yes, Move to Tomorrow")*.
- **Spoken Script**:
  > *"Now we have two tasks containing the word 'call': 'call Ravi' and 'call vendor'.*
  > *Let's test Sentence 4 from Section 5: 'mark call done'."*
- **Action**: Speak or type:
  > **`"mark call done"`**
- **What to highlight on screen**:
  1. The app recognizes multiple matches and **does not guess or act prematurely** (Rule C4).
  2. The assistant asks aloud: *"Which one?"*
  3. The `ActivePromptBanner` displays candidate buttons: `[1: call Ravi]` and `[2: call vendor]`.
  4. Show the Understanding Panel showing intent `COMPLETE`, target `call`.
- **Action**: Speak or tap:
  > **`"one"`** (or tap `[1: call Ravi]`).
- **What to highlight**:
  - The app marks `"call Ravi"` completed with a green checkmark and strikethrough.

---

### 2:45 – 3:45 | Sentence 5 (Delete Safety & 8-Second Countdown)
- **Spoken Script**:
  > *"Next is Sentence 5: 'delete the last task'. Under Rule C5, deletion is a destructive action that requires confirmation and has a mandatory 8-second safety timeout."*
- **Action**: Hold the mic and say:
  > **`"delete the last task"`**
- **What to highlight on screen**:
  1. The assistant asks: *"Are you sure you want to delete 'call Ravi'?"*
  2. Show the **active 8-second circular countdown timer** counting down on screen (`8s... 7s... 6s...`).
  3. Show the large glove-friendly `[Yes, Delete]` and `[Cancel]` buttons.
  4. Speak or tap:
     > **`"yes"`**
  5. The task is deleted, spoken feedback confirms it, and the undo count in the AppBar increases to 1!

---

### 3:45 – 4:30 | Sentence 8 (Low Confidence Rejection) & Simulated Voice
- **Spoken Script**:
  > *"For reviewers testing without a microphone, we provide this bottom Simulated Voice input that routes through the exact same parsing engine.*
  > *Let's test Sentence 8: 'make coffee fly to the moon'."*
- **Action**: Tap the preset chip **8: Make coffee... (C6 Low)** or type `"make coffee fly to the moon"` and tap **Send**.
- **What to highlight on screen**:
  1. The assistant does **not** take any action (no task is modified).
  2. The Understanding Panel shows **`CONFIDENCE LOW`** (red badge) and Intent `UNKNOWN`.
  3. The assistant speaks back: *"I didn't understand that. Please try rephrasing."*

---

### 4:30 – 5:30 | Technical Explanation & Section 10 Wrap-Up
- **Spoken Script**:
  > *"To summarize our technical decisions:
  > 1. In 'move it to Friday at 10', 'it' is resolved to our active context pointer (shown with the blue 'Active Context' indicator on the card), Friday resolves to Nov 13 against the Demo Clock, and 10 resolves to 10:00 AM.
  > 2. TTS audio is instantly cut off whenever the user begins speaking or inputs a command, preventing acoustic feedback.
  > 3. All tasks, command history, and undo steps are saved in local storage and persist across app reboots.
  > 4. To support Hindi or Kannada, we would switch from SVO to SOV grammar parsing and configure regional language codes.
  > Thank you!"*
