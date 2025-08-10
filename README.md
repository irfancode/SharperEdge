# SharperEdge — Privacy, performance, and security hardening for Microsoft Edge

SharperEdge brings BetterFox-style hardening to Microsoft Edge. It provides three profiles you can apply via PowerShell or .reg files:

- Strict — Maximum privacy and lock-down; may break site features.
- Balanced — Smart defaults with strong privacy and security; good daily driver.
- Performance — Faster startup and responsiveness with sensible safeguards.

> Scope: Windows 10/11, latest Edge (Chromium). Settings are applied via Edge policies under HKCU/HKLM.

---

## Quick start (PowerShell)

1) Open PowerShell as Administrator (recommended for machine-wide).
2) Optional: allow script execution temporarily:
   `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

3) Apply a profile to your user (HKCU):
   - Strict: `.\edge-apply.ps1 -Profile strict -Scope User`
   - Balanced: `.\edge-apply.ps1 -Profile balanced -Scope User`
   - Performance: `.\edge-apply.ps1 -Profile performance -Scope User`

4) Apply machine-wide (HKLM) instead:
   `.\edge-apply.ps1 -Profile balanced -Scope Machine`

5) Verify: open `edge://policy` and click "Reload policies".

### Rollback and backup

- The script automatically exports a backup before changes:
  - User scope: `%USERPROFILE%\Documents\SharperEdge-Backup-HKCU.reg`
  - Machine scope: `%PUBLIC%\Documents\SharperEdge-Backup-HKLM.reg`

- Remove only the settings applied by a profile:
  `.\edge-apply.ps1 -Profile balanced -Scope User -Unapply`

- Restore from backup (manual):
  - Double-click the `.reg` created in the backup directory, or
  - Use `reg import PATH_TO_BACKUP.reg`

---

## Profiles at a glance

| Category | Balanced (default) | Strict | Performance |
|---|---|---|---|
| Tracking Prevention | Strict | Strict | Balanced |
| Third-party cookies | Block | Block | Block |
| SmartScreen/PUA | On | On | On |
| Do Not Track | On | On | On |
| Password Manager | On | Off | On |
| Autofill (cards) | Off | Off | On |
| Autofill (addresses) | On | Off | On |
| WebRTC leak hardening | On | On | Off |
| TLS minimum | 1.2 | 1.2 | 1.2 |
| DoH | Automatic | Secure (custom) | Automatic |
| QUIC/HTTP3 | On | Off | On |
| Site Isolation | On | On | On |
| Background mode | Off | Off | On |
| Startup Boost | On | Off | On |
| Sleeping Tabs | On (60m) | On (15m) | On (30m) |
| Sidebar/Discover | Off | Off | On |
| Location/Notifications | Ask | Block | Ask |

> Note: Some settings (e.g., WebRTC hardening, blocking notifications/location globally) can break site features. Use Balanced if you want a stable daily experience with strong privacy.

---

## How it works (high level)

- Applies Edge policy registry values under:
  - HKCU\Software\Policies\Microsoft\Edge (per-user)
  - HKLM\Software\Policies\Microsoft\Edge (machine-wide)
- Idempotent: re-running updates values consistently.
- Unapply removes only values that a given profile set.

---

## Contributing

PRs welcome for:
- Edge version-specific tuning
- Enterprise/GPO documentation & ADMX guidance
- Additional profiles (e.g., “Paranoid”, “KidSafe”)

---

## License

MIT
