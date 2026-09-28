# Gizli Pano (Secret Clipboard)

A second, private clipboard for Windows. Passwords and tokens are captured **without** landing in the Windows clipboard or the `Win+V` history, and pasted back without the clipboard being touched at all.

AutoHotkey v2 · single file · no installation · nothing written to disk

Türkçe: [README.tr.md](README.tr.md)

---

## The problem

When you run a virtual machine (VMware, Hyper-V, RDP) you keep clipboard sharing on because it saves time. The price is that **everything** you copy on the host crosses into the guest. If the guest is a monitored corporate system, your personal passwords end up in an environment you do not control.

The second problem is Windows itself. The `Win+V` clipboard history keeps copied values, and emptying the clipboard does **not** remove them. You clear the clipboard, believe the value is gone, and it is still sitting in the history.

Gizli Pano closes both paths: the sensitive value lives in the script's own memory, stays in the Windows clipboard for a measurably short moment, and the Win+V history is dropped after every capture.

---

## What it does

Classification happens at copy time. There is no content filter — text cannot tell you whether it is a password — so the decision is made by which key you press.

| Hotkey | Action |
|---|---|
| `Left Shift + C` | Capture the selection into the secret clipboard, empty the Windows clipboard |
| `Left Shift + V` | Type the most recent entry at the caret |
| `Left Shift + D` | Open the secret clipboard history window |

Normal `Ctrl+C` / `Ctrl+V` / `Win+V` behaviour is **unchanged**. Ordinary text is copied and synced to the VM exactly as before.

On top of that, whenever you make a normal copy, a small translucent **hassas** ("sensitive") button appears next to the cursor for two seconds. If a website's own copy button just put a password on your clipboard, clicking this button moves that value into the secret store after the fact and empties the normal clipboard.

---

## How it works

**No restore-after-read.** The script sends `Ctrl+C` in the background, reads the value and empties the clipboard immediately. It does not try to put the previous clipboard content back — restoring would only extend the time the secret spends on the clipboard.

**The protection is the time window.** The value stays on the clipboard for roughly 50 ms. Measurement showed that VMware Tools transfers the clipboard at certain moments rather than continuously, and misses that window.

**Pasting never uses the clipboard.** `Left Shift + V` types the value character by character with `SendText`. Tested with a string containing shifted keys, AltGr keys, Turkish letters and `€`: no dropped characters.

**Win+V history is dropped explicitly.** After every secret capture the WinRT `Clipboard.ClearHistory()` method is called.

**History is memory only.** 20 entries, each expiring after 10 minutes. No disk writes, no log, no vault file — when the script exits, nothing remains.

---

