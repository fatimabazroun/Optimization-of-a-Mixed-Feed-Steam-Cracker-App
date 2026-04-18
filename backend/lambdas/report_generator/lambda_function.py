"""
steam-cracker-report-generator
Generates a PDF from actual simulation results only — no fabricated values.
Security: credentials via execution role, config via environment variables only.
"""

import io
import json
import os
import uuid
from datetime import datetime, timezone

import boto3
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas as pdf_canvas

BUCKET = os.environ["REPORT_BUCKET"]
EXPIRY = int(os.environ.get("PRESIGNED_URL_EXPIRY_SECONDS", "3600"))

s3 = boto3.client("s3")

# ── Palette ────────────────────────────────────────────────────────────────────
BG_PAGE     = colors.HexColor("#F2F7FD")
HEADER_BG   = colors.HexColor("#0D1B2A")
CARD_BG     = colors.white
CARD_BORDER = colors.HexColor("#CCDFF0")
SHADOW_C    = colors.HexColor("#BDD4EC")
CYAN        = colors.HexColor("#00BCD4")
PURPLE      = colors.HexColor("#7B61FF")
DARK        = colors.HexColor("#0D1B2A")
MED         = colors.HexColor("#546E7A")
LIGHT       = colors.HexColor("#90A4AE")
GREEN       = colors.HexColor("#2ECC71")
GREEN_BG    = colors.HexColor("#D5F5E3")
ORANGE      = colors.HexColor("#FF9800")
ORANGE_BG   = colors.HexColor("#FFF3E0")
RED         = colors.HexColor("#E74C3C")
RED_BG      = colors.HexColor("#FDECEA")

W, H      = A4
MARGIN    = 20 * mm
CONTENT_W = W - 2 * MARGIN


def _status_color(status: str):
    s = status.lower()
    if any(w in s for w in ["optimal", "excellent", "good", "above", "feasible"]):
        return GREEN, GREEN_BG
    if any(w in s for w in ["moderate", "minor", "needs", "initial", "conditional", "warning"]):
        return ORANGE, ORANGE_BG
    return RED, RED_BG


def _accent_for_scenario(scenario_id: str):
    return {"S1": CYAN, "S2": PURPLE, "S3": colors.HexColor("#26A69A")}.get(scenario_id, CYAN)


def _safe_float(val, default=0.0) -> float:
    try:
        return float(val)
    except (TypeError, ValueError):
        return default


# ── Canvas wrapper ─────────────────────────────────────────────────────────────

