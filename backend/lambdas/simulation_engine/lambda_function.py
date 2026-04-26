import json
import math
import boto3
import io
import os


s3 = boto3.client("s3")

BUCKET = os.environ["RESULTS_BUCKET"]


def classify_ethylene_yield(value):
    if value < 40:
        return {
            "status": "Not Acceptable",
            "explanation": "Low severity cracking. Ethane is underutilized, resulting in poor ethylene production and inefficient process performance."
        }
    elif 40 <= value < 55:
        return {
            "status": "Needs Improvement",
            "explanation": "Moderate cracking achieved, but still below optimal industrial performance. Further optimization is required."
        }
    elif 55 <= value < 65:
        return {
            "status": "Acceptable",
            "explanation": "Balanced operation with reasonable conversion and ethylene yield. Represents typical industrial performance."
        }
    elif 65 <= value <= 75:
        return {
            "status": "High Performance",
            "explanation": "High conversion efficiency with strong ethylene production. Indicates optimized cracking conditions."
        }
    else:
        return {
            "status": "Risky",
            "explanation": "Excessive cracking severity may lead to higher byproducts, reduced selectivity, and potential operational issues."
        }


def classify_furnace_reduction(value):
    if value < 10:
        return {
            "status": "Not Acceptable",
            "explanation": "Negligible reduction in furnace energy consumption. Indicates no significant improvement compared to baseline operation."
        }
    elif 10 <= value < 30:
        return {
            "status": "Minor Improvement",
            "explanation": "Some reduction achieved, but still below desired industrial performance. Further process optimization is required."
        }
    elif 30 <= value <= 50:
        return {
            "status": "Good Reduction",
            "explanation": "Significant reduction in furnace energy consumption compared to baseline. Indicates improved process efficiency."
        }
    else:
        return {
            "status": "Excellent Performance",
            "explanation": "High energy savings achieved through improved conversion and process optimization. Represents excellent performance under current conditions."
        }


def classify_cost_saving(value):
    if value < 2:
        return {
            "status": "Not Acceptable",
            "explanation": "Negligible cost reduction. The process improvement does not provide sufficient economic value to justify implementation."
        }
    elif 2 <= value < 5:
        return {
            "status": "Minor Improvement",
            "explanation": "Small cost savings achieved, but may not be enough to offset operational complexity or investment costs."
        }
    elif 5 <= value < 8:
        return {
            "status": "Moderate Improvement",
            "explanation": "Moderate cost reduction with potential benefits. Requires further evaluation to balance economic gains with process performance."
        }
    elif 8 <= value <= 12:
        return {
            "status": "Good Reduction",
            "explanation": "Significant cost reduction achieved, indicating improved economic performance and better process efficiency."
        }
    else:
        return {
            "status": "Excellent Performance",
            "explanation": "High cost savings achieved, making the process highly attractive from an economic perspective."
        }


def classify_hydrogen_purity(value):
    if value < 80:
        return {
            "status": "Not Acceptable",
            "explanation": "Low hydrogen purity indicates poor separation efficiency, with significant methane contamination in the hydrogen stream."
        }
    elif 80 <= value < 85:
        return {
            "status": "Moderate Performance",
            "explanation": "Moderate hydrogen purity achieved, but still below optimal levels. Further improvement in separation efficiency is required."
        }
    elif 85 <= value <= 88:
        return {
            "status": "Acceptable",
            "explanation": "Acceptable hydrogen purity with reasonable separation performance, indicating effective recovery of hydrogen."
        }
    else:
        return {
            "status": "High Performance",
            "explanation": "High-purity hydrogen stream achieved, reflecting efficient separation and strong process performance."
        }


def build_che_evaluation(result):
    return {
        "ethylene_yield": {
            "value": result["ethylene_yield_percent"],
            **classify_ethylene_yield(result["ethylene_yield_percent"])
        },
        "furnace_reduction": {
            "value": result["furnace_reduction_percent"],
            **classify_furnace_reduction(result["furnace_reduction_percent"])
        },
        "cost_saving": {
            "value": result["cost_saving_percent"],
            **classify_cost_saving(result["cost_saving_percent"])
        },
        "hydrogen_purity": {
            "value": result["hydrogen_purity_percent"],
            **classify_hydrogen_purity(result["hydrogen_purity_percent"])
        }
    }


