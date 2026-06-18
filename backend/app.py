from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def index():
    return jsonify(message="Hello from the backend")


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    # Dev server only. In the container, gunicorn serves the app (see Dockerfile).
    app.run(host="0.0.0.0", port=5000)
