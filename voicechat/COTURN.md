# Using coturn for voice chat relaying

Voice goes directly between players when their networks allow it. When they don't
(strict NAT, mobile/CGNAT, some countries' filtering), it goes through a TURN relay.

By default the node server runs a small built-in relay (`node-turn`) on UDP 3478. It needs
no setup, but it only speaks UDP. Some networks, notably in Russia, block or throttle UDP
voice traffic to foreign servers. [coturn](https://github.com/coturn/coturn) can relay over
TCP and over TLS on port 443, which looks like normal HTTPS traffic and gets through far more often.

Without `voicechat/node/turn_config.json`, nothing changes and the built-in relay is used.

## 1. Install coturn

```bash
sudo apt install coturn
sudo sed -i 's/#TURNSERVER_ENABLED=1/TURNSERVER_ENABLED=1/' /etc/default/coturn  # older Debian/Ubuntu packages only
```

## 2. Configure `/etc/turnserver.conf`

Generate a secret with `openssl rand -hex 32`.

```ini
listening-port=3478
# only needed for TURN over TLS, see step 4
tls-listening-port=443

# only if the machine is behind NAT (most cloud VMs are not, docker usually is)
# external-ip=PUBLIC_IP/PRIVATE_IP

realm=voicechat
use-auth-secret
static-auth-secret=YOUR_SECRET
fingerprint

min-port=49152
max-port=65535

# security: don't let the relay be used to reach the server's own network
no-multicast-peers
denied-peer-ip=10.0.0.0-10.255.255.255
denied-peer-ip=172.16.0.0-172.31.255.255
denied-peer-ip=192.168.0.0-192.168.255.255
denied-peer-ip=127.0.0.0-127.255.255.255
no-cli
```

If you don't set up TLS, remove the `tls-listening-port` line and add `no-tls` and `no-dtls`.

Then `sudo systemctl enable --now coturn`.

## 3. Point the voice server at coturn

Copy `voicechat/node/turn_config.example.json` to `voicechat/node/turn_config.json`
(it is gitignored, it holds the secret), set `secret` to the same value, and restart
voice chat (admin verb "Restart Voicechat", or restart the server). The node log should say
`TURN mode: coturn`. In coturn mode the built-in relay is not started, so coturn can use port 3478.

`{host}` in a url is replaced by the game server address players connect to. Without TLS, use:

```json
"urls": ["turn:{host}:3478?transport=udp", "turn:{host}:3478?transport=tcp"]
```

## 4. TURN over TLS on 443 (best for Russia)

Browsers check the certificate, so this needs a domain name pointing at the server
(e.g. `turn.yourserver.com`) and a real certificate, e.g. from Let's Encrypt:

```bash
sudo apt install certbot
sudo certbot certonly --standalone -d turn.yourserver.com
```

Add to `turnserver.conf`:

```ini
cert=/etc/letsencrypt/live/turn.yourserver.com/fullchain.pem
pkey=/etc/letsencrypt/live/turn.yourserver.com/privkey.pem
```

coturn has to be able to read those files (e.g. copy them in a certbot deploy hook, or add
the `turnserver` user to a group that can read them), and needs restarting after renewals.
Port 443 must not already be used by a web server on the same IP.

Then add `"turns:turn.yourserver.com:443?transport=tcp"` to `urls` (use the domain, not `{host}`).

## 5. Firewall

Open inbound:

| Port | Protocol | For |
| --- | --- | --- |
| 3000 (or `PORT_VOICECHAT`) | TCP | voice chat page connection (already needed) |
| 3478 | UDP and TCP | STUN/TURN |
| 443 | TCP | TURN over TLS, if set up |
| 49152-65535 | UDP | relayed audio |

## Checking it works

In Chrome open `chrome://webrtc-internals` while in voice chat. The selected candidate pair
shows `relay` and the protocol when a player is going through coturn. Or test the server with
https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/ using a username and password
generated with:

```bash
u="$(($(date +%s) + 3600)):test"; echo "$u"; echo -n "$u" | openssl dgst -sha1 -hmac YOUR_SECRET -binary | base64
```
