"""Fallback local launcher: Python 3, no packages needed."""
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import webbrowser
root=Path(__file__).resolve().parent.parent/'dist'
server=None
for port in range(4250,4261):
    try:
        server=ThreadingHTTPServer(('127.0.0.1',port),partial(SimpleHTTPRequestHandler,directory=str(root)))
        break
    except OSError:
        pass
if server is None:
    raise SystemExit('Ports 4250–4260 are busy. Close an old game server and try again.')
url=f'http://127.0.0.1:{port}/'
print(f'RED — The Other Side\n{url}\nLeave this window open. Ctrl+C stops the server.',flush=True)
webbrowser.open(url)
try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
