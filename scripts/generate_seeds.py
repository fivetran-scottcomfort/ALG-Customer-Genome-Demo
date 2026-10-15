"""Regenerates the seed CSVs for the Customer Genome POC.

Run from the project root:  python scripts/generate_seeds.py
User IDs are SHA-256 hashes of the lowercase email, exactly what dbt computes.
"""
import csv, hashlib, os

OUT = os.path.join(os.path.dirname(__file__), "..", "seeds")

def h(email):
    return hashlib.sha256(email.strip().lower().encode()).hexdigest()

def write(name, header, rows):
    with open(os.path.join(OUT, name + ".csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)

MARIA, HANNAH = "maria.alvarez@gmail.com", "hannah.cole@icloud.com"

# ---------------------------------------------------------------- identify
identify = [
    # Maria: the full anonymous -> known arc. Messy casing/whitespace on purpose.
    ("2026-09-29 19:15:00", "anon_a1", " Maria.Alvarez@Gmail.com ", "(303) 555-0101", "maria", "ALVAREZ"),
    # Jon / Jonathan: nickname + email variant (fuzzy, auto-merge)
    ("2026-09-25 14:30:00", "anon_j1", "jon.smith@yahoo.com", "", "Jon", "Smith"),
    # Priya: typo'd email domain (fuzzy, auto-merge)
    ("2026-09-30 11:05:00", "anon_p1", "priya.nair@gmial.com", "", "Priya", "Nair"),
    # Sam / Samuel Lee: name-only similarity (fuzzy, queued for review, NOT merged)
    ("2026-10-02 16:40:00", "anon_s1", "samlee@gmail.com", "", "Sam", "Lee"),
    # Garcia family: one shared phone, two different people (must NOT merge)
    ("2026-10-05 09:20:00", "anon_g1", "rosa.garcia@gmail.com", "720-555-0199", "Rosa", "Garcia"),
    ("2026-10-06 21:10:00", "anon_g2", "luis.garcia@gmail.com", "(720) 555-0199", "Luis", "Garcia"),
    # Travel agent: ONE shared device + phone, four different people
    ("2026-10-08 09:00:00", "anon_t1", "agent@sunsettravel.com", "800-555-0100", "Dana", "Brooks"),
    ("2026-10-08 09:30:00", "anon_t1", "tom.reyes@gmail.com", "800-555-0100", "Tom", "Reyes"),
    ("2026-10-09 10:15:00", "anon_t1", "alice.wong@outlook.com", "800-555-0100", "Alice", "Wong"),
    ("2026-10-10 11:00:00", "anon_t1", "carlos.mendez@gmail.com", "800-555-0100", "Carlos", "Mendez"),
    # Employees / competitor
    ("2026-10-03 08:00:00", "anon_e1", "kim.lopez@algvacations.com", "", "Kim", "Lopez"),
    ("2026-10-04 09:00:00", "anon_e2", "sam.ortiz@hyatt.com", "", "Sam", "Ortiz"),
    ("2026-10-04 13:00:00", "anon_c1", "pat.chen@marriott.com", "", "Pat", "Chen"),
    # Regular known visitors
    ("2026-10-07 18:30:00", "anon_h1", HANNAH, "", "Hannah", "Cole"),
    ("2026-10-01 12:00:00", "anon_o1", "owen.park@gmail.com", "", "Owen", "Park"),
]
write("raw_metarouter_identify",
      ["event_id", "event_ts", "anonymous_id", "email", "phone", "first_name", "last_name"],
      [(f"idf-{i+1:03d}",) + r for i, r in enumerate(identify)])

# -------------------------------------------------------------------- page
page = []
def pg(anon, sess, user, pages):
    for ts, path in pages:
        page.append((ts, anon, user, sess, path))

pg("anon_a1", "s_a1", "", [("2026-09-22 10:00:00", "/home"), ("2026-09-22 10:02:00", "/destinations/cancun")])
pg("anon_a1", "s_a2", "", [("2026-09-29 19:10:00", "/home"), ("2026-09-29 19:12:00", "/hotels/riu-latino")])
pg("anon_a2", "s_a3", h(MARIA), [("2026-10-06 19:40:00", "/home"), ("2026-10-06 19:45:00", "/hotels/riu-latino"),
                                  ("2026-10-06 19:52:00", "/checkout"), ("2026-10-06 20:04:00", "/checkout/confirmation")])
pg("anon_j1", "s_j1", "", [("2026-09-25 14:20:00", "/home"), ("2026-09-25 14:25:00", "/hotels/riu-palace")])
pg("anon_p1", "s_p1", "", [("2026-10-01 11:00:00", "/home"), ("2026-10-01 11:03:00", "/destinations/punta-cana")])
pg("anon_s1", "s_s1", "", [("2026-10-02 16:30:00", "/home"), ("2026-10-02 16:35:00", "/destinations/cabo")])
pg("anon_g1", "s_g1", "", [("2026-10-05 09:10:00", "/home"), ("2026-10-05 09:14:00", "/hotels/hyatt-ziva")])
pg("anon_g2", "s_g2", "", [("2026-10-06 21:00:00", "/home"), ("2026-10-06 21:06:00", "/destinations/cancun")])
pg("anon_t1", "s_t1", "", [("2026-10-08 09:00:00", "/home"), ("2026-10-08 09:05:00", "/hotels/hyatt-ziva")])
pg("anon_t1", "s_t2", "", [("2026-10-09 10:00:00", "/home"), ("2026-10-09 10:10:00", "/destinations/cancun")])
pg("anon_t1", "s_t3", "", [("2026-10-10 11:00:00", "/home"), ("2026-10-10 11:20:00", "/hotels/riu-palace")])
pg("anon_e1", "s_e1", "", [("2026-10-03 07:55:00", "/home"), ("2026-10-03 08:05:00", "/hotels/riu-latino")])
pg("anon_e2", "s_e2", "", [("2026-10-04 08:50:00", "/home"), ("2026-10-04 08:55:00", "/destinations/cabo")])
pg("anon_c1", "s_c1", "", [("2026-10-04 13:00:00", "/home"), ("2026-10-04 13:10:00", "/hotels/hyatt-ziva")])
pg("anon_h1", "s_h1", "", [("2026-10-07 18:20:00", "/home"), ("2026-10-07 18:30:00", "/hotels/riu-palace")])
pg("anon_h2", "s_h2", h(HANNAH), [("2026-10-12 20:00:00", "/home"), ("2026-10-12 20:03:00", "/hotels/riu-palace")])
pg("anon_o1", "s_o1", "", [("2026-10-01 12:00:00", "/home"), ("2026-10-01 12:04:00", "/destinations/cancun")])
pg("anon_o1", "s_o2", "", [("2026-10-12 12:10:00", "/hotels/riu-latino"), ("2026-10-12 12:25:00", "/checkout")])
# pure anonymous traffic
pg("anon_n1", "s_n1", "", [("2026-10-09 15:00:00", "/home")])                                   # 1 page: not eligible
pg("anon_n2", "s_n2", "", [("2026-10-10 12:00:00", "/home"), ("2026-10-10 12:02:00", "/destinations/cancun"),
                            ("2026-10-10 12:05:00", "/hotels/riu-latino")])                      # eligible
pg("anon_n3", "s_n3a", "", [("2026-10-02 09:00:00", "/home"), ("2026-10-02 09:03:00", "/destinations/cabo")])
pg("anon_n3", "s_n3b", "", [("2026-10-11 09:00:00", "/home"), ("2026-10-11 09:04:00", "/hotels/hyatt-ziva")])  # returning anon
pg("anon_n4", "s_n4", "", [("2026-10-11 14:00:00", "/home")])                                   # 1 page: not eligible
pg("anon_n5", "s_n5", "", [("2026-07-20 10:00:00", "/home"), ("2026-07-20 10:02:00", "/destinations/cancun")])  # >60 days old
page.sort()
write("raw_metarouter_page", ["event_id", "event_ts", "anonymous_id", "user_id", "session_id", "page_path"],
      [(f"pg-{i+1:03d}",) + r for i, r in enumerate(page)])

# ------------------------------------------------------------------- track
track = [
    ("2026-10-06 20:05:00", "anon_a2", "RES-1001", "order_completed"),
    ("2026-10-12 12:30:00", "anon_o1", "RES-1004", "order_completed"),
]
write("raw_metarouter_track", ["event_id", "event_ts", "anonymous_id", "reservation_id", "event_name"],
      [(f"trk-{i+1:03d}",) + r for i, r in enumerate(track)])

# --------------------------------------------------------------- attentive
attentive = [
    ("2026-10-01 10:00:00", "maria.alvarez@gmail.com", "+13035550101", "sms"),
    ("2026-10-02 09:00:00", "priya.nair@gmail.com", "(720) 555-0133", "email_sms"),
    ("2026-10-08 12:00:00", HANNAH, "+1 415 555 0177", "email_sms"),
]
write("raw_attentive_capture", ["event_id", "event_ts", "email", "phone", "channel"],
      [(f"att-{i+1:03d}",) + r for i, r in enumerate(attentive)])

# ---------------------------------------------------------------- bookings
bookings = [
    ("RES-1001", "2026-10-06 20:05:00", "maria.alvarez@gmail.com", "Maria", "Alvarez", "3035550101"),
    ("RES-1002", "2026-10-03 11:00:00", "jonathan.smith@yahoo.com", "Jonathan", "Smith", ""),
    ("RES-1003", "2026-08-20 15:00:00", "rosa.garcia@gmail.com", "Rosa", "Garcia", "720-555-0199"),
    ("RES-1004", "2026-10-12 12:30:00", "owen.park@gmail.com", "Owen", "Park", ""),
    ("RES-1005", "2026-10-09 14:00:00", "agent@sunsettravel.com", "Dana", "Brooks", "800-555-0100"),
]
write("raw_web_bookings", ["reservation_id", "booking_ts", "email", "first_name", "last_name", "phone"], bookings)

# -------------------------------------------------------------- bq profile
bq = [
    ("maria.alvarez@gmail.com", "+13035550101", "Maria", "Alvarez", "2026-10-07 02:00:00"),
    ("jonathan.smith@yahoo.com", "", "Jonathan", "Smith", "2026-10-04 02:00:00"),
    ("s.lee.travel@outlook.com", "", "Samuel", "Lee", "2026-10-04 02:00:00"),
    ("rosa.garcia@gmail.com", "7205550199", "Rosa", "Garcia", "2026-08-21 02:00:00"),
    ("owen.park@gmail.com", "", "Owen", "Park", "2026-10-13 02:00:00"),
]
write("raw_bq_user_profile", ["email", "phone", "user_id", "first_name", "last_name", "updated_at"],
      [(e, p, h(e), f, l, u) for e, p, f, l, u in bq])

# ------------------------------------------------------------------ config
write("survivorship_rules", ["field_name", "strategy", "source_priority"], [
    ("email", "source_priority", "web_booking|bq_user_profile|attentive_capture|metarouter_identify"),
    ("phone", "most_recent", "attentive_capture|web_booking|bq_user_profile|metarouter_identify"),
    ("first_name", "source_priority", "web_booking|bq_user_profile|metarouter_identify"),
    ("last_name", "source_priority", "web_booking|bq_user_profile|metarouter_identify"),
])
write("suppression_domains", ["domain", "category"], [
    ("algvacations.com", "employee"), ("hyatt.com", "employee"),
    ("marriott.com", "competitor"), ("hilton.com", "competitor"),
    ("sunsettravel.com", "travel_agent"),
])
print("seeds written to", os.path.abspath(OUT))
