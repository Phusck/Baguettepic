"""Upload figure PNGs into Base.Image.

Password from BAGUETTEPIC_DB_PASSWORD. Does not re-run tyranids.sql.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

import pymysql

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

from _gen_tyranids import BASES, image_path_for  # noqa: E402

FIGURES = ROOT / "figures"
HOSTS = [("10.0.0.22", 3306), ("87.57.158.180", 37202)]


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


def apply_schema(cur) -> None:
    sql = (ROOT / "migrate-base-image.sql").read_text(encoding="utf-8")
    for stmt in sql.split(";"):
        stmt = "\n".join(
            line for line in stmt.splitlines() if not line.strip().startswith("--")
        ).strip()
        if stmt:
            cur.execute(stmt)


def main() -> None:
    password = os.environ["BAGUETTEPIC_DB_PASSWORD"]
    conn = connect(password)
    cur = conn.cursor()
    apply_schema(cur)
    cur.execute("SELECT CodexId FROM Codex WHERE CodexName = %s", ("Tyranids",))
    row = cur.fetchone()
    if row is None:
        raise SystemExit("Tyranids codex not found.")
    codex_id = row[0]

    uploaded = 0
    missing: list[str] = []
    for base in BASES:
        name = base["name"]
        filename = image_path_for(name)
        if not filename:
            cur.execute(
                "UPDATE `Base` SET Image = NULL WHERE CodexId = %s AND BaseName = %s",
                (codex_id, name),
            )
            continue
        path = FIGURES / filename
        if not path.is_file():
            missing.append(f"{name} -> {filename}")
            continue
        data = path.read_bytes()
        n = cur.execute(
            "UPDATE `Base` SET Image = %s WHERE CodexId = %s AND BaseName = %s",
            (data, codex_id, name),
        )
        if n:
            uploaded += 1
            print(f"uploaded {name} ({len(data)} bytes)")
        else:
            missing.append(f"{name} (no matching Base row)")

    cur.execute(
        """
        SELECT COUNT(*) FROM `Base`
        WHERE CodexId = %s AND Image IS NOT NULL AND OCTET_LENGTH(Image) > 0
        """,
        (codex_id,),
    )
    print("bases with images:", cur.fetchone()[0], "uploaded this run:", uploaded)
    if missing:
        print("missing:")
        for item in missing:
            print(" ", item)
    conn.close()


if __name__ == "__main__":
    main()
