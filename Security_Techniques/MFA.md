# What is Multi-factor Authentication (MFA)?
We usualy have heard of 2FA which is a kind of MFA. MFA is an authentication method that requires the user to provide more than two verification factors to gain access to a resource such as an application, or a social media account.
![How Multi-Factor Authentication Works](img/mfa-how-it-works.jpg)

## MFA Authentication Methodology
MFA authentication methodology is based on the followin types:
- _Things_ you **know**, i.e. password or PIN
- _Things_ you **have**, i.e. badge or harware token
- _Things_ you **are**, i.e. biometric (fingerprints) or voice recognition
- _Where_ you **are**, i.e. at home (a specific geographical location)

## Examples of MFA
- **Biometrics**: Such as fingerprint, facial features or the retina or iris of the eye
- **Push to Approve**: A notification on the device that asks for approving a request by tapping on the screen
- **One-Time Password (OTP)**: An automatically generated set of characters
- **SMS Text**: A means of OTP to a user's smartphone
- **[Hardware Token](https://en.wikipedia.org/wiki/Security_token)**: A portable OTP-generating device
- **Software Token**: A software app that generates a new OTP every couple of seconds

# To-Dos
- Set it up on all accounts
- Store the recovery phrase; it is also known as the secret code or the QR code. It will be given during the setup process.
- Get the list of the one-time backup codes.
- Have a backup plan, in case of losing your possession of MFA tool and/or recovery phrase. For instance, setting up two or more means of MFA will reduce the risk of loss, i.e. enabaling hardware token and SMS text besides of having the list of backup codes.

## Recommended Tools
| Tool | Type | Features |
| ---- | ---- | -------- |
| [Yubikey](https://www.yubico.com/) | Hardware Token | FIDO2 standard / Cross-Platform / NFC |
| [Any FIDO2 Key](https://www.google.com/search?q=fido2+key) | Hardware Token | - |
| [Authy](https://authy.com/) | Software Token | Mobile App / Web App / Browser App / Cloud Backup / Cross Platform |
| [Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2&hl=en&gl=US) | Software Token | Offline / Mobile App |
| [LastPass](https://www.lastpass.com/) | Software Token | Password Manager / Mobile App / Web App / Browser App / Cloud Backup / Cross Platform |
| [Bitwarden](https://bitwarden.com) | Software Token | Password Manager / Mobile App / Web App / Browser App / Cloud Backup / Cross Platform |

## How to Do
You can use [2FA Directory](https://2fa.directory/) to see if the account you have, supports 2FA or not.

| Account | How to |
| ------- | ------ |
| Google | - [Official Site](https://support.google.com/accounts/answer/185839?hl=en)<br>- [Authy](https://authy.com/guides/googleandgmail/) |
| Microsoft | - [Authy](https://authy.com/guides/microsoft/) |
| Apple ID | - [Authy](https://authy.com/guides/apple/) |
| Yahoo | - [Authy](https://authy.com/guides/yahoo/) |
| Proton Mail | - [Authy](https://authy.com/guides/protonmail/) |
| Instagram | - [Authy](https://authy.com/guides/instagram/) |
| Twitter | - [Authy](https://authy.com/guides/twitter/) |
| TikTok | - [Make of Use](https://www.makeuseof.com/tiktok-enable-two-step-verification/) |
| LinkedIn | - [Authy](https://authy.com/guides/linkedin/) |
| Facebook | - [Authy](https://authy.com/guides/facebook/) |
| Snapchat | - [Authy](https://authy.com/guides/snapchat/) |
| Pnterest | - [Authy](https://authy.com/guides/pinterest/) |
| Dropbox | - [Authy](https://authy.com/guides/dropbox/) |
| Box | - [Authy](https://authy.com/guides/box/) |
| PayPal | - [Authy](https://authy.com/guides/paypal/) |
| Binance | - [Authy](https://authy.com/guides/binance/) |
| Coinbase | - [SaaSPass](https://blog.saaspass.com/how-to-add-two-factor-authentication-2fa-to-coinbase-e5744c21f981) |
| Signal | - [Beebom](https://beebom.com/enable-two-factor-authentication-2fa-on-signal/) |
| Telegram | - [Authy](https://beebom.com/enable-two-step-verification-on-telegram/) |
| WhatsApp | - [ACSC](https://www.cyber.gov.au/acsc/view-all-content/guidance/turning-two-factor-authentication-whatsapp-and-whatsapp-business) |
| Amazon | - [Authy](https://authy.com/guides/amazon/) |

## Good to Know
- The best is to use a hardware token
- If you use any kind of the software tokens, remember to save the 2FA QR-code or the correspondig secret code
- It is not adviced to use SMS method because there is a chance of losing the ownership of your SIM card
- Keep the backup codes in printed version
- Do not save backup codes on your phone or any other digital devices
- Keep the backup codes in the safest possible place; beside your jwelleries
- Frequently review your setting and assure that
  - you have still remaining backup codes
  - all means of MFA work smoothly and correctly
  - 


# Resources
- [What is Multi-Factor Authentication (MFA) and How Does it Work?](https://www.onelogin.com/learn/what-is-mfa)
- [What is multi-factor authentication (MFA) and how does it work?](https://www.securid.com/en-us/blog/the-language-of-cybersecurity/what-is-mfa)