class RC:
    FOOTER_H = 12 * mm

    def __init__(self, buf):
        self.c     = pdf_canvas.Canvas(buf, pagesize=A4)
        self.y     = H
        self._page = 1
        self._bg()

    def _bg(self):
        self.c.setFillColor(BG_PAGE)
        self.c.rect(0, 0, W, H, fill=1, stroke=0)

    def _rr(self, x, y, w, h, r=8, fill=CARD_BG, stroke=CARD_BORDER, lw=0.7):
        self.c.setFillColor(fill)
        self.c.setStrokeColor(stroke)
        self.c.setLineWidth(lw)
        self.c.roundRect(x, y, w, h, r, fill=1, stroke=1)

    def _card(self, x, y, w, h, r=8):
        self.c.setFillColor(SHADOW_C)
        self.c.roundRect(x + 2, y - 3, w, h, r, fill=1, stroke=0)
        self._rr(x, y, w, h, r)

    def _t(self, x, y, text, size=9, color=DARK, bold=False, align="left"):
        self.c.setFillColor(color)
        self.c.setFont("Helvetica-Bold" if bold else "Helvetica", size)
        fn = {"center": self.c.drawCentredString, "right": self.c.drawRightString}.get(align, self.c.drawString)
        fn(x, y, str(text))

    def _line(self, x1, y1, x2, y2, color=CARD_BORDER, lw=0.5):
        self.c.setStrokeColor(color)
        self.c.setLineWidth(lw)
        self.c.line(x1, y1, x2, y2)

    def _ensure(self, h):
        if self.y - h < self.FOOTER_H + 10 * mm:
            self._footer()
            self.c.showPage()
            self._page += 1
            self._bg()
            self.y = H - 10 * mm

    def _section(self, title, accent=CYAN):
        self._ensure(20 * mm)
        self.y -= 6 * mm
        self._t(MARGIN, self.y, title.upper(), size=7, color=accent, bold=True)
        self.y -= 4 * mm
        self._line(MARGIN, self.y, W - MARGIN, self.y, color=accent, lw=0.8)
        self.y -= 5 * mm

    # ── Header ─────────────────────────────────────────────────────────────────
    def header(self, scenario_name, timestamp, accent):
        hh = 55 * mm
        self.c.setFillColor(HEADER_BG)
        self.c.rect(0, H - hh, W, hh, fill=1, stroke=0)
        self.c.setFillColor(accent)
        self.c.rect(0, H - hh, 4, hh, fill=1, stroke=0)
        self.c.setFillColor(colors.HexColor("#1E3A5F"))
        self.c.circle(W - 18 * mm, H - 8 * mm, 28 * mm, fill=1, stroke=0)

        self._t(MARGIN, H - 13 * mm, "STEAM CRACKER", size=7, color=accent, bold=True)
        self._t(MARGIN, H - 22 * mm, "Simulation Report", size=19, color=colors.white, bold=True)

        bx, by = MARGIN, H - 36 * mm
        self._rr(bx, by, 115, 13, r=6,
                 fill=colors.HexColor("#1E3A5F"), stroke=colors.HexColor("#1E3A5F"))
        self._t(bx + 57, by + 3, scenario_name, size=7, color=accent, bold=True, align="center")

        self._t(W - MARGIN, H - 18 * mm, timestamp, size=7, color=LIGHT, align="right")
        self._t(W - MARGIN, H - 25 * mm, "Confidential", size=7, color=LIGHT, align="right")
        self.y = H - hh - 5 * mm

    # ── Inputs card ────────────────────────────────────────────────────────────
    def inputs(self, scenario, temperature, pressure, scenario_id):
        ch = 28 * mm
        self._ensure(ch + 5 * mm)
        self._card(MARGIN, self.y - ch, CONTENT_W, ch)
        col_w = CONTENT_W / 4
        items = [
            ("Scenario",    scenario),
            ("Temperature", f"{temperature} °C"),
            ("Pressure",    f"{pressure} bar"),
            ("Scenario ID", scenario_id),
        ]
        for i, (label, value) in enumerate(items):
            cx = MARGIN + i * col_w + col_w / 2
            self._t(cx, self.y - 8 * mm,  label, size=7, color=LIGHT, align="center")
            self._t(cx, self.y - 17 * mm, value, size=10, color=DARK, bold=True, align="center")
            if i < 3:
                self._line(MARGIN + (i + 1) * col_w, self.y - 6 * mm,
                           MARGIN + (i + 1) * col_w, self.y - 24 * mm)
        self.y -= ch + 5 * mm

    # ── KPI cards (ethylene / hydrogen / co2e) ─────────────────────────────────
    def kpi_cards(self, ethylene, hydrogen, co2e, accent):
        ch, gap = 26 * mm, 4 * mm
        cw = (CONTENT_W - 2 * gap) / 3
        self._ensure(ch + 5 * mm)
        kpis = [
            ("Ethylene Production", f"{ethylene:.1f}", "kg / hr", accent),
            ("Hydrogen Production", f"{hydrogen:.1f}", "kg / hr", PURPLE),
            ("CO\u2082 Emissions",  f"{co2e:.1f}",    "kg / hr", ORANGE),
        ]
        for i, (label, value, unit, color) in enumerate(kpis):
            x = MARGIN + i * (cw + gap)
            y = self.y - ch
            self.c.setFillColor(SHADOW_C)
            self.c.roundRect(x + 2, y - 3, cw, ch, 8, fill=1, stroke=0)
            self._rr(x, y, cw, ch, r=8, stroke=color, lw=0.8)
            self.c.setFillColor(color)
            self.c.roundRect(x, y + ch - 3, cw, 3, 2, fill=1, stroke=0)
            mx = x + cw / 2
            self._t(mx, y + ch - 9 * mm, label, size=7, color=MED, align="center")
            self._t(mx, y + 8 * mm, value, size=16, color=color, bold=True, align="center")
            self._t(mx, y + 3 * mm, unit, size=7, color=LIGHT, align="center")
        self.y -= ch + 5 * mm

    # ── Performance rows (only real fields) ────────────────────────────────────
    def performance_rows(self, results, performance):
        metrics = [
            ("Ethylene Yield",   results.get("ethyleneYield"),   "%",  "ethylene_yield"),
            ("Furnace Reduction",results.get("furnaceReduction"), "%",  "furnace_reduction"),
            ("Cost Saving",      results.get("costSaving"),       "%",  "cost_saving"),
            ("Hydrogen Purity",  results.get("hydrogenPurity"),   "%",  "hydrogen_purity"),
        ]
        # filter out None values
        metrics = [(l, v, u, k) for l, v, u, k in metrics if v is not None]
        if not metrics:
            return

        row_h = 14 * mm
        ch    = len(metrics) * row_h + 6 * mm
        self._ensure(ch + 5 * mm)
        self._card(MARGIN, self.y - ch, CONTENT_W, ch)

        pad = 5 * mm
        for i, (label, value, unit, perf_key) in enumerate(metrics):
            ry = self.y - pad - i * row_h - row_h / 2
            perf = performance.get(perf_key, {})
            status = perf.get("status", "")
            explanation = perf.get("explanation", "")
            sc, sc_bg = _status_color(status)

            # Alternating row bg
            if i % 2 == 0:
                self.c.setFillColor(colors.HexColor("#F5F9FF"))
                self.c.rect(MARGIN + 1, ry - row_h / 2 + 1, CONTENT_W - 2, row_h - 2, fill=1, stroke=0)

            self._t(MARGIN + pad, ry + 2, label, size=9, color=DARK, bold=True)
            self._t(MARGIN + pad, ry - 5, explanation, size=7, color=LIGHT)

            # Status badge
            badge_w = 70
            bx = W - MARGIN - pad - badge_w
            self._rr(bx, ry - 5, badge_w, 12, r=6, fill=sc_bg, stroke=sc, lw=0.5)
            self._t(bx + badge_w / 2, ry - 1, status, size=7, color=sc, bold=True, align="center")

            # Value
            val_str = f"{_safe_float(value):.1f}{unit}"
            self._t(bx - 6, ry + 2, val_str, size=11, color=DARK, bold=True, align="right")

        self.y -= ch + 5 * mm

    # ── CO2 Storage / PETE section ─────────────────────────────────────────────
    def pete_section(self, results, accent):
        feasibility = results.get("feasibility", "N/A")
        feas_msg    = results.get("feasibilityMessage", "")
        fc, fc_bg   = _status_color(feasibility)

        # Feasibility banner
        ban_h = 22 * mm
        self._ensure(ban_h + 5 * mm)
        self._card(MARGIN, self.y - ban_h, CONTENT_W, ban_h)
        self.c.setFillColor(fc)
        self.c.roundRect(MARGIN, self.y - ban_h, 4, ban_h, 2, fill=1, stroke=0)
        self._rr(MARGIN + 8 * mm, self.y - ban_h / 2 - 4, 60, 14, r=7, fill=fc_bg, stroke=fc, lw=0.6)
        self._t(MARGIN + 38 * mm, self.y - ban_h / 2 + 1, feasibility, size=8, color=fc, bold=True, align="center")
        self._t(MARGIN + 14 * mm, self.y - 8 * mm, "CO\u2082 Storage Feasibility", size=8, color=DARK, bold=True)
        if feas_msg:
            self._t(MARGIN + 14 * mm, self.y - 16 * mm, feas_msg[:80], size=7, color=MED)
        self.y -= ban_h + 4 * mm

        # 4 PETE metrics in 2×2 grid
        pete_metrics = [
            ("Max Safe Injection Time", _safe_float(results.get("maxInjectionTime")), "years"),
            ("Pressure at Project End",  _safe_float(results.get("pressureAtEnd")),   "MPa"),
            ("Max Sustainable Rate",     _safe_float(results.get("maxSustainableRate")), "kg/hr"),
            ("Plume Radius",             _safe_float(results.get("plumeRadius")),      "m"),
        ]
        gap   = 4 * mm
        cw    = (CONTENT_W - gap) / 2
        ch    = 22 * mm
        colors_list = [accent, PURPLE, CYAN, colors.HexColor("#2ECC71")]

        for i, (label, value, unit) in enumerate(pete_metrics):
            col = i % 2
            row = i // 2
            if col == 0:
                self._ensure(ch + gap)
            x = MARGIN + col * (cw + gap)
            y = self.y - ch
            color = colors_list[i]
            self.c.setFillColor(SHADOW_C)
            self.c.roundRect(x + 2, y - 3, cw, ch, 8, fill=1, stroke=0)
            self._rr(x, y, cw, ch, r=8, stroke=color, lw=0.8)
            mx = x + cw / 2
            self._t(mx, y + ch - 8 * mm, label, size=7, color=MED, align="center")
            self._t(mx, y + 7 * mm, f"{value:.1f}", size=15, color=color, bold=True, align="center")
            self._t(mx, y + 2 * mm, unit, size=7, color=LIGHT, align="center")
            if col == 1 or i == len(pete_metrics) - 1:
                self.y -= ch + gap

    # ── Recommendation ─────────────────────────────────────────────────────────
    def recommendation(self, text, accent):
        if not text:
            return
        words = text.split()
        chars = 90
        lines, cur = [], ""
        for w in words:
            test = f"{cur} {w}".strip()
            if len(test) <= chars:
                cur = test
            else:
                lines.append(cur)
                cur = w
        if cur:
            lines.append(cur)

        lh = 4.5 * mm
        ch = 13 * mm + len(lines) * lh
        self._ensure(ch + 4 * mm)
        self._card(MARGIN, self.y - ch, CONTENT_W, ch)
        self.c.setFillColor(accent)
        self.c.rect(MARGIN, self.y - ch, 3, ch, fill=1, stroke=0)
        self._t(MARGIN + 6 * mm, self.y - 8 * mm,
                "OPTIMIZATION RECOMMENDATION", size=7, color=accent, bold=True)
        for j, line in enumerate(lines):
            self._t(MARGIN + 6 * mm, self.y - 13 * mm - j * lh, line, size=8, color=MED)
        self.y -= ch + 4 * mm

    # ── Footer ─────────────────────────────────────────────────────────────────
    def _footer(self):
        self.c.setFillColor(HEADER_BG)
        self.c.rect(0, 0, W, self.FOOTER_H, fill=1, stroke=0)
        self._t(MARGIN, 4 * mm, "Steam Cracker Optimization Platform", size=7, color=LIGHT)
        self._t(W / 2, 4 * mm, "Generated by Steam Cracker AI Engine", size=7, color=LIGHT, align="center")
        self._t(W - MARGIN, 4 * mm, f"Page {self._page}", size=7, color=LIGHT, align="right")

    def save(self):
        self._footer()
        self.c.save()


