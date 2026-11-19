import psycopg

DB_CONFIG = {
    "host": "localhost",
    "port": 25432,
    "dbname": "nyc_urban",
    "user": "docker",
    "password":"docker"
}


def get_connection():
    return psycopg.connect(**DB_CONFIG)