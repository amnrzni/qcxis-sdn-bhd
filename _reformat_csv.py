import csv, io

SRC = r'c:\Users\ADMIN\Desktop\Workspace\qcxis-sdn-bhd\QCXIS_Forecast_Monthly.csv'
DST = SRC  # overwrite in-place

# ── Column indices in the original row ──────────────────────────────
I_SCENARIO    = 0
I_YEAR        = 1
I_MONTH       = 2
I_PERIOD      = 3
I_REV_FEE     = 4
I_REV_HR      = 5
I_REV_POR     = 6
I_REV_TOT     = 7
I_INFRA_FEE   = 8
I_INFRA_TOT   = 9
I_CEO         = 10
I_DCEO        = 11
I_IT_TRF      = 12
I_IT_NEW      = 13
I_ADMIN       = 14
I_PAY_TOT     = 15
I_ONEOFFS     = 16
I_CONT        = 17
I_MGMT_TOT    = 18
I_COST_TOT    = 19
I_NET         = 20
I_CUM         = 21

IT_TRF_CTC = 3196.17   # (2200+450)*1.1495 + 150
IT_NEW_CTC = 2966.28   # (2000+450)*1.1495 + 150

# ── Read Optimum rows only ───────────────────────────────────────────
rows = []
with open(SRC, 'r', newline='') as f:
    reader = csv.reader(f)
    for raw in reader:
        if raw and raw[0] == 'Optimum':
            rows.append(raw)

# ── Patch Jan-27 to May-27: move IT staff start from Jun→Jan ────────
MONTHS_27_EARLY = {'Jan', 'Feb', 'Mar', 'Apr', 'May'}

cumulative = 0.0
for row in rows:
    year  = int(row[I_YEAR])
    month = row[I_MONTH]

    if year == 2027 and month in MONTHS_27_EARLY:
        row[I_IT_TRF] = str(IT_TRF_CTC)
        row[I_IT_NEW] = str(IT_NEW_CTC)

        ceo      = float(row[I_CEO])
        dceo     = float(row[I_DCEO])
        admin    = float(row[I_ADMIN])       # 0 for Jan–May 27
        payroll  = round(ceo + dceo + IT_TRF_CTC + IT_NEW_CTC + admin, 2)
        row[I_PAY_TOT] = str(payroll)

        infra_fee = float(row[I_INFRA_FEE])
        oneoffs   = float(row[I_ONEOFFS])
        cont      = round(0.05 * (payroll + infra_fee + oneoffs), 2)
        row[I_CONT] = str(cont)

        mgmt_tot  = round(payroll + oneoffs + cont, 2)
        row[I_MGMT_TOT] = str(mgmt_tot)

        cost_tot  = round(float(row[I_INFRA_TOT]) + mgmt_tot, 2)
        row[I_COST_TOT] = str(cost_tot)

        net       = round(float(row[I_REV_TOT]) - cost_tot, 2)
        row[I_NET] = str(net)

    # Rolling cumulative (all rows, in order)
    cumulative = round(cumulative + float(row[I_NET]), 2)
    row[I_CUM] = str(cumulative)

# ── Transpose: rows = metrics, columns = periods ─────────────────────
periods = [r[I_PERIOD] for r in rows]

METRICS = [
    ('Year',                    I_YEAR),
    ('Month',                   I_MONTH),
    ('Rev_FeeCollection',       I_REV_FEE),
    ('Rev_HR_Module',           I_REV_HR),
    ('Rev_Portrait_Module',     I_REV_POR),
    ('Rev_Total',               I_REV_TOT),
    ('Cost_Infra_ManagementFee',I_INFRA_FEE),
    ('Cost_Infra_Total',        I_INFRA_TOT),
    ('Cost_Mgmt_CEO',           I_CEO),
    ('Cost_Mgmt_DCEO',          I_DCEO),
    ('Cost_Mgmt_IT_Transfer',   I_IT_TRF),
    ('Cost_Mgmt_IT_NewHire',    I_IT_NEW),
    ('Cost_Mgmt_Admin',         I_ADMIN),
    ('Cost_Mgmt_Payroll_Total', I_PAY_TOT),
    ('Cost_Mgmt_CorporateOneoffs', I_ONEOFFS),
    ('Cost_Mgmt_Contingency',   I_CONT),
    ('Cost_Mgmt_Total',         I_MGMT_TOT),
    ('Cost_Total',              I_COST_TOT),
    ('Net_Profit_Loss',         I_NET),
    ('Cumulative_Net',          I_CUM),
]

out_rows = [['Metric'] + periods]
for label, idx in METRICS:
    out_rows.append([label] + [r[idx] for r in rows])

with open(DST, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(out_rows)

print(f"Done — {len(rows)} periods, {len(METRICS)} metrics written to {DST}")
