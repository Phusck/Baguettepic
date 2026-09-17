"""Apply a codex SQL seed (multi-statement). Preserves armies.

Usage: python apply_codex_sql.py exodites.sql
Password from BAGUETTEPIC_DB_PASSWORD, else WhySoTyranid.
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

import pymysql

ROOT = Path(__file__).resolve().parent
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
                autocommit=False,
                connect_timeout=8,
            )
        except Exception as ex:
            last = ex
    raise last or RuntimeError("Could not reach the database.")


def split_statements(sql: str) -> list[str]:
    stmts: list[str] = []
    buf: list[str] = []
    in_single = False
    i = 0
    while i < len(sql):
        ch = sql[i]
        if ch == "'" and in_single:
            if i + 1 < len(sql) and sql[i + 1] == "'":
                buf.append("''")
                i += 2
                continue
            in_single = False
            buf.append(ch)
        elif ch == "'" and not in_single:
            in_single = True
            buf.append(ch)
        elif ch == ";" and not in_single:
            stmt = "".join(buf).strip()
            if stmt:
                stmts.append(stmt)
            buf = []
        else:
            buf.append(ch)
        i += 1
    stmt = "".join(buf).strip()
    if stmt:
        stmts.append(stmt)
    return stmts


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: python apply_codex_sql.py <file.sql>")
    sql_path = ROOT / sys.argv[1]
    password = os.environ.get("BAGUETTEPIC_DB_PASSWORD") or "WhySoTyranid"
    raw = sql_path.read_text(encoding="utf-8")
    sql = "\n".join(
        line for line in raw.splitlines() if not line.strip().startswith("--")
    )
    if re.search(r"DELETE\s+FROM\s+Army\b", sql, re.I):
        raise SystemExit("Refusing to apply: SQL deletes Army rows.")

    conn = connect(password)
    cur = conn.cursor()
    try:
        cur.execute("SELECT COUNT(*) FROM Army")
        before = cur.fetchone()[0]
        for stmt in split_statements(sql):
            cur.execute(stmt)
        cur.execute("SELECT COUNT(*) FROM Army")
        after = cur.fetchone()[0]
        conn.commit()
        print(f"Applied {sql_path.name}; armies {before}/{after}")
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
