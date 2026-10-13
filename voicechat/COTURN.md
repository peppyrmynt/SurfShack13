# Using coturn for voice chat relaying

Voice goes directly between players when their networks allow it. When they don't
(strict NAT, mobile/CGNAT, some countries' filtering), it goes through a TURN relay.

By default the node server runs a small built-in relay (`node-turn`) on UDP 3478. It needs
no setup, but it only speaks UDP. Some networks, notably in Russia, block or throttle UDP
voice traffic to foreign servers. [coturn](https://github.com/coturn/coturn) can relay over
TCP and over TLS on port 443, which looks like normal HTTPS traffic and gets through far more often.

Without `voicechat/node/turn_config.json`, nothing changes and the built-in relay is used.

## How voice picks a path

There are two separate choices.

**1. Which relay server exists (server side, chosen by you).** Only one runs at a time:

| `voicechat/node/turn_config.json` | Relay used |
| --- | --- |
| missing, or `"mode": "builtin"` | built-in `node-turn`, UDP 3478 only |
| `"mode": "coturn"` with `secret` and `urls` | coturn; the built-in relay is not started |

It is read when the node server starts, so restart voice chat after changing it. The node log
prints `TURN mode: builtin` or `TURN mode: coturn`. If the file is broken or missing `secret`/`urls`,
it logs an error and falls back to the built-in relay.

If you stay on the built-in relay and the server is behind NAT (e.g. Docker), use
`{"mode": "builtin", "externalIp": "YOUR.PUBLIC.IP"}` so relays hand out the public address.

**2. Which path each pair of players uses (automatic, in the browser).** When two players get
near each other, both browsers collect every way they could be reached, then test them all
at once (WebRTC "ICE"):

1. **Direct**: their own addresses, plus their public address learned from the STUN server.
   Used whenever it works; most players connect this way and the relay isn't involved.
2. **Relay over UDP**: through the relay's UDP port 3478.
3. **Relay over TCP**: through `turn:...?transport=tcp` (coturn only).
4. **Relay over TLS**: through `turns:...:443` (coturn only, needs a domain and certificate).

The browser prefers them in that order and keeps the best one that actually works. Nothing needs
to be configured per player, and it's decided separately for every pair, so a player in Russia
can be relayed over TLS while everyone else keeps talking directly. Only the player whose network
blocks things needs the relay; the other side just sends UDP to the relay's address.

## Players in Russia (or anywhere UDP voice is blocked)

Russian ISPs block or throttle WebRTC voice to many foreign servers, mostly UDP. Google's STUN
servers are also blocked there, which is why the game server's own STUN is listed first.
The built-in relay only speaks UDP, so for those players it fails. To make them work:

1. Set up coturn (steps 1-3 below), with at least `turn:{host}:3478?transport=tcp` in `urls`.
   That already gets through plain UDP blocking.
2. Best: also set up TLS on 443 (step 4). The relay traffic then looks like an ordinary HTTPS
   connection to your server, which is the hardest thing for filtering to block.
3. Open the firewall ports (step 5).
4. Have a Russian player check it (see "Checking it works"): the connection should show
   `relay` with protocol `tcp` or `tls`.

The voice page itself also connects to the game server over TCP (port 3000 by default). If that
port is blocked for someone, no relay helps; it would need to be moved behind the same port 443
with a reverse proxy, which this setup doesn't cover.

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

In the node log, look for `TURN mode: coturn`.

In Chrome open `chrome://webrtc-internals` while in voice chat. The selected candidate pair
shows `relay` and the protocol when a player is going through coturn. Or test the server with
https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/ using a username and password
generated with:

```bash
u="$(($(date +%s) + 3600)):test"; echo "$u"; echo -n "$u" | openssl dgst -sha1 -hmac YOUR_SECRET -binary | base64
```
