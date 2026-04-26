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
HEADER_BG   = colors.HexColor("#2D3B7D")
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
MARGIN    = 22 * mm
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
    FOOTER_H = 14 * mm

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

    def _t(self, x, y, text, size=10, color=DARK, bold=False, align="left"):
        self.c.setFillColor(color)
        self.c.setFont("Helvetica-Bold" if bold else "Helvetica", size)
        # Helvetica cannot render Unicode subscript ₂ — replace with ASCII 2
        safe = str(text).replace('₂', '2')
        fn = {"center": self.c.drawCentredString, "right": self.c.drawRightString}.get(align, self.c.drawString)
        fn(x, y, safe)

    def _line(self, x1, y1, x2, y2, color=CARD_BORDER, lw=0.5):
        self.c.setStrokeColor(color)
        self.c.setLineWidth(lw)
        self.c.line(x1, y1, x2, y2)

    def _ensure(self, h):
        if self.y - h < self.FOOTER_H + 12 * mm:
            self._footer()
            self.c.showPage()
            self._page += 1
            self._bg()
            self.y = H - 12 * mm

    def _section(self, title, accent=CYAN):
        self._ensure(16 * mm)
        self.y -= 5 * mm
        self._t(MARGIN, self.y, title.upper(), size=9, color=accent, bold=True)
        self.y -= 4 * mm
        self._line(MARGIN, self.y, W - MARGIN, self.y, color=accent, lw=0.8)
        self.y -= 5 * mm

    # ── Header ─────────────────────────────────────────────────────────────────
    def header(self, scenario_name, timestamp, accent):
        hh = 58 * mm
        # Gradient background matching app tealGradient: #5DBFC9 → #4A5FA8
        c1 = (0x5D / 255, 0xBF / 255, 0xC9 / 255)
        c2 = (0x2D / 255, 0x3B / 255, 0x7D / 255)
        steps = 80
        sw = W / steps
        for i in range(steps):
            t = i / max(steps - 1, 1)
            self.c.setFillColor(colors.Color(
                c1[0] + (c2[0] - c1[0]) * t,
                c1[1] + (c2[1] - c1[1]) * t,
                c1[2] + (c2[2] - c1[2]) * t,
            ))
            self.c.rect(i * sw, H - hh, sw + 1, hh, fill=1, stroke=0)
        self.c.setFillColor(accent)
        self.c.rect(0, H - hh, 5, hh, fill=1, stroke=0)
        # Decorative bubbles — semi-transparent dark circles, top-right corner
        self.c.setFillColor(colors.Color(0, 0, 0, 0.15))
        self.c.circle(W - 14 * mm, H - 6 * mm,  30 * mm, fill=1, stroke=0)
        self.c.setFillColor(colors.Color(0, 0, 0, 0.10))
        self.c.circle(W - 2 * mm,  H - 22 * mm, 20 * mm, fill=1, stroke=0)

        self._t(MARGIN, H - 14 * mm, "STEAM CRACKER SIMULATION", size=9, color=accent, bold=True)
        self._t(MARGIN, H - 25 * mm, "Simulation Report", size=22, color=colors.white, bold=True)

        bx, by = MARGIN, H - 40 * mm
        self._rr(bx, by, 130, 15, r=6,
                 fill=colors.HexColor("#0D2B4A"), stroke=colors.HexColor("#0D2B4A"))
        self._t(bx + 65, by + 4, scenario_name, size=9, color=accent, bold=True, align="center")

        # Logo — white circle backdrop so it pops against the gradient
        logo_size = 22 * mm
        logo_x = W - MARGIN - logo_size
        logo_y = H - hh + (hh - logo_size) / 2
        cx = logo_x + logo_size / 2
        cy = logo_y + logo_size / 2
        self.c.setFillColor(colors.white)
        self.c.circle(cx, cy, logo_size / 2 + 2 * mm, fill=1, stroke=0)
        logo_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logo.png")
        if os.path.exists(logo_path):
            self.c.drawImage(logo_path, logo_x, logo_y,
                             width=logo_size, height=logo_size,
                             preserveAspectRatio=True, mask="auto")

        # Timestamp + confidential — left of logo
        text_right = logo_x - 4 * mm
        self._t(text_right, H - 19 * mm, timestamp, size=9, color=LIGHT, align="right")
        self._t(text_right, H - 28 * mm, "Confidential", size=9, color=LIGHT, align="right")
        self.y = H - hh - 6 * mm

    # ── Inputs card ────────────────────────────────────────────────────────────
    def inputs(self, scenario, temperature, pressure, scenario_id):
        ch = 28 * mm
        self._ensure(ch + 3 * mm)
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
            self._t(cx, self.y - 8 * mm,  label, size=9, color=LIGHT, align="center")
            self._t(cx, self.y - 18 * mm, value, size=12, color=DARK, bold=True, align="center")
            if i < 3:
                self._line(MARGIN + (i + 1) * col_w, self.y - 5 * mm,
                           MARGIN + (i + 1) * col_w, self.y - 25 * mm)
        self.y -= ch + 3 * mm

    # ── KPI cards ──────────────────────────────────────────────────────────────
    def kpi_cards(self, ethylene, hydrogen, co2e, accent):
        ch, gap = 26 * mm, 4 * mm
        cw = (CONTENT_W - 2 * gap) / 3
        self._ensure(ch + 3 * mm)
        kpis = [
            ("Ethylene Production", f"{ethylene:.1f}", "kg / hr", accent),
            ("Hydrogen Production", f"{hydrogen:.1f}", "kg / hr", PURPLE),
            ("CO₂ Emissions",  f"{co2e:.1f}",    "kg / hr", ORANGE),
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
            # Label centred in top third
            self._t(mx, y + ch - 8 * mm, label, size=9, color=MED, align="center")
            self._t(mx, y + 7 * mm, value, size=16, color=color, bold=True, align="center")
            self._t(mx, y + 2.5 * mm, unit, size=8, color=LIGHT, align="center")
        self.y -= ch + 3 * mm

    # ── Performance rows ───────────────────────────────────────────────────────
    def performance_rows(self, results, performance):
        metrics = [
            ("Ethylene Yield",    results.get("ethyleneYield"),    "%", "ethylene_yield"),
            ("Furnace Reduction", results.get("furnaceReduction"),  "%", "furnace_reduction"),
            ("Cost Saving",       results.get("costSaving"),        "%", "cost_saving"),
            ("Hydrogen Purity",   results.get("hydrogenPurity"),    "%", "hydrogen_purity"),
        ]
        metrics = [(l, v, u, k) for l, v, u, k in metrics if v is not None]
        if not metrics:
            return

        row_h   = 22 * mm
        ch      = len(metrics) * row_h + 6 * mm
        self._ensure(ch + 4 * mm)
        self._card(MARGIN, self.y - ch, CONTENT_W, ch)

        pad     = 5 * mm
        badge_w = 125        # wide enough for "Excellent Performance"
        val_w   = 28 * mm
        right_x = W - MARGIN - pad
        badge_x = right_x - badge_w
        val_x   = badge_x - val_w - 3 * mm

        def _wrap_line(text, max_chars):
            """Split text into at most 2 lines at word boundaries."""
            if len(text) <= max_chars:
                return [text]
            cut = text[:max_chars].rsplit(' ', 1)[0]
            rest = text[len(cut):].strip()
            lines = [cut]
            if rest:
                lines.append(rest[:max_chars].rsplit(' ', 1)[0] if len(rest) > max_chars else rest)
            return lines

        max_exp_chars = 60   # chars per explanation line

        for i, (label, value, unit, perf_key) in enumerate(metrics):
            ry = self.y - pad - i * row_h - row_h / 2
            perf = performance.get(perf_key, {})
            status      = perf.get("status", "")
            explanation = perf.get("explanation", "")
            sc, sc_bg   = _status_color(status)

            # Alternating row background
            if i % 2 == 0:
                self.c.setFillColor(colors.HexColor("#F5F9FF"))
                self.c.rect(MARGIN + 1, ry - row_h / 2 + 1, CONTENT_W - 2, row_h - 2, fill=1, stroke=0)

            # Left: label + full explanation wrapped to 2 lines
            exp_lines = _wrap_line(explanation, max_exp_chars)
            self._t(MARGIN + pad, ry + 6,  label, size=11, color=DARK, bold=True)
            for j, line in enumerate(exp_lines):
                self._t(MARGIN + pad, ry - 2 - j * 5.5, line, size=8, color=LIGHT)

            # Middle-right: percentage value (vertically centred)
            val_str = f"{_safe_float(value):.1f}{unit}"
            self._t(val_x, ry + 2, val_str, size=13, color=DARK, bold=True, align="right")

            # Far right: status badge (vertically centred)
            self._rr(badge_x, ry - 8, badge_w, 16, r=8, fill=sc_bg, stroke=sc, lw=0.5)
            self._t(badge_x + badge_w / 2, ry - 1, status, size=8.5, color=sc, bold=True, align="center")

        self.y -= ch + 5 * mm

    # ── CO2 Storage / PETE section ─────────────────────────────────────────────
    def pete_section(self, results, accent):
        feasibility = results.get("feasibility", "N/A")
        feas_msg    = results.get("feasibilityMessage", "")
        fc, fc_bg   = _status_color(feasibility)

        # Feasibility banner
        ban_h = 26 * mm
        self._ensure(ban_h + 5 * mm)
        self._card(MARGIN, self.y - ban_h, CONTENT_W, ban_h)
        # Left accent bar
        self.c.setFillColor(fc)
        self.c.roundRect(MARGIN, self.y - ban_h, 4, ban_h, 2, fill=1, stroke=0)
        # Badge
        badge_x = MARGIN + 8 * mm
        badge_w = 72
        self._rr(badge_x, self.y - ban_h / 2 - 7, badge_w, 16, r=8, fill=fc_bg, stroke=fc, lw=0.6)
        self._t(badge_x + badge_w / 2, self.y - ban_h / 2 - 1, feasibility, size=10, color=fc, bold=True, align="center")
        # Title + message to the right of the badge
        text_x = badge_x + badge_w + 8 * mm
        self._t(text_x, self.y - 9 * mm, "CO₂ Storage Feasibility", size=11, color=DARK, bold=True)
        if feas_msg:
            self._t(text_x, self.y - 18 * mm, feas_msg[:85], size=9, color=MED)
        self.y -= ban_h + 5 * mm

        # 4 PETE metrics in 2×2 grid
        pete_metrics = [
            ("Max Safe Injection Time", _safe_float(results.get("maxInjectionTime")),    "years"),
            ("Pressure at Project End",  _safe_float(results.get("pressureAtEnd")),       "MPa"),
            ("Max Sustainable Rate",     _safe_float(results.get("maxSustainableRate")),   "kg/hr"),
            ("Plume Radius",             _safe_float(results.get("plumeRadius")),          "m"),
        ]
        gap  = 4 * mm
        cw   = (CONTENT_W - gap) / 2
        ch   = 26 * mm
        colors_list = [accent, PURPLE, CYAN, colors.HexColor("#2ECC71")]

        for i, (label, value, unit) in enumerate(pete_metrics):
            col = i % 2
            if col == 0:
                self._ensure(ch + gap)
            x = MARGIN + col * (cw + gap)
            y = self.y - ch
            color = colors_list[i]
            self.c.setFillColor(SHADOW_C)
            self.c.roundRect(x + 2, y - 3, cw, ch, 8, fill=1, stroke=0)
            self._rr(x, y, cw, ch, r=8, stroke=color, lw=0.8)
            mx = x + cw / 2
            self._t(mx, y + ch - 9 * mm, label, size=9, color=MED, align="center")
            self._t(mx, y + 8 * mm, f"{value:.1f}", size=17, color=color, bold=True, align="center")
            self._t(mx, y + 2.5 * mm, unit, size=9, color=LIGHT, align="center")
            if col == 1 or i == len(pete_metrics) - 1:
                self.y -= ch + gap

    # ── PETE Charts ────────────────────────────────────────────────────────────
    def _draw_chart(self, x, y, w, h, series, limit_val,
                    series_color, limit_color,
                    series_label, limit_label,
                    title, x_label, y_start_zero=False):
        """Draw a single line chart: one data curve + one horizontal limit line."""
        self._rr(x, y, w, h, r=6)
        self._t(x + w / 2, y + h - 4.5 * mm, title, size=7.5, color=DARK, bold=True, align="center")

        if not series:
            self._t(x + w / 2, y + h / 2, "No data available", size=8, color=LIGHT, align="center")
            return

        lm, bm, tm, rm = 14 * mm, 10 * mm, 7 * mm, 4 * mm
        cx, cy = x + lm, y + bm
        cw, ch = w - lm - rm, h - bm - tm

        x_vals = [p[0] for p in series]
        y_vals = [p[1] for p in series]
        x_min  = 0.0                        # always start at time = 0
        x_max  = max(x_vals)
        y_data_min = 0.0 if y_start_zero else min(y_vals)
        y_data_max = max(y_vals)
        y_min = min(y_data_min, limit_val) * (0.985 if not y_start_zero else 1.0)
        y_max = max(y_data_max, limit_val) * 1.02
        x_rng = max(x_max - x_min, 1e-9)
        y_rng = max(y_max - y_min, 1e-9)

        def px(v): return cx + (v - x_min) / x_rng * cw
        def py(v): return cy + (v - y_min) / y_rng * ch

        # Smart x-axis format — avoids "0 0 1 1" for short durations
        def fmt_x(v):
            if x_rng >= 10: return f"{v:.0f}"
            if x_rng >= 1:  return f"{v:.1f}"
            return f"{v:.2f}"

        # Grid lines + tick labels
        for i in range(5):
            yv = y_min + i * y_rng / 4
            yl = py(yv)
            self._line(cx, yl, cx + cw, yl, color=CARD_BORDER, lw=0.3)
            self._t(cx - 1, yl - 2, f"{yv:.1f}", size=5.5, color=LIGHT, align="right")

            xv = x_min + i * x_rng / 4
            xl = px(xv)
            self._line(xl, cy, xl, cy + ch, color=CARD_BORDER, lw=0.3)
            self._t(xl, cy - 4.5 * mm, fmt_x(xv), size=5.5, color=LIGHT, align="center")

        # Axis label
        self._t(cx + cw / 2, y + 1.5, x_label, size=6, color=MED, align="center")

        # Axes
        self._line(cx, cy, cx + cw, cy, color=MED, lw=0.6)
        self._line(cx, cy, cx, cy + ch, color=MED, lw=0.6)

        # Data series (solid curve) — use path object API
        self.c.setStrokeColor(series_color)
        self.c.setLineWidth(1.2)
        path = self.c.beginPath()
        path.moveTo(px(series[0][0]), py(series[0][1]))
        for p in series[1:]:
            path.lineTo(px(p[0]), py(p[1]))
        self.c.drawPath(path, stroke=1, fill=0)

        # Limit line (horizontal dashed)
        lim_y = py(limit_val)
        if cy - 1 <= lim_y <= cy + ch + 1:
            self.c.setStrokeColor(limit_color)
            self.c.setLineWidth(0.9)
            self.c.setDash([4, 3], 0)
            self.c.line(cx, lim_y, cx + cw, lim_y)
            self.c.setDash([], 0)

        # Legend (top-left inside chart area)
        lx, ly = cx + 2 * mm, cy + ch - 4 * mm
        self.c.setStrokeColor(series_color)
        self.c.setLineWidth(1.2)
        self.c.line(lx, ly, lx + 7, ly)
        self._t(lx + 9, ly - 2, series_label, size=5.5, color=MED)

        self.c.setStrokeColor(limit_color)
        self.c.setLineWidth(0.9)
        self.c.setDash([4, 3], 0)
        self.c.line(lx, ly - 4 * mm, lx + 7, ly - 4 * mm)
        self.c.setDash([], 0)
        self._t(lx + 9, ly - 4 * mm - 2, limit_label, size=5.5, color=limit_color)

    def pete_charts(self, pressure_series, plume_series,
                    allowable_p, reservoir_radius, accent):
        gap = 4 * mm
        cw  = (CONTENT_W - gap) / 2
        ch  = 60 * mm
        # Space already reserved by the top-level ensure in generate_pdf
        y_top = self.y - ch

        self._draw_chart(
            MARGIN, y_top, cw, ch,
            series=pressure_series, limit_val=allowable_p,
            series_color=accent, limit_color=RED,
            series_label="Pressure (MPa)", limit_label="Allowable P (MPa)",
            title="Pressure vs Time", x_label="Time (years)",
            y_start_zero=False,
        )
        self._draw_chart(
            MARGIN + cw + gap, y_top, cw, ch,
            series=plume_series, limit_val=reservoir_radius,
            series_color=CYAN, limit_color=RED,
            series_label="Plume radius (m)", limit_label="Reservoir radius (m)",
            title="Plume Radius vs Time", x_label="Time (years)",
            y_start_zero=True,
        )
        self.y -= ch + 6 * mm

    # ── Recommendation ─────────────────────────────────────────────────────────
    def recommendation(self, text, accent):
        if not text:
            return
        words = text.split()
        chars = 85
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

        lh = 5 * mm
        ch = 14 * mm + len(lines) * lh
        # Space already reserved by pete_charts ensure — no separate page break needed
        self._card(MARGIN, self.y - ch, CONTENT_W, ch)
        self.c.setFillColor(accent)
        self.c.rect(MARGIN, self.y - ch, 4, ch, fill=1, stroke=0)
        self._t(MARGIN + 7 * mm, self.y - 9 * mm,
                "OPTIMIZATION RECOMMENDATION", size=9, color=accent, bold=True)
        for j, line in enumerate(lines):
            self._t(MARGIN + 7 * mm, self.y - 14 * mm - j * lh, line, size=10, color=MED)
        self.y -= ch + 4 * mm

    # ── Footer ─────────────────────────────────────────────────────────────────
    def _footer(self):
        self.c.setFillColor(HEADER_BG)
        self.c.rect(0, 0, W, self.FOOTER_H, fill=1, stroke=0)
        self._t(MARGIN, 4.5 * mm, "Steam Cracker Optimization Platform", size=8, color=LIGHT)
        self._t(W / 2, 4.5 * mm, "Generated by Steam Cracker AI Engine", size=8, color=LIGHT, align="center")
        self._t(W - MARGIN, 4.5 * mm, f"Page {self._page}", size=8, color=LIGHT, align="right")

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
    reservoir     = payload.get("reservoir",     {})
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
        # Force a page break upfront so CO2 feasibility + charts + recommendation
        # all land on one page together — no mid-block splits
        rc._ensure(248 * mm)
        rc._section("CO2 Storage Assessment (PETE)", accent)
        rc.pete_section(results, accent)

        pressure_series  = reservoir.get("pressure_series",  [])
        plume_series     = reservoir.get("plume_series",     [])
        allowable_p      = _safe_float(reservoir.get("allowable_pressure_mpa", 0))
        reservoir_radius = _safe_float(reservoir.get("reservoir_radius_m",     0))

        if pressure_series and plume_series:
            rc._section("Reservoir Charts", accent)
            rc.pete_charts(pressure_series, plume_series,
                           allowable_p, reservoir_radius, accent)

        rc._section("Recommendation", accent)
        rc.recommendation(results.get("iseRecommendation", ""), accent)
    else:
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

        pdf_buf   = generate_pdf(payload)
        scenario  = payload.get("scenario", "report").replace(" ", "_")
        ts        = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        file_key  = f"reports/{scenario}_{ts}_{uuid.uuid4().hex[:8]}.pdf"

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
