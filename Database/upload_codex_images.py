"""Upload figure PNGs for a Codex into Base.Image.

Usage:
  python upload_codex_images.py Exodites
  python upload_codex_images.py Biel-Tan

Password from BAGUETTEPIC_DB_PASSWORD, else WhySoTyranid.
"""
from __future__ import annotations

import importlib
import os
import sys
from pathlib import Path

import pymysql

ROOT = Path(__file__).resolve().parent
FIGURES = ROOT / "figures"
HOSTS = [("10.0.0.22", 3306), ("87.57.158.180", 37202)]

CODEX_MODULES = {
    "Tyranids": "_gen_tyranids",
    "Exodites": "_gen_exodites",
    "Biel-Tan": "_gen_biel_tan",
    "Necrons": "_gen_necrons",
}


def connect(password: str) -> pymysql.Connection:
    last: Exception | None = None
    for host, port in HOSTS:
        try:
            return pymysql.connect(
                host=host,
                port=port,
                user="Admin",
                password=password,
                database="baguettepic",
                charset="utf8mb4",
                autocommit=True,
                connect_timeout=8,
            )
        except Exception as ex:
            last = ex
    raise last or RuntimeError("Could not reach the database.")


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: python upload_codex_images.py <CodexName>")
    codex = sys.argv[1]
    mod_name = CODEX_MODULES.get(codex)
    if not mod_name:
        raise SystemExit(f"Unknown codex {codex!r}. Known: {', '.join(CODEX_MODULES)}")

    sys.path.insert(0, str(ROOT))
    mod = importlib.import_module(mod_name)
    bases = getattr(mod, "BASES")
    image_path_for = getattr(mod, "image_path_for")

    password = os.environ.get("BAGUETTEPIC_DB_PASSWORD") or "WhySoTyranid"
    conn = connect(password)
    cur = conn.cursor()
    cur.execute("SELECT CodexId FROM Codex WHERE CodexName = %s", (codex,))
    row = cur.fetchone()
    if row is None:
        raise SystemExit(f"{codex} codex not found.")
    codex_id = row[0]

    uploaded = 0
    skipped = 0
    missing: list[str] = []
    for base in bases:
        name = base["name"] if isinstance(base, dict) else base.name
        filename = image_path_for(name)
        if not filename:
            continue
        path = FIGURES / filename
        if not path.is_file():
            missing.append(f"{name} -> {filename}")
            continue
        data = path.read_bytes()
        cur.execute(
            "SELECT OCTET_LENGTH(Image) FROM `Base` WHERE CodexId = %s AND BaseName = %s",
            (codex_id, name),
        )
        existing = cur.fetchone()
        if existing is None:
            missing.append(f"{name} (no matching Base row)")
            continue
        if existing[0] and existing[0] == len(data):
            skipped += 1
            continue
        cur.execute(
            "UPDATE `Base` SET Image = %s WHERE CodexId = %s AND BaseName = %s",
            (data, codex_id, name),
        )
        uploaded += 1
        print(f"uploaded {name} ({len(data)} bytes)")

    cur.execute(
        """
        SELECT COUNT(*) FROM `Base`
        WHERE CodexId = %s AND Image IS NOT NULL AND OCTET_LENGTH(Image) > 0
        """,
        (codex_id,),
    )
    print(
        f"{codex}: bases with images={cur.fetchone()[0]} "
        f"uploaded={uploaded} unchanged={skipped}"
    )
    if missing:
        print("missing figure or base:")
        for item in missing:
            print(" ", item)
    conn.close()


if __name__ == "__main__":
    main()
