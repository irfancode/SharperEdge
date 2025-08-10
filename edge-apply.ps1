<#
.SYNOPSIS
  Apply BetterFox-style hardening to Microsoft Edge with profile presets.

.PARAMETER Profile
  strict | balanced | performance

.PARAMETER Scope
  User (HKCU) | Machine (HKLM)

.PARAMETER Unapply
  Remove only the policy values set by the given profile/scope.

.PARAMETER DnsTemplate
  Optional custom DoH template for strict profile
  (e.g., https://security.cloudflare-dns.com/dns-query or https://dns.quad9.net/dns-query)

.EXAMPLE
  .\edge-apply.ps1 -Profile balanced -Scope User

.EXAMPLE
  .\edge-apply.ps1 -Profile strict -Scope Machine -DnsTemplate https://dns.nextdns.io/abcd1234
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('strict','balanced','performance')]
  [string]$Profile,

  [Parameter(Mandatory=$true)]
  [ValidateSet('User','Machine')]
  [string]$Scope,

  [switch]$Unapply,

  [string]$DnsTemplate
)

function Get-PolicyRoot {
  param([string]$Scope)
  if ($Scope -eq 'Machine') {
    return 'HKLM:\Software\Policies\Microsoft\Edge'
  } else {
    return 'HKCU:\Software\Policies\Microsoft\Edge'
  }
}

function Ensure-Key {
  param([string]$Path)
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
}

function Backup-Policies {
  param([string]$Scope)
  $regPath = if ($Scope -eq 'Machine') { 'HKLM\Software\Policies\Microsoft\Edge' } else { 'HKCU\Software\Policies\Microsoft\Edge' }
  $outDir = if ($Scope -eq 'Machine') { "$env:PUBLIC\Documents" } else { "$env:USERPROFILE\Documents" }
  if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
  $outFile = Join-Path $outDir ("SharperEdge-Backup-{0}.reg" -f ($Scope -eq 'Machine' ? 'HKLM' : 'HKCU'))
  Write-Host "Backing up $regPath to $outFile..."
  & reg.exe export $regPath $outFile /y | Out-Null
  return $outFile
}

