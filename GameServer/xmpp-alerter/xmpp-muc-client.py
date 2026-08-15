#!/usr/bin/env python3

"""
Aminuxer MUC Client - Simplest XMPP chat client with configurable TLS validation     + Qwen AI 3.6-27B

Configuration:
- LOGIN: user@server.tld
- PASSWORD: your-password
- ROOM: MUC room to join
- VALIDATE_TLS_CERT: true/false/1/0
- PRINT_DEBUG_LOG: true/false/1/0   # Print detailed stanza log (slixmpp DEBUG); key status messages
"""

# Configuration
LOGIN = "ut99-bot@my-domain.ltd"
PASSWORD = "T0p-Sekret-r@ndom-pAs$w0rd"
ROOM = "ut@conference.my-jabber-server.ru"
NICK = "ut99-bot"
VALIDATE_TLS_CERT = False
PRINT_DEBUG_LOG = False

# -----------------------------------------------
VERSION = "2026-08-15"
USER_AGENT = "Aminuxer Tiny MUC client v." + VERSION
# XEP-0115 caps node: software identifier (never fetched, just hashed)
CAPS_NODE = "http://Aminuxer-Tiny-MUC/v." + VERSION

# -----------------------------------------------
import slixmpp
from slixmpp.xmlstream.handler import Callback
from slixmpp.xmlstream.matcher import StanzaPath
import logging
import socket
import sys
import time
import threading
import ssl
import asyncio
# -----------------------------------------------

# Resource name is unique per process: add hostname + datetime
RESOURCE = f"Aminuxer-MUC-{socket.gethostname()}-{time.strftime('%Y-%m-%d__%H:%M:%S')}"


def parse_tls_setting(value):
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return bool(value)
    value = str(value).lower().strip()
    if value in ('true', '1', 'yes', 'y'):
        return True
    return False

