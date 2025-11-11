FROM postgres:18

ENV POSTGRES_PASSWORD=test

COPY video_analytics_schema_pg.sql /docker-entrypoint-initdb.d
COPY video_analytics_sample_data.sql /docker-entrypoint-initdb.d/zzz_video_analytics_sample_data.sql