def build_ise_s1(selected_value):
    optimal_value = 0.85

    if selected_value == optimal_value:
        return {
            "scenario": "S1",
            "optimal_value": optimal_value,
            "is_optimal": True,
            "recommendation": f"The selected conversion {selected_value} is already optimal. Continue operating at X = {optimal_value} for the best overall performance."
        }

    return {
        "scenario": "S1",
        "optimal_value": optimal_value,
        "is_optimal": False,
        "recommendation": f"Increasing conversion {selected_value} will improve overall system performance, as it leads to higher ethylene and hydrogen production while simultaneously reducing CO2 emissions. It is recommended to operate at the highest feasible conversion (X = {optimal_value}) within operational limits."
    }


def build_ise_result(scenario_id, selected_value):
    if scenario_id == "S1":
        return build_ise_s1(selected_value)
    elif scenario_id == "S2":
        return build_ise_s2(selected_value)
    elif scenario_id == "S3":
        return build_ise_s3(selected_value)
    return None


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
    arg = (4.0 * k_m2 * t_s) / max(phi * mu_pa_s * ct_pa * rw_m ** 2, 1e-40)
    arg = max(arg, 1.000001)
    return (q_m3_s * mu_pa_s) / (4.0 * math.pi * k_m2 * h_m) * (math.log(arg) - EULER_GAMMA + skin)


def pressure_at_time_mpa(t_hr, inputs, q_per_well_vol_m3_hr):
    mu_pa_s  = inputs.get("co2_viscosity", 0.05) * 1e-3
    k_m2     = inputs["permeability"] * 9.869233e-16
    h_m      = inputs["thickness"]
    phi      = max(inputs["porosity"], 1e-9)
    ct_pa    = inputs.get("compressibility", 1e-4) / 1e6
    rw_m     = inputs.get("well_radius", 0.1)
    p_i_mpa  = inputs["initial_pressure"]
    skin     = inputs.get("skin", 0.0)

    t0_s  = inputs.get("log_start_time", 1.0) * 24 * 3600
    t_s   = max(t_hr * 3600.0, t0_s)
    q_m3s = q_per_well_vol_m3_hr / 3600.0

    dp_pa  = _delta_p_open_pa(t_s, k_m2, h_m, phi, mu_pa_s, ct_pa, rw_m, skin, q_m3s)
    dp_mpa = dp_pa / 1e6

    if inputs.get("reservoir_type", "Open").strip().lower() == "closed":
        alpha = inputs.get("closed_multiplier", 3.0)
        dp_mpa *= alpha

    return p_i_mpa + dp_mpa


def find_max_safe_injection_time_years(inputs, q_per_well_vol_m3_hr, p_allow_mpa):
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
    if log_arg > 700:
        return 100.0

    t0_s     = inputs.get("log_start_time", 1.0) * 24 * 3600
    t_safe_s = max(math.exp(log_arg) / B, t0_s)
    t_safe_yr = t_safe_s / (365 * 24 * 3600)

    return round(min(t_safe_yr, 100.0), 2)


def compute_max_sustainable_rate_kg_hr(inputs, q_total_kg_hr, p_allow_mpa):
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
    vol   = q_per_well_vol_m3_hr * t_hr
    return math.sqrt(vol / (math.pi * phi * h_m * s_co2))


def compute_plume_radius_m(inputs, q_per_well_vol_m3_hr):
    duration_hr = inputs["project_duration"] * 365 * 24
    return round(_plume_radius_at_t(duration_hr, inputs, q_per_well_vol_m3_hr), 2)


def generate_time_series(inputs, q_per_well_vol, max_safe_years, n_points=60):
    project_duration = inputs["project_duration"]

    if 0 < max_safe_years < 100:
        max_t_yr = min(max_safe_years * 1.5, 100.0)
    else:
        max_t_yr = project_duration * 1.5

    pressure_series = []
    plume_series    = []

    for i in range(1, n_points + 1):
        t_yr = i * max_t_yr / n_points
        t_hr = t_yr * 365 * 24
        pressure_series.append([round(t_yr, 3), round(pressure_at_time_mpa(t_hr, inputs, q_per_well_vol), 4)])
        plume_series.append([round(t_yr, 3), round(_plume_radius_at_t(t_hr, inputs, q_per_well_vol), 2)])

    return pressure_series, plume_series


def classify_reservoir_screening(inputs, max_safe_years, plume_radius_m):
    pressure_ok = max_safe_years >= inputs["project_duration"]
    plume_ok    = plume_radius_m <= inputs["radius"]
    if pressure_ok and plume_ok:
        return "Feasible"
    if max_safe_years >= 0.9 * inputs["project_duration"]:
        return "Conditional"
    return "Infeasible"


