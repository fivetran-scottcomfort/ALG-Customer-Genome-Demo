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
identify += [
    # Dev: known visitor who abandons a cart (the RFP's DFW -> CUN example)
    ("2026-10-13 17:55:00", "anon_d1", "dev.patel@gmail.com", "(214) 555-0166", "Dev", "Patel"),
    # Grace: booked recently, then starts another cart (must be excluded from cart-abandon)
    ("2026-10-02 13:00:00", "anon_k1", "grace.kim@outlook.com", "(415) 555-0142", "Grace", "Kim"),
    # Tyler: abandoned a cart long ago (outside the cart window, still a prospect)
    ("2026-09-04 20:00:00", "anon_r1", "tyler.reed@gmail.com", "", "Tyler", "Reed"),
    # Noah: known visitor, browses only
    ("2026-10-11 08:30:00", "anon_m1", "noah.berg@gmail.com", "", "Noah", "Berg"),
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
GRACE = "grace.kim@outlook.com"
pg("anon_d1", "s_d1", "", [("2026-10-13 17:50:00", "/home"), ("2026-10-13 17:54:00", "/destinations/cancun"),
                            ("2026-10-13 17:58:00", "/hotels/riu-latino"), ("2026-10-13 18:04:00", "/checkout")])
pg("anon_c2", "s_c2", "", [("2026-10-14 11:00:00", "/home"), ("2026-10-14 11:05:00", "/hotels/riu-palace"),
                            ("2026-10-14 11:12:00", "/checkout")])          # anonymous cart abandoner
pg("anon_k1", "s_k1", "", [("2026-10-02 12:50:00", "/home"), ("2026-10-02 12:55:00", "/hotels/riu-palace")])
pg("anon_k2", "s_k2", h(GRACE), [("2026-10-14 09:00:00", "/home"), ("2026-10-14 09:06:00", "/checkout")])
pg("anon_r1", "s_r1", "", [("2026-09-05 19:00:00", "/home"), ("2026-09-05 19:06:00", "/hotels/riu-latino"),
                            ("2026-09-05 19:10:00", "/checkout")])
pg("anon_n6", "s_n6", "", [("2026-10-13 10:00:00", "/home"), ("2026-10-13 10:03:00", "/destinations/cabo")])
pg("anon_n7", "s_n7", "", [("2026-10-14 13:00:00", "/home"), ("2026-10-14 13:02:00", "/destinations/cancun"),
                            ("2026-10-14 13:06:00", "/hotels/hyatt-ziva")])
pg("anon_n8", "s_n8a", "", [("2026-10-08 16:00:00", "/home"), ("2026-10-08 16:04:00", "/hotels/riu-palace")])
pg("anon_n8", "s_n8b", "", [("2026-10-14 16:00:00", "/home"), ("2026-10-14 16:05:00", "/destinations/punta-cana")])
pg("anon_m1", "s_m1", "", [("2026-10-11 08:20:00", "/home"), ("2026-10-11 08:26:00", "/destinations/punta-cana")])
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

# -------------------------------------------------------------------- cart
IMG = "https://images.example.com/hotels/"
cart = [
    # (ts, anon, user_id, session, origin, dest, depart, return, hotel, image, value)
    ("2026-10-06 19:53:00", "anon_a2", h(MARIA), "s_a3", "DEN", "CUN", "2026-11-20", "2026-11-24", "Riu Latino - Adults Only", IMG + "riu-latino.jpg", 2210),   # booked 12 min later
    ("2026-10-12 12:20:00", "anon_o1", "", "s_o2", "ORD", "CUN", "2026-12-01", "2026-12-05", "Riu Palace Peninsula", IMG + "riu-palace-peninsula.jpg", 1985),  # booked 10 min later
    ("2026-10-13 18:05:00", "anon_d1", "", "s_d1", "DFW", "CUN", "2026-10-31", "2026-11-02", "Riu Latino - Adults Only", IMG + "riu-latino.jpg", 1840),      # ABANDONED
    ("2026-10-14 11:13:00", "anon_c2", "", "s_c2", "DEN", "PUJ", "2026-11-14", "2026-11-18", "Riu Palace Punta Cana", IMG + "riu-palace-punta-cana.jpg", 2760),  # ABANDONED (anonymous)
    ("2026-10-14 09:07:00", "anon_k2", h(GRACE), "s_k2", "ORD", "MBJ", "2026-12-05", "2026-12-10", "Hyatt Ziva Rose Hall", IMG + "hyatt-ziva-rose-hall.jpg", 3120),  # booked 4 days ago
    ("2026-09-05 19:11:00", "anon_r1", "", "s_r1", "LAX", "CUN", "2026-10-01", "2026-10-05", "Hyatt Ziva Cancun", IMG + "hyatt-ziva-cancun.jpg", 1575),        # too old
]
cart.sort()
write("raw_metarouter_cart",
      ["event_id", "event_ts", "anonymous_id", "user_id", "session_id", "origin", "destination",
       "depart_date", "return_date", "hotel_name", "hotel_image_url", "cart_value"],
      [(f"crt-{i+1:03d}",) + r for i, r in enumerate(cart)])

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
bookings.append(("RES-1006", "2026-10-10 12:00:00", "grace.kim@outlook.com", "Grace", "Kim", "4155550142"))
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
