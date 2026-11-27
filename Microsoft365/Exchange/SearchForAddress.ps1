$SearchEmail = Read-Host("Address to hunt")

Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
Connect-ExchangeOnline -ShowBanner:$false

$results = @()

Write-Host "Searching user and shared mailboxes..." -ForegroundColor Yellow
$mailboxes = Get-ExoMailbox -ResultSize Unlimited -PropertySets All
foreach ($mbx in $mailboxes) {
    if ($mbx.PrimarySmtpAddress -ieq $SearchEmail -or $mbx.EmailAddresses -icontains "SMTP:$SearchEmail") {
        $results += [pscustomobject]@{
            Type  = $mbx.RecipientTypeDetails
            Name  = $mbx.DisplayName
            Match = $SearchEmail
            FoundIn = if ($mbx.PrimarySmtpAddress -ieq $SearchEmail) { "Primary Address" } else { "Alias" }
        }
    }
}

Write-Host "Searching distribution groups..." -ForegroundColor Yellow
$groups = Get-DistributionGroup -ResultSize Unlimited
foreach ($grp in $groups) {
    if ($grp.PrimarySmtpAddress -ieq $SearchEmail -or $grp.EmailAddresses -icontains "SMTP:$SearchEmail") {
        $results += [pscustomobject]@{
            Type  = "Distribution Group"
            Name  = $grp.DisplayName
            Match = $SearchEmail
            FoundIn = if ($grp.PrimarySmtpAddress -ieq $SearchEmail) { "Primary Address" } else { "Alias" }
        }
    }
}

Write-Host "Searching Microsoft 365 Groups..." -ForegroundColor Yellow
$m365groups = Get-UnifiedGroup -ResultSize Unlimited
foreach ($grp in $m365groups) {
    if ($grp.PrimarySmtpAddress -ieq $SearchEmail -or $grp.EmailAddresses -icontains "SMTP:$SearchEmail") {
        $results += [pscustomobject]@{
            Type  = "Microsoft 365 Group"
            Name  = $grp.DisplayName
            Match = $SearchEmail
            FoundIn = if ($grp.PrimarySmtpAddress -ieq $SearchEmail) { "Primary Address" } else { "Alias" }
        }
    }
}

Write-Host "Searching mail contacts..." -ForegroundColor Yellow
$contacts = Get-MailContact -ResultSize Unlimited
foreach ($contact in $contacts) {
    if ($contact.PrimarySmtpAddress -ieq $SearchEmail -or $contact.EmailAddresses -icontains "SMTP:$SearchEmail") {
        $results += [pscustomobject]@{
            Type  = "Mail Contact"
            Name  = $contact.DisplayName
            Match = $SearchEmail
            FoundIn = if ($contact.PrimarySmtpAddress -ieq $SearchEmail) { "Primary Address" } else { "Alias" }
        }
    }
}

Write-Host "Searching resource mailboxes (rooms/equipment)..." -ForegroundColor Yellow
$resources = Get-Mailbox -RecipientTypeDetails RoomMailbox, EquipmentMailbox -ResultSize Unlimited
foreach ($res in $resources) {
    if ($res.PrimarySmtpAddress -ieq $SearchEmail -or $res.EmailAddresses -icontains "SMTP:$SearchEmail") {
        $results += [pscustomobject]@{
            Type  = $res.RecipientTypeDetails
            Name  = $res.DisplayName
            Match = $SearchEmail
            FoundIn = if ($res.PrimarySmtpAddress -ieq $SearchEmail) { "Primary Address" } else { "Alias" }
        }
    }
}

Write-Host "`nSearch complete. Results:" -ForegroundColor Green
if ($results.Count -eq 0) {
    Write-Host "No matches found for $SearchEmail" -ForegroundColor Red
} else {
    $results | Sort-Object Type, Name | Format-Table -AutoSize
}

Disconnect-ExchangeOnline -Confirm:$false
