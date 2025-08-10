# Rationale (key highlights)

- TrackingPrevention = Strict/Balanced: Uses Edge’s built-in tracker blocking; Strict blocks more but may break sites.
- BlockThirdPartyCookies = 1: Strong privacy baseline; site compatibility remains good in most cases.
- SmartScreenEnabled + PUA: Keep Microsoft Defender SmartScreen on; improves security without privacy cost.
- WebRtcIPHandlingPolicy = DisableNonProxiedUdp: Reduces local IP leak via WebRTC; may impact some real-time apps.
- DnsOverHttps: Balanced uses `automatic`; Strict uses `secure` with optional custom template (Cloudflare/Quad9/NextDNS).
- SSLVersionMin = tls1.2: Disables TLS 1.0/1.1; modern sites unaffected.
- SitePerProcess = 1: Site isolation hardening; minor memory overhead.
- QUIC: Enabled for performance; disabled in Strict for network observability/privacy preferences.
- BackgroundMode/StartupBoost: Disabled in privacy-heavy profiles to avoid background telemetry/CPU wake-ups; enabled in performance.
- SleepingTabs: Reduces resource usage on idle tabs, improving responsiveness and battery life.

These choices mirror BetterFox’s philosophy: minimize surface area, reduce tracking, and keep performance crisp.