# ── PDF entry ──────────────────────────────────────────────────────────────────

def generate_pdf(payload: dict) -> io.BytesIO:
    scenario      = payload.get("scenario",      "Unknown")
    temperature   = payload.get("temperature",   "—")
    pressure      = payload.get("pressure",      "—")
    scenario_id   = payload.get("scenarioId",    "S1")
    use_reservoir = payload.get("use_reservoir", False)
    results       = payload.get("results",       {})
    performance   = results.get("performance",   {})
    timestamp     = datetime.now(timezone.utc).strftime("%Y-%m-%d  %H:%M UTC")
    accent        = _accent_for_scenario(scenario_id)

    buf = io.BytesIO()
    rc  = RC(buf)

    rc.header(scenario, timestamp, accent)

    rc._section("Simulation Inputs", accent)
    rc.inputs(scenario, temperature, pressure, scenario_id)

    rc._section("Calculated KPIs", accent)
    rc.kpi_cards(
        ethylene = _safe_float(results.get("ethyleneKgHr")),
        hydrogen = _safe_float(results.get("hydrogenKgHr")),
        co2e     = _safe_float(results.get("co2eKgHr")),
        accent   = accent,
    )

    rc._section("Cracking Performance", accent)
    rc.performance_rows(results, performance)

    if use_reservoir:
        rc._section("CO\u2082 Storage Assessment (PETE)", accent)
        rc.pete_section(results, accent)

    rc._section("Recommendation", accent)
    rc.recommendation(results.get("iseRecommendation", ""), accent)

    rc.save()
    buf.seek(0)
    return buf


# ── Lambda handler ─────────────────────────────────────────────────────────────

def lambda_handler(event, context):
    try:
        body    = event.get("body", "{}")
        payload = json.loads(body) if isinstance(body, str) else (body or {})

        pdf_buf  = generate_pdf(payload)
        file_key = f"reports/{uuid.uuid4()}.pdf"

        s3.put_object(
            Bucket      = BUCKET,
            Key         = file_key,
            Body        = pdf_buf.read(),
            ContentType = "application/pdf",
        )

        url = s3.generate_presigned_url(
            "get_object",
            Params    = {"Bucket": BUCKET, "Key": file_key},
            ExpiresIn = EXPIRY,
        )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type":                "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"url": url}),
        }

    except Exception as exc:
        return {
            "statusCode": 500,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": str(exc)}),
        }
