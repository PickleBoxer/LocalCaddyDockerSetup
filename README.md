# 🚀 Local Development with Caddy, Docker, and HTTPS (Windows Guide)

Set up local HTTPS with [Caddy](https://caddyserver.com/) as a reverse proxy for multiple Docker projects, using trusted certificates on Windows.  
This guide is visually formatted for GitHub markdown and **step-by-step** for easy reference!

## 🗂️ Project Structure

```
caddy/
├── compose.yml
└── conf/
    └── Caddyfile
```
## 1️⃣ Add Local Domains to Windows Hosts File

1. Run Notepad **as Administrator**  
2. Open:  
   `C:\Windows\System32\drivers\etc\hosts`
3. Add:
   ```
   127.0.0.1   project1.local
   127.0.0.1   project2.local
   ```
4. Save and close.

## 2️⃣ Start Your Test Projects (`whoami` containers)

```powershell
docker run -d -p 8001:80 --name project1-whoami traefik/whoami
docker run -d -p 8002:80 --name project2-whoami traefik/whoami
```
- **Port 8001:** `project1-whoami`
- **Port 8002:** `project2-whoami`

## 3️⃣ Prepare Caddy Docker Compose Setup

### **compose.yml**
```yaml
services:
  caddy:
    image: caddy:2.8.4
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./conf:/etc/caddy
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
```

### **conf/Caddyfile**
```caddyfile
project1.local {
    reverse_proxy host.docker.internal:8001
    tls internal
}

project2.local {
    reverse_proxy host.docker.internal:8002
    tls internal
}
```

> ℹ️ **`host.docker.internal`** lets Caddy (in Docker) reach containers running on your host machine.

## 4️⃣ Start Caddy

Navigate to your `caddy` directory and run:
```bash
docker compose up -d
```

## 5️⃣ Copy and Trust Caddy's Root Certificate (HTTPS)

### **A. Open PowerShell as Administrator**

### **B. Find Caddy Container Name**
```powershell
docker ps
```
Look for the container named `caddy` (use that name below).

### **C. Copy the Certificate**
```powershell
docker cp caddy:/data/caddy/pki/authorities/local/root.crt "$env:TEMP\root.crt"
```
*(Replace `caddy` with your actual container name if different.)*

### **D. Trust the Certificate**
```powershell
certutil -addstore -f "ROOT" "$env:TEMP\root.crt"
```
Or, **double-click** the file and follow the Windows Certificate Import Wizard.

> 💡 You may need to import manually into browsers like Firefox (Settings → Privacy & Security → Certificates → Authorities → Import).

## 6️⃣ Reload Caddy After Changing the Caddyfile

If you edit `conf/Caddyfile`, reload Caddy with:
```powershell
docker exec -w /etc/caddy caddy-caddy-1 caddy reload
```
> **Note:**  
No need to restart the container. This command tells Caddy to reload its config instantly.

## 7️⃣ Test in Your Browser

- [https://project1.local](https://project1.local)
- [https://project2.local](https://project2.local)

You should see the whoami page for each, **using HTTPS with no browser warnings**!

## 📝 Summary Table

| Step | Action                    | Command/Location                                          |
|------|---------------------------|-----------------------------------------------------------|
| 1    | Add domains to hosts file | `C:\Windows\System32\drivers\etc\hosts`                  |
| 2    | Start whoami containers   | `docker run ...`                                          |
| 3    | Set up Caddy/Compose      | `compose.yml`, `conf/Caddyfile`                           |
| 4    | Start Caddy container     | `docker compose up -d`                                    |
| 5    | Copy/trust CA cert        | `docker cp ...`, `certutil -addstore ...`                 |
| 6    | Test in browser           | https://project1.local, https://project2.local            |

## 🎯 Tips & Troubleshooting

- If you get SSL warnings, make sure you imported the CA cert into both **Windows** and your **browser's** trusted authorities.
- To add more projects, repeat steps for additional ports and domains!
- For static sites, mount a `site` folder and use `root * /srv` in your Caddyfile.

## 📚 References

- [Caddy Docker Hub](https://hub.docker.com/_/caddy)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [whoami Docker Image](https://hub.docker.com/r/traefik/whoami)

**Enjoy your secure, local multi-project development setup! 🚦**