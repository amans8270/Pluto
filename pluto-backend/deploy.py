import os
import subprocess

os.environ["PYTHONIOENCODING"] = "utf-8"
os.environ["PYTHONUTF8"] = "1"

os.chdir(r"C:\Users\amans\OneDrive\Desktop\dating app\pluto-backend")

result = subprocess.run(
    ["fastapi", "cloud", "deploy"],
    capture_output=False,
    env={**os.environ, "PYTHONIOENCODING": "utf-8"},
)