class XmppClient:
    def __init__(self, login, password, room, nick, validate_tls):
        self.login = login
        self.password = password
        self.room = room
        self.nick = nick
        self.client = None
        self.connected = False
        self.in_room = False
        self.message_buffer = []
        self.lock = threading.Lock()

        if '@' in login:
            self.server = login.split('@')[1]
        else:
            print(f"Login must contain @: {login}")
            sys.exit(1)

        self.validate_tls = parse_tls_setting(validate_tls)
        print(f"TLS Validation: {self.validate_tls}")

    async def session_start(self, event):
        """Handle session start event (async: awaits caps publication)"""
        self.connected = True
        print("Connected to server")
        print(f"Session started: {event}")

        # Register message and presence handlers (slixmpp 1.8 API: register_handler(Callback(name, matcher, pointer)))
        try:
            self.client.register_handler(
                Callback('muc_groupchat_message',
                         StanzaPath('message@type=groupchat'),
                         self.message_handler))
            self.client.register_handler(
                Callback('muc_presence',
                         StanzaPath('presence'),
                         self.presence_handler))
        except Exception as e:
            print(f"Warning: {e}")

        # Advertise the user agent: disco#info identity (XEP-0030).
        # Must run after session_bind: the static store keys on the full bound JID (user@host/resource) which disco#info queries arrive addressed to
        try:
            await self.client['xep_0030'].add_identity(
                category='client', itype='pc', name=USER_AGENT)
        except Exception as e:
            print(f"Warning: add_identity: {e}")

        # Publish entity capabilities (user agent) before joining, so the join presence already carries the caps element
        try:
            await self.client['xep_0115'].update_caps()
        except Exception as e:
            print(f"Warning: update_caps: {e}")

        # Join the MUC room; buffered messages are flushed once the room confirms our occupant presence (see presence_handler)
        self._join_room()

    def session_end(self, event):
        """Handle session end event"""
        self.connected = False
        self.in_room = False
        print("Disconnected - will reconnect in 30 seconds")

    def message_handler(self, msg):
        """Handle received groupchat messages"""
        print(f"Received from {msg['from']}: {msg['body']}")

    def _join_room(self):
        """Join the MUC room: directed presence to room/nick (XEP-0045)"""
        self.in_room = False
        try:
            self.client.send_presence(pto=f"{self.room}/{self.nick}", pshow="online")
            print(f"Joining room {self.room} as {self.nick}")
        except Exception as e:
            print(f"Join room error: {e}")

    def presence_handler(self, pres):
        """Track our own occupant presence to know when we are in the room"""
        try:
            frm = str(pres['from'])
        except Exception:
            return
        if frm != f"{self.room}/{self.nick}":
            return
        if pres['type'] == 'unavailable':
            self.in_room = False
            print("Not in the room anymore (kicked or left)")
            return
        if not self.in_room:
            self.in_room = True
            print(f"In room as {self.nick}")
            self._flush_buffer()

    def _flush_buffer(self):
        """Send buffered messages once we are in the room"""
        with self.lock:
            if not self.message_buffer:
                return
            msgs, self.message_buffer = self.message_buffer, []
        for m in msgs:
            self.client.send_message(mto=self.room, mbody=m, mtype='groupchat')
        print(f"Sent {len(msgs)} buffered messages")

    def send_message(self, message):
        """Send message to MUC room"""
        if self.connected and self.in_room:
            # Queue the send on the slixmpp event loop thread; 
            # the stdin loop runs in the main thread and asyncio.Queue is not thread-safe, so a direct send would silently stall
            self.client.loop.call_soon_threadsafe(
                lambda: self.client.send_message(
                    mto=self.room, mbody=message, mtype='groupchat'))
            print(f"Sent: {message}")
        else:
            # Buffer message until we are in the room
            with self.lock:
                self.message_buffer.append(message)
                print(f"Buffered: {message}")

    def connect(self):
        """Connect to XMPP server"""
        try:
            self.client = slixmpp.ClientXMPP(
                jid=self.login,
                password=self.password,
                plugin_config={'xep_0115': {'caps_node': CAPS_NODE}}
            )

            # Patch the client's own SSL context (in slixmpp 1.8.3 the ClientXMPP itself is the XMLStream, there is no .stream attribute;
            # get_ssl_context() always returns this context)
            if not self.validate_tls:
                ctx = self.client.ssl_context
                ctx.check_hostname = False
                ctx.verify_mode = ssl.CERT_NONE

            # Connection resource name: the bind request reads requested_jid.resource; boundjid is filled from the server reply, so setting it here would be overwritten
            self.client.requested_jid.resource = RESOURCE

            # Plugins are not loaded automatically in slixmpp 1.8.3, register explicitly (the identity is added in session_start, once the JID is bound)
            self.client.register_plugin('xep_0115')

            # Register session handlers (slixmpp 1.8 event API)
            self.client.add_event_handler('session_start', self.session_start)
            self.client.add_event_handler('session_end', self.session_end)

            # Connect, then run the event loop in a background thread
            self.client.connect()
            threading.Thread(target=self.client.process, daemon=True).start()

            print("Client starting")

        except Exception as e:
            print(f"Connection error: {e}")

    def reconnect_thread_func(self):
        """Reconnection loop with proper event loop handling"""
        while True:
            time.sleep(30)
            if not self.connected:
                try:
                    # Create event loop for this thread
                    loop = asyncio.new_event_loop()
                    asyncio.set_event_loop(loop)
                    self.connect()
                except Exception as e:
                    print(f"Reconnect error: {e}")

def main():
    # Key status messages always go to stdout; the detailed stanza log (slixmpp DEBUG) is controlled by PRINT_DEBUG_LOG
    print(f"Starting: {USER_AGENT}")
    if PRINT_DEBUG_LOG:
        logging.basicConfig(level=logging.DEBUG, format="%(name)s: %(message)s")
        logging.getLogger('slixmpp').setLevel(logging.DEBUG)

    client = XmppClient(LOGIN, PASSWORD, ROOM, NICK, VALIDATE_TLS_CERT)

    # Initial connection
    client.connect()

    # Start reconnect thread
    threading.Thread(target=client.reconnect_thread_func).start()

    # Main loop to read from stdin
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            message = line.strip()
            if message:
                client.send_message(message)
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    main()
