import json
import math

EULER_GAMMA = 0.5772156649


def compute_allowable_pressure(inputs):
    safety_margin = inputs.get("safety_margin", 1.5)
    fracture_pressure = inputs.get("fracture_pressure")
    fracture_gradient = inputs.get("fracture_gradient")
    depth = inputs.get("depth")

    if fracture_pressure is not None:
        p_frac = fracture_pressure
    elif fracture_gradient is not None and depth is not None:
        p_frac = fracture_gradient * depth
    else:
        raise ValueError("Provide either fracture_pressure or both fracture_gradient and depth.")

    return p_frac - safety_margin, p_frac


def _delta_p_open_pa(t_s, k_m2, h_m, phi, mu_pa_s, ct_pa, rw_m, skin, q_m3_s):
    """
    Open-reservoir transient pressure buildup in Pa.

    ΔP = (q·μ)/(4πkh) · [ln(4kt / (φ·μ·c_t·r_w²)) − γ + s]

    All inputs in SI units (m², Pa·s, 1/Pa, m, m³/s, s).
    """
    arg = (4.0 * k_m2 * t_s) / max(phi * mu_pa_s * ct_pa * rw_m ** 2, 1e-40)
    arg = max(arg, 1.000001)
    return (q_m3_s * mu_pa_s) / (4.0 * math.pi * k_m2 * h_m) * (math.log(arg) - EULER_GAMMA + skin)


def pressure_at_time_mpa(t_hr, inputs, q_per_well_vol_m3_hr):
    """
    Well-face pressure at time t_hr for one injection well.

    Converts all field-unit inputs to SI, applies the Ei-function
    transient radial-flow equation, and applies the closed-boundary
    multiplier α when reservoir_type == 'Closed'.

    Returns pressure in MPa.
    """
    # --- unit conversions to SI ---
    mu_pa_s  = inputs.get("co2_viscosity", 0.05) * 1e-3        # cP   → Pa·s
    k_m2     = inputs["permeability"] * 9.869233e-16             # mD   → m²
    h_m      = inputs["thickness"]                               # m
    phi      = max(inputs["porosity"], 1e-9)                     # fraction
    ct_pa    = inputs.get("compressibility", 1e-4) / 1e6         # 1/MPa → 1/Pa
    rw_m     = inputs.get("well_radius", 0.1)                   # m
    p_i_mpa  = inputs["initial_pressure"]                        # MPa
    skin     = inputs.get("skin", 0.0)

    t0_s  = inputs.get("log_start_time", 1.0) * 24 * 3600       # days → s
    t_s   = max(t_hr * 3600.0, t0_s)                            # floor at t0
    q_m3s = q_per_well_vol_m3_hr / 3600.0                      # m³/hr → m³/s

    dp_pa = _delta_p_open_pa(t_s, k_m2, h_m, phi, mu_pa_s, ct_pa, rw_m, skin, q_m3s)
    dp_mpa = dp_pa / 1e6

    # Apply closed-boundary multiplier α (PDF §8: ΔP_closed = α·ΔP_open)
    if inputs.get("reservoir_type", "Open").strip().lower() == "closed":
        alpha = inputs.get("closed_multiplier", 3.0)
        dp_mpa *= alpha

    return p_i_mpa + dp_mpa


def find_max_safe_injection_time_years(inputs, q_per_well_vol_m3_hr, p_allow_mpa):
    """
    Analytical safe-time from PDF §11:

        P_allow = P_i + α·A·[ln(B·t_safe) − γ + s]
        t_safe  = exp((P_allow − P_i) / (α·A) + γ − s) / B
    """
    mu_pa_s = inputs.get("co2_viscosity", 0.05) * 1e-3
    k_m2    = inputs["permeability"] * 9.869233e-16
    h_m     = inputs["thickness"]
    phi     = max(inputs["porosity"], 1e-9)
    ct_pa   = inputs.get("compressibility", 1e-4) / 1e6
    rw_m    = inputs.get("well_radius", 0.1)
    skin    = inputs.get("skin", 0.0)
    q_m3s   = q_per_well_vol_m3_hr / 3600.0

    A = (q_m3s * mu_pa_s) / (4.0 * math.pi * k_m2 * h_m)
    B = (4.0 * k_m2) / max(phi * mu_pa_s * ct_pa * rw_m ** 2, 1e-40)

    alpha = 1.0
    if inputs.get("reservoir_type", "Open").strip().lower() == "closed":
        alpha = inputs.get("closed_multiplier", 3.0)

    dp_pa = (p_allow_mpa - inputs["initial_pressure"]) * 1e6
    if dp_pa <= 0 or A <= 0:
        return 0.0

    log_arg = dp_pa / (alpha * A) + EULER_GAMMA - skin
    if log_arg > 700:           # exp would overflow → effectively >100 yr
        return 100.0

    t0_s     = inputs.get("log_start_time", 1.0) * 24 * 3600
    t_safe_s = max(math.exp(log_arg) / B, t0_s)
    t_safe_yr = t_safe_s / (365 * 24 * 3600)

    return round(min(t_safe_yr, 100.0), 2)