def run_reservoir_model(inputs, q_total_kg_hr):
    n_wells = inputs["n_wells"]
    rho     = inputs.get("co2_density", 700)

    q_per_well_vol = (q_total_kg_hr / n_wells) / rho

    p_allow_mpa, _ = compute_allowable_pressure(inputs)
    max_safe_years  = find_max_safe_injection_time_years(inputs, q_per_well_vol, p_allow_mpa)
    max_rate_kg_hr  = compute_max_sustainable_rate_kg_hr(inputs, q_total_kg_hr, p_allow_mpa)
    plume_radius_m  = compute_plume_radius_m(inputs, q_per_well_vol)

    t_final_hr     = inputs["project_duration"] * 365 * 24
    final_pressure = pressure_at_time_mpa(t_final_hr, inputs, q_per_well_vol)

    status = classify_reservoir_screening(inputs, max_safe_years, plume_radius_m)

    messages = {
        "Feasible":    "Reservoir can sustain the required CO₂ rate for the full project duration without exceeding pressure limits.",
        "Conditional": "Reservoir can inject CO₂, but one or more limits reduce confidence in sustaining the full project duration.",
        "Infeasible":  "Reservoir cannot safely sustain the required CO₂ rate under the selected design conditions.",
    }

    pressure_series, plume_series = generate_time_series(inputs, q_per_well_vol, max_safe_years)

    return {
        "status":                        status,
        "feasibility_message":           messages[status],
        "max_safe_injection_time_years": round(max_safe_years, 2),
        "final_pressure_mpa":            round(final_pressure, 4),
        "max_sustainable_rate_kg_hr":    round(max_rate_kg_hr, 2),
        "estimated_plume_radius_m":      round(plume_radius_m, 2),
        "allowable_pressure_mpa":        round(p_allow_mpa, 4),
        "reservoir_radius_m":            inputs["radius"],
        "pressure_series":               pressure_series,
        "plume_series":                  plume_series,
    }


def ise_eth(X):
    return 2220.03 * X + 18.16

def ise_hydrogen(X):
    return 159.53 * X + 2.16

def ise_co2e(X):
    return -1039.71 * X + 3134.26

def ise2_eth(X1, X2):
    return 2220.13 * X1 + 0.00 * X2 + 18.06

def ise2_hydrogen(X1, X2):
    return 159.60 * X1 + 0.00 * X2 + 2.09

def ise2_co2e(X1, X2):
    return -1040.00 * X1 + 16705.00 * X2 + 1798.10


def parse_s2_selection(selection):
    x1_str, x2_str = selection.split("-")
    return float(x1_str), float(x2_str)


def build_ise_s2(selected_value):
    x1, x2 = parse_s2_selection(selected_value)

    optimal_x1 = 0.90
    optimal_x2 = 0.04

    is_optimal = (x1 == optimal_x1 and x2 == optimal_x2)

    if is_optimal:
        recommendation = (
            f"The selected values (X1 = {x1}, X2 = {x2}) are already optimal. "
            f"Continue operating at X1 = {optimal_x1} and X2 = {optimal_x2} to maximize ethylene production while minimizing CO2 emissions."
        )
    else:
        recommendation = (
            f"For the selected values, increasing {x1} toward 0.90 will improve ethylene and hydrogen production. "
            f"To minimize CO2 emissions, keep {x2} near the lower end of its range, ideally around 0.04. "
            f"For a balanced approach, operate within X1 = 0.80–0.90 and X2 = 0.04–0.06."
        )

    return {
        "scenario": "S2",
        "optimal_x1": optimal_x1,
        "optimal_x2_for_low_co2": optimal_x2,
        "is_optimal": is_optimal,
        "recommendation": recommendation
    }

def ise3_eth(X1, X2, X3):
    return 2220 * X1 + 18.18

def ise3_hydrogen(X1, X2, X3):
    return 159.60 * X1 + 2.10

def ise3_co2e(X1, X2, X3):
    return -1040 * X1 + 16705.00 * X2 + 8560.00 * X3 + 1944.30

def parse_s3_selection(selection):
    x1_str, x2_str, x3_str = selection.split("-")
    return float(x1_str), float(x2_str), float(x3_str)

