# Interactive PowerShell script to add a new site to Caddyfile in a Docker container,
# format and reload Caddy, and add the domain to the Windows hosts file.
# Run as Administrator!

# List running Docker containers
$containers = docker ps --format "{{.Names}}"
if ([string]::IsNullOrWhiteSpace($containers)) {
    Write-Host "No running containers found."
    exit 1
}
$containersArray = $containers -split "`n"

Write-Host "Select your Caddy container:"
for ($i = 0; $i -lt $containersArray.Length; $i++) {
    Write-Host "$($i+1). $($containersArray[$i])"
}
$selection = Read-Host "Enter the number of your container"
if ($selection -notmatch '^\d+$' -or $selection -lt 1 -or $selection -gt $containersArray.Length) {
    Write-Host "Invalid selection."
    exit 1
}
$selectedContainer = $containersArray[$selection - 1]

$domain = Read-Host "Enter the domain to add (e.g. mysite.local)"
if ([string]::IsNullOrWhiteSpace($domain)) {
    Write-Host "Domain cannot be empty."
    exit 1
}
$port = Read-Host "Enter the backend port for this domain (e.g. 8005)"
if ([string]::IsNullOrWhiteSpace($port)) {
    Write-Host "Port cannot be empty."
    exit 1
}
$siteBlock = "$domain { reverse_proxy host.docker.internal:$port tls internal }"

Write-Host "Adding the following site block inside the container:"
Write-Host $siteBlock
Write-Host ""

# Append the site block directly inside the container
docker exec -it $selectedContainer sh -c "echo '$siteBlock' >> /etc/caddy/Caddyfile"
Write-Host "✅ Added site block to /etc/caddy/Caddyfile inside $selectedContainer"

# Format the Caddyfile in the container
docker exec -w /etc/caddy $selectedContainer caddy fmt --overwrite
Write-Host "✅ Caddyfile formatted in container"

# Reload Caddy config
docker exec -w /etc/caddy $selectedContainer caddy reload
Write-Host "✅ Caddy reloaded"

# Add entry to Windows hosts file
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsEntry = "127.0.0.1 $domain"
Write-Host "Adding '$hostsEntry' to $hostsPath ..."
Add-Content -Path $hostsPath -Value $hostsEntry
Write-Host "✅ Added $domain to Windows hosts file!"

Write-Host "`n🎉 Done!"