def compute_max_sustainable_rate_kg_hr(inputs, q_total_kg_hr, p_allow_mpa):
    """Binary-search for the largest total rate that stays below p_allow at project end."""
    target_t_hr = inputs["project_duration"] * 365 * 24
    n_wells = inputs["n_wells"]
    rho = inputs.get("co2_density", 700)

    low, high, best = 0.0, max(q_total_kg_hr * 10, 1.0), 0.0
    for _ in range(60):
        mid = (low + high) / 2.0
        q_per_well = (mid / n_wells) / rho
        if pressure_at_time_mpa(target_t_hr, inputs, q_per_well) <= p_allow_mpa:
            best = mid
            low = mid
        else:
            high = mid
    return round(best, 2)


def _plume_radius_at_t(t_hr, inputs, q_per_well_vol_m3_hr):
    phi   = max(inputs["porosity"], 1e-9)
    h_m   = max(inputs["thickness"], 1e-9)
    s_co2 = max(inputs.get("co2_saturation", 0.2), 1e-9)
    vol_per_well = q_per_well_vol_m3_hr * t_hr
    return round(math.sqrt(vol_per_well / (math.pi * phi * h_m * s_co2)), 2)


def compute_plume_radius_m(inputs, q_per_well_vol_m3_hr):
    """
    Volumetric plume-radius estimate per well (PDF §12.3).

    r_p = sqrt(q_well · T_proj / (π · φ · h · S_CO2))
    """
    duration_hr = inputs["project_duration"] * 365 * 24
    return _plume_radius_at_t(duration_hr, inputs, q_per_well_vol_m3_hr)


def generate_time_series(inputs, q_per_well_vol_m3_hr):
    project_duration = inputs["project_duration"]
    months = int(round(project_duration * 12))
    log_start_hr = inputs.get("log_start_time", 1.0) * 24.0
    pressure_series = []
    plume_series = []

    for i in range(months + 1):
        t_yr = i / 12.0
        t_hr = max(t_yr * 365 * 24, log_start_hr)
        pressure_series.append([round(t_yr, 3), round(pressure_at_time_mpa(t_hr, inputs, q_per_well_vol_m3_hr), 4)])
        plume_series.append([round(t_yr, 3), _plume_radius_at_t(t_hr, inputs, q_per_well_vol_m3_hr)])

    return pressure_series, plume_series


def classify_reservoir_screening(inputs, max_safe_years, plume_radius_m):
    pressure_ok = max_safe_years >= inputs["project_duration"]
    plume_ok    = plume_radius_m <= inputs["radius"]
    if pressure_ok and plume_ok:
        return "Feasible"
    if max_safe_years > 0:
        return "Conditional"
    return "Infeasible"


def run_co2_assessment(reservoir_inputs, co2_rate_kg_hr):
    n_wells = reservoir_inputs["n_wells"]
    rho     = reservoir_inputs.get("co2_density", 700)

    q_per_well_vol = (co2_rate_kg_hr / n_wells) / rho   # m³/hr per well

    p_allow_mpa, _ = compute_allowable_pressure(reservoir_inputs)
    max_safe_years  = find_max_safe_injection_time_years(reservoir_inputs, q_per_well_vol, p_allow_mpa)
    max_rate_kg_hr  = compute_max_sustainable_rate_kg_hr(reservoir_inputs, co2_rate_kg_hr, p_allow_mpa)
    plume_radius_m  = compute_plume_radius_m(reservoir_inputs, q_per_well_vol)

    t_final_hr    = reservoir_inputs["project_duration"] * 365 * 24
    final_pressure = pressure_at_time_mpa(t_final_hr, reservoir_inputs, q_per_well_vol)

    status = classify_reservoir_screening(reservoir_inputs, max_safe_years, plume_radius_m)
    pressure_series, plume_series = generate_time_series(reservoir_inputs, q_per_well_vol)

    messages = {
        "Feasible":     "Reservoir can sustain the required CO₂ rate for the full project duration without exceeding pressure limits.",
        "Conditional":  "Reservoir can inject CO₂, but one or more limits reduce confidence in sustaining the full project duration.",
        "Infeasible":   "Reservoir cannot safely sustain the required CO₂ rate under the selected design conditions.",
    }

    return {
        "status":                        status,
        "feasibility_message":           messages[status],
        "max_safe_injection_time_years": round(max_safe_years, 2),
        "final_pressure_mpa":            round(final_pressure, 4),
        "max_sustainable_rate_kg_hr":    round(max_rate_kg_hr, 2),
        "estimated_plume_radius_m":      round(plume_radius_m, 2),
        "allowable_pressure_mpa":        round(p_allow_mpa, 4),
        "reservoir_radius_m":            reservoir_inputs["radius"],
        "pressure_series":               pressure_series,
        "plume_series":                  plume_series,
    }


HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
}


def lambda_handler(event, _context):
    try:
        body = json.loads(event.get("body") or "{}")
        co2_rate        = body.get("co2_rate_kg_hr")
        reservoir_inputs = body.get("reservoir_inputs")

        if co2_rate is None or not reservoir_inputs:
            return {
                "statusCode": 400,
                "headers": HEADERS,
                "body": json.dumps({"error": "co2_rate_kg_hr and reservoir_inputs are required"}),
            }

        result = run_co2_assessment(reservoir_inputs, float(co2_rate))
        return {"statusCode": 200, "headers": HEADERS, "body": json.dumps(result)}

    except Exception as e:
        return {"statusCode": 500, "headers": HEADERS, "body": json.dumps({"error": str(e)})}