def build_ise_s3(selected_value):
    X1, X2, X3 = parse_s3_selection(selected_value)

    is_optimal = (
        0.75 <= X1 <= 0.80 and
        0.03 <= X2 <= 0.04 and
        0.01 <= X3 <= 0.02
    )

    if is_optimal:
        recommendation = (
            f"The selected values ({X1},{X2},{X3}) are within the recommended balanced operating range. "
            f"Maintain {X1}, within 0.75–0.80, {X2} within 0.03–0.04, and {X3} within 0.01–0.02 for balanced performance between production and emissions."
        )
    else:
        recommendation = (
            f"For the selected values ({X1},{X2},{X3}), increasing X1 will increase ethylene and hydrogen production. "
            f"To reduce CO2 emissions, increase {X1} and minimize both {X2} and {X3}, as they directly increase emissions. "
            f"For a balanced performance between production and emissions, it is recommended to operate within X1 = 0.75–0.80, X2 = 0.03–0.04, and X3 = 0.01–0.02."
        )

    return {
        "scenario": "S3",
        "recommended_range": {
            "x1": "0.75-0.80",
            "x2": "0.03-0.04",
            "x3": "0.01-0.02"
        },
        "is_in_recommended_range": is_optimal,
        "recommendation": recommendation
    }


# ── Main handler ──────────────────────────────────────────────────────────────

def lambda_handler(event, context):
    if "body" in event:
        event = json.loads(event["body"])

    scenario_id = event.get("scenario_id")
    selected_value = event.get("selected_value")
    use_reservoir = event.get("use_reservoir", False)
    reservoir_inputs = event.get("reservoir_inputs")

    if not scenario_id:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "scenario_id is required"})
        }

    if selected_value is None:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "selected_value is required"})
        }

    key = f"results/scenario_{scenario_id[1:]}.json"

    try:
        response = s3.get_object(Bucket=BUCKET, Key=key)
        data = json.loads(response["Body"].read())

        matched_result = None

        for option in data["options"]:
            if "conversion" in option and option["conversion"] == selected_value:
                matched_result = option["results"]
                break

            if "selection" in option and option["selection"] == selected_value:
                matched_result = option["results"]
                break

        if matched_result is None:
            return {
                "statusCode": 404,
                "body": json.dumps({"error": f"No match found for selected_value={selected_value}"})
            }

        required_fields = ["ethylene_yield_percent", "furnace_reduction_percent",
                           "cost_saving_percent", "hydrogen_purity_percent", "co2_rate"]
        missing = [f for f in required_fields if matched_result.get(f) is None]
        if missing:
            return {
                "statusCode": 500,
                "body": json.dumps({"error": f"Result data incomplete for {selected_value}. Missing fields: {missing}"})
            }

        che_evaluation = build_che_evaluation(matched_result)
        ise_result = build_ise_result(scenario_id, selected_value)

        ise_kpis = None

        if scenario_id == "S1":
            X = selected_value
            ise_kpis = {
                "ethylene_kg_hr": round(ise_eth(X), 2),
                "hydrogen_kg_hr": round(ise_hydrogen(X), 2),
                "co2e_kg_hr": round(ise_co2e(X), 2)
            }

        elif scenario_id == "S2":
            X1, X2 = parse_s2_selection(selected_value)
            ise_kpis = {
                "ethylene_kg_hr": round(ise2_eth(X1, X2), 2),
                "hydrogen_kg_hr": round(ise2_hydrogen(X1, X2), 2),
                "co2e_kg_hr": round(ise2_co2e(X1, X2), 2)
            }
        elif scenario_id == "S3":
            X1, X2, X3 = parse_s3_selection(selected_value)
            ise_kpis = {
                "ethylene_kg_hr": round(ise3_eth(X1, X2, X3), 2),
                "hydrogen_kg_hr": round(ise3_hydrogen(X1, X2, X3), 2),
                "co2e_kg_hr": round(ise3_co2e(X1, X2, X3), 2)
            }

        response_body = {
            "scenario_id": scenario_id,
            "selected_value": selected_value,
            "results": matched_result,
            "performance": che_evaluation,
            "ise": ise_result,
            "ise_calculated_kpis": ise_kpis
        }

        if use_reservoir:
            co2_rate = matched_result.get("co2_rate")
            if co2_rate is None:
                return {
                    "statusCode": 400,
                    "body": json.dumps({"error": "co2_rate is missing from the selected JSON result"})
                }

            response_body["reservoir"] = run_reservoir_model(reservoir_inputs, co2_rate)

        return {
            "statusCode": 200,
            "body": json.dumps(response_body)
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
