# Privacy Policy & VpnService Disclosure for izi vpn

**Application:** izi vpn (`com.arshadevelop.izivpn`)  
**Developer:** Arsha Develop  
**Effective Date:** November 4, 2026  
**Public Policy URL:** [https://arshamc.github.io/izivpn/](https://arshamc.github.io/izivpn/)

---

## 1. Strict Zero-Log Commitment
At **izi vpn**, user privacy is our foundational principle. We operate under a **strict Zero-Log Policy**:
- **No Browsing Logs:** We never monitor, record, store, or log the websites you visit, online services you access, or files you download.
- **No Traffic Logs:** We do not record source or destination IP addresses.
- **No Connection Metadata:** We do not log session timestamps, connection duration, or bandwidth usage associated with individual user identities.
- **No DNS Queries Persisted:** DNS lookups handled inside the VPN tunnel are ephemeral and resolved without retention.

Because we do not log or store any user traffic, we have no personal data to sell, monetize, or provide to third parties or governmental authorities.

---

## 2. Mandatory Android `VpnService` Disclosure
In compliance with Google Play's **VpnService Policy**:
- **Core Functionality:** `izi vpn` utilizes Android's native `VpnService` API to establish an encrypted, device-level network tunnel using modern cryptographic protocols (VLESS and Xray).
- **Purpose:** This tunnel protects your data against eavesdropping on public Wi-Fi networks, man-in-the-middle attacks, and unauthorized network packet inspection.
- **Security Boundaries:** The `VpnService` is strictly used to forward encrypted packets to our remote proxy servers. It does not inspect, modify, or harvest sensitive personal data or transmitted payloads.
- **Explicit Consent:** A prominent frosted-glass disclosure dialog is displayed before requesting OS VPN permissions. The tunnel only activates after the user taps "Agree & Continue" and grants system permission.

---

## 3. Third-Party Advertising (Google AdMob)
`izi vpn` integrates the **Google Mobile Ads SDK (AdMob)** to provide free high-speed VPN access without requiring paid subscriptions.
AdMob may collect and process standard diagnostic and device data, including:
- Google Advertising ID (AAID / GAID)
- Coarse geolocation (country-level)
- Performance and crash diagnostics

Users can reset or delete their advertising identifier at any time via Android settings:  
`Settings > Google > Ads > Delete Advertising ID`

For details on Google's privacy practices, visit:  
[Google Privacy Policy](https://policies.google.com/privacy)

---

## 4. Permissions Requested
- `android.permission.BIND_VPN_SERVICE`: Required to create and manage the virtual network interface (`tun0`).
- `android.permission.INTERNET`: Required to communicate with proxy servers.
- `android.permission.POST_NOTIFICATIONS`: Required on Android 13+ to display the ongoing foreground service notification.

---

## 5. Security & Encryption
- Remote server configurations are secured with **AES-256-CBC** encryption.
- Network tunnels utilize **TLS 1.3** and **Reality** obfuscation handshakes.

---

## 6. Children's Privacy
`izi vpn` does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.

---

## 7. Contact Information
If you have any questions or suggestions regarding our Privacy Policy, contact us at:
- **Email:** `arshamc.dev@gmail.com`
- **GitHub:** [https://github.com/arshamc/izivpn](https://github.com/arshamc/izivpn)
