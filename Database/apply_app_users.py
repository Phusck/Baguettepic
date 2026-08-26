"""Create AppUser and attach Army.UserId. Password from BAGUETTEPIC_DB_PASSWORD."""
from __future__ import annotations

import base64
import hashlib
import os
from pathlib import Path

import pymysql
from pymysql.constants import CLIENT

ROOT = Path(__file__).resolve().parent
HOSTS = [("10.0.0.22", 3306), ("87.57.158.180", 37202)]
ITERATIONS = 100_000


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, ITERATIONS, 32)
    return (
        f"pbkdf2-sha256${ITERATIONS}$"
        f"{base64.b64encode(salt).decode()}$"
        f"{base64.b64encode(dk).decode()}"
    )


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
                client_flag=CLIENT.MULTI_STATEMENTS,
            )
        except Exception as ex:
            last = ex
    raise last or RuntimeError("Could not reach the database.")


def column_exists(cur, table: str, column: str) -> bool:
    cur.execute(
        """
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = %s AND COLUMN_NAME = %s
        """,
        (table, column),
    )
    return cur.fetchone()[0] > 0


def index_exists(cur, table: str, name: str) -> bool:
    cur.execute(
        """
        SELECT COUNT(*) FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = %s AND INDEX_NAME = %s
        """,
        (table, name),
    )
    return cur.fetchone()[0] > 0


def fk_exists(cur, table: str, name: str) -> bool:
    cur.execute(
        """
        SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = %s AND CONSTRAINT_NAME = %s
        """,
        (table, name),
    )
    return cur.fetchone()[0] > 0


def main() -> None:
    password = os.environ["BAGUETTEPIC_DB_PASSWORD"]
    conn = connect(password)
    cur = conn.cursor()
    sql = (ROOT / "migrate-app-users.sql").read_text(encoding="utf-8")
    cur.execute(sql)
    while cur.nextset():
        pass

    cur.execute("SELECT UserId FROM AppUser WHERE Username = %s", ("Admin",))
    row = cur.fetchone()
    if row is None:
        cur.execute(
            """
            INSERT INTO AppUser (Username, PasswordHash, IsAdmin, MustChangePassword)
            VALUES (%s, %s, 1, 0)
            """,
            ("Admin", hash_password("WhySoTyranid")),
        )
        print("seeded Admin")
        cur.execute("SELECT UserId FROM AppUser WHERE Username = %s", ("Admin",))
        row = cur.fetchone()
    admin_id = row[0]

    if not column_exists(cur, "Army", "UserId"):
        cur.execute("ALTER TABLE Army ADD COLUMN UserId INT UNSIGNED NULL AFTER ArmyId")
        print("added Army.UserId")

    cur.execute("UPDATE Army SET UserId = %s WHERE UserId IS NULL", (admin_id,))
    cur.execute("ALTER TABLE Army MODIFY UserId INT UNSIGNED NOT NULL")

    if not index_exists(cur, "Army", "UQ_Army_User_Name"):
        cur.execute("ALTER TABLE Army ADD UNIQUE KEY UQ_Army_User_Name (UserId, ArmyName)")
        print("added UQ_Army_User_Name")
    if index_exists(cur, "Army", "UQ_Army_Name"):
        cur.execute("ALTER TABLE Army DROP INDEX UQ_Army_Name")
        print("dropped UQ_Army_Name")
    if not fk_exists(cur, "Army", "FK_Army_User"):
        cur.execute(
            """
            ALTER TABLE Army
            ADD CONSTRAINT FK_Army_User
                FOREIGN KEY (UserId) REFERENCES AppUser (UserId)
                ON UPDATE CASCADE ON DELETE RESTRICT
            """
        )
        print("added FK_Army_User")

    cur.execute("SELECT COUNT(*) FROM AppUser")
    users = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM Army WHERE UserId = %s", (admin_id,))
    armies = cur.fetchone()[0]
    print("users", users, "admin armies", armies)
    conn.close()


if __name__ == "__main__":
    main()
