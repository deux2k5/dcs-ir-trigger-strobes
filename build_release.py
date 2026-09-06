"""Build the standalone I2 mod using only this public repository."""
from pathlib import Path
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parent
mod = Path("Mods/tech/USLANTCOM I2 Beacon")
payload = {p.relative_to(root).as_posix(): p.read_bytes()
           for p in (root / mod).rglob("*") if p.is_file()}
assert (mod / "entry.lua").as_posix() in payload
assert (mod / "Shapes/USLANTCOM_I2_BEACON.edm").as_posix() in payload
payload[(mod / "Scripts/IR_Runway.lua").as_posix()] = (root / "IR_Runway.lua").read_bytes()
payload[(mod / "README.md").as_posix()] = (root / "README.md").read_bytes()
payload["README.md"] = (root / "README.md").read_bytes()
hashes = {name: hashlib.sha256(data).hexdigest() for name, data in payload.items()}
output = root / "dist/USLANTCOM_I2_Beacon_Standalone.zip"
output.parent.mkdir(exist_ok=True)
temporary = output.with_suffix(".new.zip")
with zipfile.ZipFile(temporary, "w", zipfile.ZIP_DEFLATED) as archive:
    for name, data in sorted(payload.items()):
        archive.writestr(name, data)
    archive.writestr("SHA256.json", json.dumps(hashes, indent=2))
with zipfile.ZipFile(temporary) as archive:
    assert archive.testzip() is None
    for name, digest in hashes.items():
        assert hashlib.sha256(archive.read(name)).hexdigest() == digest
temporary.replace(output)
print(f"{output}\nSHA256: {hashlib.sha256(output.read_bytes()).hexdigest()}")
