# TESTING KEYCLOAK IDENTITY SERVER

<!-- Current Keycloak Version: 26.3.4 -->

## Using Keycloak sh

`/opt/keycloak/bin/kc.sh`

## Export realm include users data

`docker exec -it exp.keycloak.server /opt/keycloak/bin/kc.sh export --dir /opt/keycloak/data/export/25_12_2025 --realm=exp-keycloak --users=realm_file`

`docker exec -it exp.keycloak.server /opt/keycloak/bin/kc.sh export --dir=/opt/keycloak/data/export/25_12_2025_optimized --realm=exp-keycloak --users=realm_file --optimized`

### copy from container to local machine

`docker cp exp.keycloak.server:/opt/keycloak/data/export ./provisions/volumes/keycloak`

## Tryout with docker compose

`docker-compose --env-file .env.example up -d`