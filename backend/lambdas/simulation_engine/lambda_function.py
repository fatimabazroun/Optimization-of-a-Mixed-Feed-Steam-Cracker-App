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

    low = 0.0
    high = max(q_total_kg_hr * 5, 1.0)
    best = 0.0

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
    duration = inputs["project_duration"]
    reservoir_radius = inputs["radius"]

    if max_safe_years >= duration and plume_radius_m <= reservoir_radius:
        return "Feasible"

    if max_safe_years > 0 and (max_safe_years < duration or plume_radius_m > reservoir_radius):
        return "Conditional"

    return "Infeasible"


def run_reservoir_model(inputs, q_total_kg_hr):
    n_wells = inputs["n_wells"]
    rho = inputs.get("co2_density", 700)

    q_per_well_mass_kg_hr = q_total_kg_hr / n_wells
    q_per_well_vol_m3_hr = q_per_well_mass_kg_hr / rho

    p_allow_mpa, p_frac_mpa = compute_allowable_pressure(inputs)
    max_safe_years = find_max_safe_injection_time_years(inputs, q_per_well_vol_m3_hr, p_allow_mpa)
    max_rate_kg_hr = compute_max_sustainable_rate_kg_hr(inputs, q_total_kg_hr, p_allow_mpa)
    plume_radius_m = compute_plume_radius_m(inputs, q_per_well_vol_m3_hr)

    t_final = inputs["project_duration"] * 365 * 24
    if inputs["reservoir_type"].strip().lower() == "open":
        final_pressure = pressure_open_mpa(t_final, inputs, q_per_well_vol_m3_hr)
    else:
        final_pressure = pressure_closed_mpa(t_final, inputs, q_per_well_vol_m3_hr)

    status = classify_reservoir_screening(inputs, max_safe_years, plume_radius_m)

    if status == "Feasible":
        feasibility_message = "Reservoir can sustain the required CO2 rate for the full project duration without exceeding pressure limits."
    elif status == "Conditional":
        feasibility_message = "Reservoir can inject CO2, but one or more limits reduce confidence in sustaining the full project duration."
    else:
        feasibility_message = "Reservoir cannot safely sustain the required CO2 rate under the selected design conditions."

    return {
        "status": status,
        "feasibility_message": feasibility_message,
        "max_safe_injection_time_years": round(max_safe_years, 2),
        "final_pressure_mpa": round(final_pressure, 4),
        "max_sustainable_rate_kg_hr": round(max_rate_kg_hr, 2),
        "estimated_plume_radius_m": round(plume_radius_m, 2)
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
                "body": json.dumps({"error": "No match found"})
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
