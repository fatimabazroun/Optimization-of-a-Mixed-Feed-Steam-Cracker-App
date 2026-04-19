import json
import math


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


def pressure_open_mpa(t_hr, inputs, q_per_well_vol_m3_hr):
    mu_cp = inputs.get("co2_viscosity", 0.05)
    k_md = inputs["permeability"]
    h_m = inputs["thickness"]
    ct_per_mpa = inputs.get("compressibility", 1e-4)
    rw_m = inputs.get("well_radius", 0.1)
    p_init_mpa = inputs["initial_pressure"]
    skin = inputs.get("skin", 0.0)

    gamma = 0.577
    denom = max(2 * math.pi * k_md * h_m, 1e-9)
    arg = max(t_hr / max((rw_m ** 2) * ct_per_mpa, 1e-9), 1.000001)

    delta_p = ((q_per_well_vol_m3_hr * mu_cp) / denom) * (math.log(arg) + gamma + skin)
    return p_init_mpa + delta_p


def pressure_closed_mpa(t_hr, inputs, q_per_well_vol_m3_hr):
    re_m = inputs["radius"]
    ct_per_mpa = inputs.get("compressibility", 1e-4)
    t_boundary = max((re_m ** 2) * ct_per_mpa, 1e-9)

    if t_hr < t_boundary:
        return pressure_open_mpa(t_hr, inputs, q_per_well_vol_m3_hr)

    p_open = pressure_open_mpa(t_hr, inputs, q_per_well_vol_m3_hr)
    p_init = inputs["initial_pressure"]
    return p_init + (p_open - p_init) * 1.5


def find_max_safe_injection_time_years(inputs, q_per_well_vol_m3_hr, p_allow_mpa):
    reservoir_type = inputs["reservoir_type"].strip().lower()
    max_safe_years = 0.0

    for month in range(1, 1201):
        t_hr = month * 30 * 24
        if reservoir_type == "open":
            p_t = pressure_open_mpa(t_hr, inputs, q_per_well_vol_m3_hr)
        else:
            p_t = pressure_closed_mpa(t_hr, inputs, q_per_well_vol_m3_hr)

        if p_t >= p_allow_mpa:
            break
        max_safe_years = month / 12.0

    return round(max_safe_years, 2)


def compute_max_sustainable_rate_kg_hr(inputs, q_total_kg_hr, p_allow_mpa):
    duration_years = inputs["project_duration"]
    reservoir_type = inputs["reservoir_type"].strip().lower()
    n_wells = inputs["n_wells"]
    rho = inputs.get("co2_density", 700)
    target_t_hr = duration_years * 365 * 24

    low, high, best = 0.0, max(q_total_kg_hr * 5, 1.0), 0.0

    for _ in range(50):
        mid = (low + high) / 2.0
        q_per_well_vol = (mid / n_wells) / rho
        if reservoir_type == "open":
            p_end = pressure_open_mpa(target_t_hr, inputs, q_per_well_vol)
        else:
            p_end = pressure_closed_mpa(target_t_hr, inputs, q_per_well_vol)

        if p_end <= p_allow_mpa:
            best = mid
            low = mid
        else:
            high = mid

    return round(best, 2)


def compute_plume_radius_m(inputs, q_per_well_vol_m3_hr):
    duration_hr = inputs["project_duration"] * 365 * 24
    phi = inputs["porosity"]
    h_m = inputs["thickness"]
    accessible_volume = q_per_well_vol_m3_hr * duration_hr
    radius = math.sqrt(accessible_volume / (math.pi * max(phi * h_m, 1e-9)))
    return round(radius, 2)


def classify_reservoir_screening(inputs, max_safe_years, plume_radius_m):
    if max_safe_years >= inputs["project_duration"] and plume_radius_m <= inputs["radius"]:
        return "Feasible"
    if max_safe_years > 0:
        return "Conditional"
    return "Infeasible"


def run_co2_assessment(reservoir_inputs, co2_rate_kg_hr):
    n_wells = reservoir_inputs["n_wells"]
    rho = reservoir_inputs.get("co2_density", 700)

    q_per_well_vol = (co2_rate_kg_hr / n_wells) / rho

    p_allow_mpa, _ = compute_allowable_pressure(reservoir_inputs)
    max_safe_years = find_max_safe_injection_time_years(reservoir_inputs, q_per_well_vol, p_allow_mpa)
    max_rate_kg_hr = compute_max_sustainable_rate_kg_hr(reservoir_inputs, co2_rate_kg_hr, p_allow_mpa)
    plume_radius_m = compute_plume_radius_m(reservoir_inputs, q_per_well_vol)

    t_final = reservoir_inputs["project_duration"] * 365 * 24
    if reservoir_inputs["reservoir_type"].strip().lower() == "open":
        final_pressure = pressure_open_mpa(t_final, reservoir_inputs, q_per_well_vol)
    else:
        final_pressure = pressure_closed_mpa(t_final, reservoir_inputs, q_per_well_vol)

    status = classify_reservoir_screening(reservoir_inputs, max_safe_years, plume_radius_m)

    messages = {
        "Feasible": "Reservoir can sustain the required CO₂ rate for the full project duration without exceeding pressure limits.",
        "Conditional": "Reservoir can inject CO₂, but one or more limits reduce confidence in sustaining the full project duration.",
        "Infeasible": "Reservoir cannot safely sustain the required CO₂ rate under the selected design conditions.",
    }

    return {
        "status": status,
        "feasibility_message": messages[status],
        "max_safe_injection_time_years": round(max_safe_years, 2),
        "final_pressure_mpa": round(final_pressure, 4),
        "max_sustainable_rate_kg_hr": round(max_rate_kg_hr, 2),
        "estimated_plume_radius_m": round(plume_radius_m, 2),
    }


HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
}


def lambda_handler(event, _context):
    try:
        body = json.loads(event.get("body") or "{}")

        co2_rate = body.get("co2_rate_kg_hr")
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
