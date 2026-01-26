import os
import psycopg2

def handler(event, context):
    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=5432,
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        sslmode="require"
    )

    with conn:
        with conn.cursor() as cur:
            with open("schema.sql", "r") as f:
                sql = f.read()
                cur.execute(sql)

    return {
        "status": "ok",
        "message": "Schema applied successfully"
    }
