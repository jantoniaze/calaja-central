from flask import Flask, request, jsonify, render_template, abort, redirect, url_for
from datetime import datetime, timezone
import requests

app = Flask(__name__)

rigs = {}


def is_online(last_seen):
    try:
        last = datetime.strptime(last_seen, "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        now = datetime.now(timezone.utc)
        return (now - last).total_seconds() < 90
    except Exception:
        return False


@app.route("/api/status", methods=["POST"])
def status():
    data = request.get_json(silent=True) or {}
    rig_id = data.get("rig_id", "unknown")

    rigs[rig_id] = {
        "rig_id": rig_id,
        "worker": data.get("worker"),
        "location": data.get("location"),
        "hashrate": data.get("hashrate"),
        "cpu": data.get("cpu"),
        "ram": data.get("ram"),
        "disk": data.get("disk"),
        "temp": data.get("temp"),
        "uptime": data.get("uptime"),
        "load": data.get("load"),
        "ip": data.get("ip"),
        "ping": data.get("ping"),
        "threads": data.get("threads"),
        "accepted": data.get("accepted"),
        "rejected": data.get("rejected"),
        "pool": data.get("pool"),
        "control_url": data.get("control_url"),
        "last_seen": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    }

    return jsonify({"status": "ok"})


@app.route("/api/rigs")
def api_rigs():
    result = {}

    for rig_id, rig in rigs.items():
        r = dict(rig)
        r["online"] = is_online(rig["last_seen"])
        result[rig_id] = r

    return jsonify(result)


@app.route("/")
def index():
    rig_list = []

    for rig in rigs.values():
        r = dict(rig)
        r["online"] = is_online(rig["last_seen"])
        rig_list.append(r)

    rig_list.sort(key=lambda x: x["rig_id"])

    total_rigs = len(rig_list)
    online_rigs = sum(1 for r in rig_list if r["online"])
    offline_rigs = total_rigs - online_rigs

    return render_template(
        "index.html",
        rigs=rig_list,
        total_rigs=total_rigs,
        online_rigs=online_rigs,
        offline_rigs=offline_rigs,
        rig=None
    )


@app.route("/rig/<rig_id>")
def rig_detail(rig_id):
    rig = rigs.get(rig_id)
    if not rig:
        abort(404)

    r = dict(rig)
    r["online"] = is_online(rig["last_seen"])
    r["config"] = None
    r["local_status"] = None

    control_url = r.get("control_url")
    if control_url:
        try:
            resp = requests.get(f"{control_url}/api/local/config", timeout=5)
            if resp.ok:
                r["config"] = resp.json()
        except Exception:
            pass

        try:
            resp = requests.get(f"{control_url}/api/local/status", timeout=5)
            if resp.ok:
                r["local_status"] = resp.json()
        except Exception:
            pass

    rig_list = []
    for item in rigs.values():
        row = dict(item)
        row["online"] = is_online(item["last_seen"])
        rig_list.append(row)

    rig_list.sort(key=lambda x: x["rig_id"])

    return render_template("rig_detail.html", rig=r, rigs=rig_list)


@app.route("/rig/<rig_id>/config", methods=["POST"])
def save_rig_config(rig_id):
    rig = rigs.get(rig_id)
    if not rig:
        abort(404)

    control_url = rig.get("control_url")
    if not control_url:
        abort(400, "Rig sem control_url")

    payload = {
        "pool": {
            "POOL_HOST": request.form.get("POOL_HOST", ""),
            "POOL_PORT": request.form.get("POOL_PORT", ""),
            "POOL_USER": request.form.get("POOL_USER", ""),
            "POOL_PASS": request.form.get("POOL_PASS", ""),
            "ALGO": request.form.get("ALGO", "rx/0"),
        },
        "miner": {
            "THREADS": request.form.get("THREADS", "14"),
            "MINER": request.form.get("MINER", "xmrig"),
            "DONATE_LEVEL": request.form.get("DONATE_LEVEL", "1"),
            "CPU_PRIORITY": request.form.get("CPU_PRIORITY", "5"),
            "HUGE_PAGES": request.form.get("HUGE_PAGES", "true"),
        }
    }

    requests.post(f"{control_url}/api/local/config", json=payload, timeout=10)
    return redirect(url_for("rig_detail", rig_id=rig_id))


@app.route("/rig/<rig_id>/action/<action>", methods=["POST"])
def rig_action(rig_id, action):
    rig = rigs.get(rig_id)
    if not rig:
        abort(404)

    control_url = rig.get("control_url")
    if not control_url:
        abort(400, "Rig sem control_url")

    if action not in {"start", "stop", "restart"}:
        abort(400, "Ação inválida")

    requests.post(f"{control_url}/api/local/miner/{action}", timeout=10)
    return redirect(url_for("rig_detail", rig_id=rig_id))


@app.route("/health")
def health():
    return jsonify({
        "status": "ok",
        "rigs": len(rigs)
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