# Profiles: policy names map to values (int -> REG_DWORD; string -> REG_SZ)
$profiles = @{
  balanced = @{
    ConfigureDoNotTrack              = 1
    TrackingPrevention               = 1
    TrackingPreventionLevel          = 'Balanced'  # 'Basic'|'Balanced'|'Strict'
    BlockThirdPartyCookies           = 1
    PasswordManagerEnabled           = 1
    PasswordLeakDetectionEnabled     = 1
    AutofillCreditCardEnabled        = 0
    AutofillAddressEnabled           = 1
    PaymentMethodQueryEnabled        = 0
    SmartScreenEnabled               = 1
    SmartScreenPuaEnabled            = 1
    SSLVersionMin                    = 'tls1.2'
    DnsOverHttpsMode                 = 'automatic' # 'off'|'automatic'|'secure'
    HardwareAccelerationModeEnabled  = 1
    StartupBoostEnabled              = 1
    BackgroundModeEnabled            = 0
    SleepingTabsEnabled              = 1
    SleepingTabsTimeout              = 60          # minutes
    HubsSidebarEnabled               = 0
    SitePerProcess                   = 1
    QuicAllowed                      = 1
    WebRtcIPHandlingPolicy           = 'DisableNonProxiedUdp' # Default|DefaultPublicAndPrivateInterfaces|DisableNonProxiedUdp|ProxyOnly
    DefaultGeolocationSetting        = 3           # 1 allow, 2 block, 3 ask
    DefaultNotificationsSetting      = 3
    DefaultSensorsSetting            = 2
  }
  strict = @{
    ConfigureDoNotTrack              = 1
    TrackingPrevention               = 1
    TrackingPreventionLevel          = 'Strict'
    BlockThirdPartyCookies           = 1
    PasswordManagerEnabled           = 0
    PasswordLeakDetectionEnabled     = 1
    AutofillCreditCardEnabled        = 0
    AutofillAddressEnabled           = 0
    PaymentMethodQueryEnabled        = 0
    SmartScreenEnabled               = 1
    SmartScreenPuaEnabled            = 1
    SSLVersionMin                    = 'tls1.2'
    DnsOverHttpsMode                 = 'secure'
    # DnsOverHttpsTemplates may be set via -DnsTemplate
    HardwareAccelerationModeEnabled  = 1
    StartupBoostEnabled              = 0
    BackgroundModeEnabled            = 0
    SleepingTabsEnabled              = 1
    SleepingTabsTimeout              = 15
    HubsSidebarEnabled               = 0
    SitePerProcess                   = 1
    QuicAllowed                      = 0
    WebRtcIPHandlingPolicy           = 'DisableNonProxiedUdp'
    DefaultGeolocationSetting        = 2
    DefaultNotificationsSetting      = 2
    DefaultSensorsSetting            = 2
    BrowserSignin                    = 0          # 0 disabled, 1 enabled, 2 forced
    SyncDisabled                     = 1
  }
  performance = @{
    ConfigureDoNotTrack              = 1
    TrackingPrevention               = 1
    TrackingPreventionLevel          = 'Balanced'
    BlockThirdPartyCookies           = 1
    PasswordManagerEnabled           = 1
    PasswordLeakDetectionEnabled     = 1
    AutofillCreditCardEnabled        = 1
    AutofillAddressEnabled           = 1
    PaymentMethodQueryEnabled        = 1
    SmartScreenEnabled               = 1
    SmartScreenPuaEnabled            = 1
    SSLVersionMin                    = 'tls1.2'
    DnsOverHttpsMode                 = 'automatic'
    HardwareAccelerationModeEnabled  = 1
    StartupBoostEnabled              = 1
    BackgroundModeEnabled            = 1
    SleepingTabsEnabled              = 1
    SleepingTabsTimeout              = 30
    HubsSidebarEnabled               = 1
    SitePerProcess                   = 1
    QuicAllowed                      = 1
    WebRtcIPHandlingPolicy           = 'Default'
    DefaultGeolocationSetting        = 3
    DefaultNotificationsSetting      = 3
    DefaultSensorsSetting            = 3
  }
}

$policyRoot = Get-PolicyRoot -Scope $Scope
Ensure-Key -Path $policyRoot | Out-Null

if ($Unapply) {
  $keys = $profiles[$Profile].Keys
  Write-Host "Removing $($keys.Count) policy values for profile '$Profile' at $policyRoot..."
  foreach ($name in $keys) {
    if (Test-Path "$policyRoot") {
      if (Get-ItemProperty -Path $policyRoot -Name $name -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $policyRoot -Name $name -ErrorAction SilentlyContinue
        Write-Host "  - Removed $name"
      }
    }
  }
  Write-Host "Done. Reload policies at edge://policy."
  exit 0
}

# Backup before applying
$backupFile = Backup-Policies -Scope $Scope
Write-Host "Backup saved to: $backupFile"

# Apply chosen profile
$settings = $profiles[$Profile].Clone()

# If strict + DnsTemplate provided, set DnsOverHttpsTemplates
if ($Profile -eq 'strict' -and $DnsTemplate) {
  $settings['DnsOverHttpsTemplates'] = $DnsTemplate
}

Write-Host "Applying profile '$Profile' to $policyRoot ..."
foreach ($kvp in $settings.GetEnumerator()) {
  $name = $kvp.Key
  $value = $kvp.Value
  if ($value -is [int]) {
    New-ItemProperty -Path $policyRoot -Name $name -Value $value -PropertyType DWord -Force | Out-Null
  } else {
    New-ItemProperty -Path $policyRoot -Name $name -Value ([string]$value) -PropertyType String -Force | Out-Null
  }
  Write-Host ("  - {0} = {1}" -f $name, $value)
}

# Friendly note for DoH
if ($Profile -eq 'strict' -and -not $DnsTemplate) {
  Write-Warning "Strict DoH is enabled without a template. Provide -DnsTemplate for a custom provider."
}

Write-Host "Done. Open edge://policy and click 'Reload policies'."