#!/data/data/com.termux/files/usr/bin/bash

logfile="$HOME/cloudflared.log"
urlfile="$HOME/cloud_url.txt"

while true; do
  echo "🌐 Starting new tunnel at $(date)" | tee -a "$logfile"

  # Start cloudflared in background, capture PID
  cloudflared tunnel --url http://localhost:8080 > /tmp/cloud_output.txt 2>&1 &
  pid=$!

  # Wait max 10 seconds, then kill if not complete
  for i in {1..10}; do
    if grep -q 'https://.*\.trycloudflare\.com' /tmp/cloud_output.txt; then
      break
    fi
    sleep 1
  done

  kill $pid 2>/dev/null

  url=$(grep -o 'https://[^ ]*\.trycloudflare\.com' /tmp/cloud_output.txt | head -n 1)
  cat /tmp/cloud_output.txt >> "$logfile"

  if [ -n "$url" ]; then
    echo "$url" > "$urlfile"
    echo "✅ Tunnel URL: $url" | tee -a "$logfile"
    sed -i "s|const TUNNEL_URL = \".*\"|const TUNNEL_URL = \"$url\"|" "$HOME/app/index.html"
    cd "$HOME/app"
    git add index.html
    git commit -m "🔁 Auto-updated Cloudflare URL to $url"
    git push
  else
    echo "❌ Failed to get URL at $(date)" | tee -a "$logfile"
  fi

  echo "🕒 Sleeping before retry..." | tee -a "$logfile"
  sleep 10
done