[
---
**Shift + C , Shift + V , Shift + D**

](https://github.com/user-attachments/assets/d73c31fc-e88f-415a-83c4-b48a1ae6fe1e


---
**Shift + C , Shift + V , Shift + D**



https://github.com/user-attachments/assets/7711618a-77e3-4e7d-998a-f31490f51370)

---

## Requirements

Windows 10 or 11 and [AutoHotkey v2](https://www.autohotkey.com/v2/). The v1 syntax is not compatible; the script must be run with v2.

---

## Installation

1. Install AutoHotkey v2.
2. Put `gizli_pano.ahk` anywhere you like.
3. Double-click it. The tray icon means it is running.
4. To start it with Windows, put a shortcut in the `shell:startup` folder.

Administrator rights are not needed and not recommended.

---

## Settings

Every setting is a constant in the AYAR ("settings") block at the top of the file. After editing, right-click the tray icon and choose **Reload Script**.

| Constant | Default | Meaning |
|---|---|---|
| `TUS_KOPYALA` | `"<+c"` | Secret copy hotkey |
| `TUS_YAPISTIR` | `"<+v"` | Paste-latest hotkey |
| `TUS_GECMIS` | `"<+d"` | History window hotkey |
| `AZAMI` | `20` | Maximum number of entries |
| `OMUR_DK` | `10` | Entry lifetime, minutes |
| `HASSAS_SN` | `2` | How long the floating button stays visible |
| `ONIZLEME` | `46` | Preview length in the history window, characters |
| `HASSAS_SAYDAM` | `235` | Button opacity (0 invisible, 255 opaque) |
| `HASSAS_ZEMIN` | `"1E2430"` | Button background colour, RRGGBB |
| `HASSAS_YAZI` | `"D6E4EE"` | Button text colour, RRGGBB |
| `HASSAS_GEN` / `HASSAS_YUK` | `56` / `20` | Button size in pixels |

In hotkey strings `<` and `>` select the left or right modifier; `+` is shift, `^` is ctrl, `!` is alt, `#` is win. So `"^+c"` is ctrl+shift+c, `"!v"` is alt+v, and `"F9"` is simply F9.

---

## History window

`Left Shift + D` opens it next to the cursor, newest entry first. Arrow keys move the selection, `Enter` types the selected entry into the previous window, `Delete` or the `×` at the end of a row removes a single entry. The **Tumunu temizle** ("clear all") button in the header drops the whole history.

The window closes on `Esc`, on a click anywhere outside it, and on focus loss. Each row shows the entry's remaining lifetime in minutes.

---

## Known limitations

**Hotkeys do not fire while the VM window has focus.** VMware captures the keyboard raw when the guest is focused, so host hotkeys never reach the script. This is expected behaviour in every virtualisation product and is accepted deliberately here: secrets are not meant to reach the guest, so the secret clipboard does not need to work there. Disabling VMware's raw keyboard driver fixes it but sends `Win` and `Alt+Tab` to the host instead.

**`ClearHistory` is not selective.** It wipes the entire Win+V history, not just the entry you captured. If you rely on that history, this is a real cost. To turn the history off completely, set `HKCU\Software\Microsoft\Clipboard\EnableClipboardHistory` to `0`.

**The letter in a hotkey cannot be typed with that modifier.** With the defaults, capital `C`, `V` and `D` cannot be typed with the left shift key; use the right one. If that bothers you, change the hotkeys.

**Memory is not encrypted.** Entries live in process memory as plain text. What this script defends against is clipboard and Win+V leakage, not an attacker who can dump your memory.

**Do not trust `ExcludeClipboardContentFromMonitorProcessing`.** Measured: a value written with that flag does stay out of the Win+V history, but VMware Tools ignores the flag and the value still pastes in the guest with `Ctrl+V`. That is why this script relies on the time window instead of the flag.

---

## Measurement notes

The behaviours below were tested on a real host/guest setup rather than assumed.

`A_Clipboard := ""` empties the clipboard but does not remove the entry from the Win+V history; what you see in the history is not necessarily the current clipboard content.

Writing a value to the clipboard and emptying it 50 ms later left the guest holding the **old** value — neither the new value nor the clearing was synced. Transfer happens at certain moments, not continuously.

A string typed with `SendText` and the same string pasted from the clipboard matched exactly, including special characters.

---

## Reading the code

Identifiers and comments are in Turkish, since that is the maintainer's language. The mapping is small:

| Turkish | English |
|---|---|
| `pano` | clipboard / store |
| `gizli` | secret |
| `gecmis` | history |
| `kopyala` / `yapistir` | copy / paste |
| `tus` | key |
| `hassas` | sensitive |
| `temizle` / `sil` | clear / delete |
| `dugme` | button |
| `ayar` | setting |
| `bildir` | notify |
| `saydam` | transparent |
| `omur` | lifetime |

The interesting functions are `GizliKopyala()` (capture and clear), `GizliYapistir()` (type back), `GecmisAc()` (history window), `WinGecmisiTemizle()` (the WinRT call) and `HassasAl()` (the floating button).

---

## Licence

MIT. Use it, change it, redistribute it.
