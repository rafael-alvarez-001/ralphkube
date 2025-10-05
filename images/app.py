from flask import Flask, jsonify
import os

app = Flask(__name__)


@app.get("/health")
def health():
    return "up", 200, {"Content-Type": "text/plain; charset=utf-8"}


@app.get("/hello")
def hello():
    return jsonify({"message": "hello world"})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)


