from flask import Flask, request, jsonify
from datetime import datetime

app = Flask(__name__)

rigs = {}

@app.route("/api/status", methods=["POST"])
def status():
    data = request.get_json(silent=True) or {}

    rig_id = data.get("rig_id", "unknown-rig")

    rigs[rig_id] = {
        "last_seen": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "hashrate": data.get("hashrate", "n/a"),
        "cpu": data.get("cpu", "n/a"),
        "ram": data.get("ram", "n/a"),
        "disk": data.get("disk", "n/a"),
        "temp": data.get("temp", "n/a"),
        "uptime": data.get("uptime", "n/a"),
        "load": data.get("load", "n/a"),
        "ip": data.get("ip", "n/a"),
        "ping": data.get("ping", "n/a"),
        "worker": data.get("worker", "n/a"),
        "location": data.get("location", "n/a"),
        "threads": data.get("threads", "n/a"),
        "accepted": data.get("accepted", "n/a"),
        "rejected": data.get("rejected", "n/a"),
        "pool": data.get("pool", "n/a")
    }

    return jsonify({"status": "ok", "rig_id": rig_id})

@app.route("/api/rigs", methods=["GET"])
def get_rigs():
    return jsonify(rigs)

@app.route("/")
def index():
    return jsonify({
        "service": "Calaja Central",
        "status": "online",
        "port": 5001,
        "rigs_count": len(rigs)
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
