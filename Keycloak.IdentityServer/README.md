# TESTING KEYCLOAK IDENTITY SERVER

<!-- Current Keycloak Version: 26.3.4 -->

## Using Keycloak sh script

`/opt/keycloak/bin/kc.sh`

## Export realm include users data

`docker exec -it exp.keycloak.server /opt/keycloak/bin/kc.sh export --dir /tmp/export  --realm ygz-realm   --users realm_file`

### copy from container to local machine

`docker cp ygz.keycloak.server:/tmp/export ./provisions/volumes/keycloak`

## Tryout with docker compose

`docker-compose --env-file .env.example up -d`