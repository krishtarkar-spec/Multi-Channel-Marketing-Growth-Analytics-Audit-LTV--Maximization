# -*- coding: utf-8 -*-
"""
Multi-Channel Growth Marketing & LTV Engine -- data generator (v3)

v3 adds what campaign-level and predictive analytics require:
  * campaign_id on dim_users        -> revenue attributable to CAMPAIGN, not just channel
  * region on fact_marketing_spend  -> geo-targeted campaigns, no spend allocation guesswork
  * per-campaign quality profiles   -> 50 campaigns actually perform differently
  * per-region profiles             -> regions stop being 4 identical bars
  * seasonality + growth trend      -> a real 36-month series to forecast on

Carried over from v2:
  * order_value / shipping_cost generated as ARRAYS (the v1 scalar-broadcast bug)
  * unit_cost so margin is computable
  * category price/refund profiles, price-tier refund lift
  * "dirty" currency strings to preserve the ETL challenge
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import zipfile, os

SEED = 42
rng = np.random.default_rng(SEED)

NUM_USERS = 100_000
NUM_TRANSACTIONS = 1_000_000
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2025, 12, 31)
DAYS = (END_DATE - START_DATE).days + 1

channels   = ['TikTok', 'Meta', 'Google', 'Amazon Ads', 'YouTube']
regions    = ['North America', 'EMEA', 'APAC', 'LATAM']
devices    = ['iOS', 'Android', 'Web']
categories = ['Electronics', 'Fashion', 'Home & Kitchen', 'Beauty', 'Sports']

CATEGORY_PROFILE = {
    'Electronics':    {'mean_log': 6.05, 'sigma': 0.75, 'refund': 0.112, 'cost_ratio': 0.78},
    'Home & Kitchen': {'mean_log': 4.85, 'sigma': 0.70, 'refund': 0.061, 'cost_ratio': 0.62},
    'Sports':         {'mean_log': 4.55, 'sigma': 0.68, 'refund': 0.048, 'cost_ratio': 0.58},
    'Fashion':        {'mean_log': 4.20, 'sigma': 0.72, 'refund': 0.094, 'cost_ratio': 0.45},
    'Beauty':         {'mean_log': 3.65, 'sigma': 0.60, 'refund': 0.032, 'cost_ratio': 0.40},
}

CHANNEL_PROFILE = {
    'Meta':       {'share': 0.25, 'order_mult': 1.00, 'value_mult': 1.00, 'cpm': 1.00},
    'Google':     {'share': 0.20, 'order_mult': 1.35, 'value_mult': 1.18, 'cpm': 1.12},
    'TikTok':     {'share': 0.20, 'order_mult': 0.72, 'value_mult': 0.74, 'cpm': 0.82},
    'YouTube':    {'share': 0.20, 'order_mult': 0.95, 'value_mult': 1.05, 'cpm': 0.95},
    'Amazon Ads': {'share': 0.15, 'order_mult': 1.20, 'value_mult': 1.10, 'cpm': 1.25},
}

# Regions differ in basket size, refund behaviour and growth rate
REGION_PROFILE = {
    'North America': {'share': 0.34, 'value_mult': 1.22, 'refund_mult': 1.15, 'growth': 1.00, 'spend_mult': 1.35},
    'EMEA':          {'share': 0.28, 'value_mult': 1.05, 'refund_mult': 1.00, 'growth': 1.15, 'spend_mult': 1.10},
    'APAC':          {'share': 0.26, 'value_mult': 0.82, 'refund_mult': 0.80, 'growth': 1.45, 'spend_mult': 0.85},
    'LATAM':         {'share': 0.12, 'value_mult': 0.68, 'refund_mult': 0.92, 'growth': 1.60, 'spend_mult': 0.55},
}

# --- 50 campaigns, each with its own efficiency -----------------------------
campaign_ids = [f"{c}_PROMO_{i}" for c in channels for i in range(1, 11)]
_q = rng.lognormal(mean=0.0, sigma=0.42, size=len(campaign_ids))
CAMPAIGN_QUALITY = {}
for cid, q in zip(campaign_ids, _q):
    ch = cid.rsplit('_PROMO_', 1)[0]
    CAMPAIGN_QUALITY[cid] = {
        'channel':      ch,
        'order_mult':   float(np.clip(q, 0.35, 2.4)),
        'value_mult':   float(np.clip(rng.normal(1.0, 0.18), 0.6, 1.5)),
        'spend_weight': float(np.clip(rng.lognormal(0, 0.35), 0.4, 2.2)),
        'acq_weight':   float(np.clip(q * rng.normal(1.0, 0.15), 0.2, 2.6)),
    }

# --- Seasonality: Q4 lift, Feb/Jul troughs ---------------------------------
SEASON = {1: 0.86, 2: 0.80, 3: 0.94, 4: 0.97, 5: 1.02, 6: 0.99,
          7: 0.92, 8: 0.96, 9: 1.04, 10: 1.12, 11: 1.34, 12: 1.42}

print("Generating dim_users ...")

# Signups grow over time -> a real acquisition trend
day_idx = np.arange(DAYS)
trend = 1.0 + 0.9 * (day_idx / DAYS)
season_by_day = np.array([SEASON[(START_DATE + timedelta(days=int(d))).month] for d in day_idx])
signup_w = trend * season_by_day
signup_w = signup_w / signup_w.sum()
signup_offset = rng.choice(DAYS, NUM_USERS, p=signup_w)

user_region = rng.choice(regions, NUM_USERS, p=[REGION_PROFILE[r]['share'] for r in regions])

# Campaign attribution captured at signup -- this is the new key
camp_w = np.array([CHANNEL_PROFILE[CAMPAIGN_QUALITY[c]['channel']]['share'] / 10
                   * CAMPAIGN_QUALITY[c]['acq_weight'] for c in campaign_ids])
camp_w = camp_w / camp_w.sum()
user_campaign = rng.choice(campaign_ids, NUM_USERS, p=camp_w)
user_channel = np.array([CAMPAIGN_QUALITY[c]['channel'] for c in user_campaign])

df_users = pd.DataFrame({
    'user_id': np.arange(100001, 100001 + NUM_USERS),
    'signup_timestamp': [START_DATE + timedelta(days=int(d)) for d in signup_offset],
    'utm_source': user_channel,
    'campaign_id': user_campaign,
    'region': user_region,
    'device_type': rng.choice(devices, NUM_USERS, p=[0.4, 0.4, 0.2]),
})

print("Generating fact_transactions ...")
user_ids = df_users['user_id'].values
user_primary_cat = rng.choice(categories, NUM_USERS)

# Purchase propensity: channel x campaign quality x region growth
om = np.array([CHANNEL_PROFILE[c]['order_mult'] for c in user_channel])
cm = np.array([CAMPAIGN_QUALITY[c]['order_mult'] for c in user_campaign])
gm = np.array([REGION_PROFILE[r]['growth'] for r in user_region])
w = rng.gamma(1.6, 1.0, NUM_USERS) * om * cm * gm
w = w / w.sum()
tix = rng.choice(NUM_USERS, NUM_TRANSACTIONS, p=w)

use_primary = rng.random(NUM_TRANSACTIONS) < 0.65
trans_category = np.where(use_primary, user_primary_cat[tix],
                          rng.choice(categories, NUM_TRANSACTIONS))

# ORDER DATE: exponential decay from signup, then a Q4 seasonal pull
# NOTE: do NOT clip overshoot to the last day -- that piles ~16% of all
# transactions onto 2025-12-31 and destroys any trend/forecast. Redraw
# the gap for out-of-window rows instead, then drop any stragglers.
gap = rng.exponential(150, NUM_TRANSACTIONS)
offset = signup_offset[tix] + gap
for _ in range(6):                                   # redraw overshoot
    bad = offset > (DAYS - 1)
    if not bad.any():
        break
    gap[bad] = rng.exponential(150, int(bad.sum()))
    offset[bad] = signup_offset[tix][bad] + gap[bad]

keep = offset <= (DAYS - 1)                          # drop any survivors
tix = tix[keep]
offset = offset[keep].astype(int)
trans_category = trans_category[keep]
use_primary = use_primary[keep]
NUM_TRANSACTIONS = len(tix)
dates = pd.to_datetime(START_DATE) + pd.to_timedelta(offset, unit='D')

pull = rng.random(NUM_TRANSACTIONS) < 0.14          # 14% pulled into peak season
yrs = dates.year.values
peak_start = pd.to_datetime([f"{y}-11-01" for y in yrs])
peak_day = peak_start + pd.to_timedelta(rng.integers(0, 60, NUM_TRANSACTIONS), unit='D')
dates = pd.to_datetime(np.where(pull & (peak_day <= pd.Timestamp(END_DATE)), peak_day, dates))

# ORDER VALUE -- per-row array (the v1 bug), now also region/campaign scaled
mean_log = np.array([CATEGORY_PROFILE[c]['mean_log'] for c in trans_category])
sigma    = np.array([CATEGORY_PROFILE[c]['sigma'] for c in trans_category])
vmult = (np.array([CHANNEL_PROFILE[c]['value_mult'] for c in user_channel[tix]])
         * np.array([CAMPAIGN_QUALITY[c]['value_mult'] for c in user_campaign[tix]])
         * np.array([REGION_PROFILE[r]['value_mult'] for r in user_region[tix]]))

order_value = np.round(rng.lognormal(mean_log, sigma, NUM_TRANSACTIONS) * vmult, 2)
order_value = np.clip(order_value, 5.00, 6000.00)

shipping_cost = np.round(rng.uniform(3, 12, NUM_TRANSACTIONS) + order_value * 0.012, 2)
cost_ratio = np.array([CATEGORY_PROFILE[c]['cost_ratio'] for c in trans_category])
unit_cost = np.clip(np.round(order_value * cost_ratio * rng.normal(1.0, 0.06, NUM_TRANSACTIONS), 2), 1.00, None)

# REFUNDS: category base x price-tier lift x region behaviour
base_refund = np.array([CATEGORY_PROFILE[c]['refund'] for c in trans_category])
price_lift = np.where(order_value > 200, 1.55, np.where(order_value < 50, 0.70, 1.00))
region_rmult = np.array([REGION_PROFILE[r]['refund_mult'] for r in user_region[tix]])
refund_prob = np.clip(base_refund * price_lift * region_rmult, 0.005, 0.45)
is_refunded = (rng.random(NUM_TRANSACTIONS) < refund_prob).astype(int)

df_transactions = pd.DataFrame({
    'user_id': user_ids[tix],
    'order_value': order_value,
    'shipping_cost': shipping_cost,
    'unit_cost': unit_cost,
    'is_refunded': is_refunded,
    'category': trans_category,
    'order_date': dates,
})
for col in ['order_value', 'shipping_cost', 'unit_cost']:
    df_transactions[col] = df_transactions[col].apply(lambda x: f"$ {x:,.2f}")

# --- Marketing spend: now CAMPAIGN x REGION x DAY --------------------------
print("Generating fact_marketing_spend ...")
all_days = pd.date_range(START_DATE, END_DATE)
n_days = len(all_days)
day_season = np.array([SEASON[d.month] for d in all_days])
day_trend = 1.0 + 0.6 * (np.arange(n_days) / n_days)

rows = []
for cid in campaign_ids:
    ch = CAMPAIGN_QUALITY[cid]['channel']
    sw = CAMPAIGN_QUALITY[cid]['spend_weight']
    cpm = CHANNEL_PROFILE[ch]['cpm']
    for reg in regions:
        rm = REGION_PROFILE[reg]['spend_mult']
        base = rng.uniform(60, 260, n_days) * sw * rm * cpm * day_season * day_trend
        clicks = (base / rng.uniform(0.9, 2.1, n_days)).astype(int)
        impr = clicks * rng.integers(10, 50, n_days)
        for d, s, c, i in zip(all_days, base, clicks, impr):
            rows.append([d, ch, cid, reg, f"$ {s:,.2f}", int(i), int(c)])

df_marketing = pd.DataFrame(rows, columns=['date', 'utm_source', 'campaign_id',
                                           'region', 'total_spend', 'impressions', 'clicks'])

files = {'dim_users.csv': df_users,
         'fact_transactions.csv': df_transactions,
         'fact_marketing_spend.csv': df_marketing}

zip_name = "LTV_Audit_Dataset_v3.zip"
with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as zf:
    for fn, df in files.items():
        df.to_csv(fn, index=False)
        zf.write(fn)
        os.remove(fn)

print(f"\nSUCCESS: {zip_name}")
print(f"users={len(df_users):,}  transactions={len(df_transactions):,}  spend={len(df_marketing):,}")
print(f"distinct order_value = {df_transactions['order_value'].nunique():,}  (must NOT be 1)")
print(f"campaigns = {df_users['campaign_id'].nunique()}")
