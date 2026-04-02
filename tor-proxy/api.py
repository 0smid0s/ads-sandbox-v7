from flask import Flask, jsonify
import socket
import requests

app = Flask(__name__)

def send_signal(signal: str):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(5)
            s.connect(("127.0.0.1", 9055))
            s.sendall(b'AUTHENTICATE ""\r\n')
            auth_resp = b""
            while b"\r\n" not in auth_resp:
                auth_resp += s.recv(1024)
            if b"250" not in auth_resp:
                return False, f"Auth failed: {auth_resp.decode()}"
            s.sendall(f"SIGNAL {signal}\r\n".encode())
            sig_resp = b""
            while b"\r\n" not in sig_resp:
                sig_resp += s.recv(1024)
            return b"250" in sig_resp, sig_resp.decode().strip()
    except Exception as e:
        return False, str(e)

@app.route("/start")
def start():
    return jsonify({"status": "tor is running"})

@app.route("/stop")
def stop():
    ok, detail = send_signal("SHUTDOWN")
    return jsonify({"status": "stopped" if ok else "error", "detail": detail})

@app.route("/restart")
def restart():
    ok, detail = send_signal("RELOAD")
    return jsonify({"status": "restarted" if ok else "error", "detail": detail})

@app.route("/reset-ip")
def reset_ip():
    ok, detail = send_signal("NEWNYM")
    return jsonify({"status": "new identity requested" if ok else "error", "detail": detail})

@app.route("/ip")
def get_ip():
    try:
        proxies = {"http": "socks5h://127.0.0.1:9055", "https": "socks5h://127.0.0.1:9055"}
        ip = requests.get("https://api.ipify.org", proxies=proxies, timeout=15).text
        return jsonify({"ip": ip})
    except Exception as e:
        return jsonify({"status": "error", "detail": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5005)
