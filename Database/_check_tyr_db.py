import os, pymysql
password = os.environ.get("BAGUETTEPIC_DB_PASSWORD") or "WhySoTyranid"
conn = pymysql.connect(host="10.0.0.22", port=3306, user="Admin", password=password, database="baguettepic", charset="utf8mb4", connect_timeout=8)
cur = conn.cursor()
cur.execute("SELECT CodexId FROM Codex WHERE CodexName=%s", ("Tyranids",))
cid = cur.fetchone()[0]
print("codex", cid)

# Sample units that changed 300->310
for name in ["Hive Tyrant", "Winged Hive Tyrant", "Zoanthrope", "Harridan", "Alpha Hierodule", "Hierophant", "Dimachaeron", "Dominatrix", "Support Tyrannofex", "Barbed Hierodule"]:
    cur.execute("SELECT BaseId, BaseName, Movement, Save, CAF, Morale FROM Base WHERE CodexId=%s AND BaseName=%s", (cid, name))
    row = cur.fetchone()
    print("\n===", name, row)
    if not row:
        continue
    bid = row[0]
    cur.execute("""
      SELECT sa.Name, bsa.AbilityValue
      FROM BaseSpecialAbility bsa
      JOIN SpecialAbility sa ON sa.SpecialAbilityId = bsa.SpecialAbilityId
      WHERE bsa.BaseId=%s ORDER BY sa.Name
    """, (bid,))
    print("  abilities:", cur.fetchall())
    cur.execute("""
      SELECT WeaponName, `Range`, Dice, ToHit, AP
      FROM WeaponProfile WHERE BaseId=%s ORDER BY WeaponName
    """, (bid,))
    print("  weapons:", cur.fetchall())
    try:
        cur.execute("""
          SELECT pp.Name FROM BasePsychicPower bpp
          JOIN PsychicPower pp ON pp.PsychicPowerId = bpp.PsychicPowerId
          WHERE bpp.BaseId=%s
        """, (bid,))
        print("  psychic:", cur.fetchall())
    except Exception as e:
        print("  psychic err", e)

# Schema peek for WeaponProfile columns
cur.execute("SHOW COLUMNS FROM WeaponProfile")
print("\nWeaponProfile cols:", [r[0] for r in cur.fetchall()])
cur.execute("SHOW COLUMNS FROM Base")
print("Base cols:", [r[0] for r in cur.fetchall()])
conn.close()
