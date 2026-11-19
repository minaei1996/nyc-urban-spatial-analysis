from pathlib import Path

from src.database import get_connection


DATA_DIR = Path("data/raw")


def copy_csv(
    table_name: str,
    filename: str,
    columns: list[str],
    has_header: bool = True,
) -> None:
    path = DATA_DIR / filename

    if not path.exists():
        raise FileNotFoundError(path)

    column_list = ", ".join(columns)
    header_option = "true" if has_header else "false"

    copy_sql = f"""
        COPY {table_name} ({column_list})
        FROM STDIN
        WITH (
            FORMAT csv,
            HEADER {header_option},
            NULL ''
        )
    """

    print(f"Loading {filename} -> {table_name}")

    with get_connection() as conn:
        with conn.cursor() as cur:
            with cur.copy(copy_sql) as copy:
                with path.open("rb") as file:
                    while chunk := file.read(1024 * 1024):
                        copy.write(chunk)

        conn.commit()

    print("  Done.")


def main():

    copy_csv(
        "raw.fdny_firehouses",
        "FDNY_Firehouse_Listing.csv",
        [
            "facility_name",
            "facility_address",
            "borough",
            "postcode",
            "latitude",
            "longitude",
            "community_board",
            "community_council",
            "census_tract",
            "bin",
            "bbl",
            "nta",
        ],
    )

    copy_csv(
        "raw.nyc_311",
        "nyc_311.csv",
        [
            "unique_key",
            "created_date",
            "closed_date",
            "agency",
            "agency_name",
            "complaint_type",
            "descriptor",
            "location_type",
            "incident_zip",
            "incident_address",
            "street_name",
            "cross_street_1",
            "cross_street_2",
            "intersection_street_1",
            "intersection_street_2",
            "address_type",
            "city",
            "landmark",
            "facility_type",
            "status",
            "due_date",
            "resolution_description",
            "resolution_action_updated_date",
            "community_board",
            "bbl",
            "borough",
            "x_coordinate_state_plane",
            "y_coordinate_state_plane",
            "open_data_channel_type",
            "park_facility_name",
            "park_borough",
            "vehicle_type",
            "taxi_company_borough",
            "taxi_pick_up_location",
            "bridge_highway_name",
            "bridge_highway_direction",
            "road_ramp",
            "bridge_highway_segment",
            "latitude",
            "longitude",
            "location",
        ],
    )

    copy_csv(
        "raw.mesonet",
        "nys_mesonet_202307.csv",
        [
            "station",
            "time_end",
            "latitude",
            "longitude",
            "elevation_m",
            "temp_2m_max_c",
            "temp_2m_min_c",
            "temp_2m_avg_c",
            "apparent_temperature_max_c",
            "apparent_temperature_min_c",
            "apparent_temperature_avg_c",
        ],
    )

    copy_csv(
        "raw.rite_aid",
        "rite_aid_odm.csv",
        [
            "geometry_wkb",
            "building_id",
            "pharm_id",
            "name",
            "pharm_geometry_wkb",
        ],
    )

    copy_csv(
        "raw.fire_odm",
        "fire_odm.csv",
        [
            "start_vid",
            "end_vid",
            "agg_cost",
        ],
        has_header=False,
    )


if __name__ == "__main__":
    main()
