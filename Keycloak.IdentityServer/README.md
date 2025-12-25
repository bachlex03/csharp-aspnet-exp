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


## Import realm

After export realm then delete 2 default policies "Default Policy", "Default Permission" (If have)

```json
...
    "authorizationSettings" : {
      "allowRemoteResourceManagement" : true,
      "policyEnforcementMode" : "ENFORCING",
      "resources" : [ {
        "name" : "Default Resource",
        "type" : "urn:admin-rest-api:resources:default",
        "ownerManagedAccess" : false,
        "attributes" : { },
        "uris" : [ "/*" ]
      } ],
      "policies" : [ {
        "name" : "Default Policy",
        "description" : "A policy that grants access only for users within this realm",
        "type" : "js",
        "logic" : "POSITIVE",
        "decisionStrategy" : "AFFIRMATIVE",
        "config" : {
          "code" : "// by default, grants any permission associated with this policy\n$evaluation.grant();\n"
        }
      }, {
        "name" : "Default Permission",
        "description" : "A permission that applies to the default resource type",
        "type" : "resource",
        "logic" : "POSITIVE",
        "decisionStrategy" : "UNANIMOUS",
        "config" : {
          "defaultResourceType" : "urn:admin-rest-api:resources:default",
          "applyPolicies" : "[\"Default Policy\"]"
        }
      } ],
      "scopes" : [ ],
      "decisionStrategy" : "UNANIMOUS"
    }
...
```

After remove

```json
...
    "authorizationSettings" : {
      "allowRemoteResourceManagement" : true,
      "policyEnforcementMode" : "ENFORCING",
      "resources" : [ {
        "name" : "Default Resource",
        "type" : "urn:admin-rest-api:resources:default",
        "ownerManagedAccess" : false,
        "attributes" : { },
        "uris" : [ "/*" ]
      } ],
      "policies" : [ ],
      "scopes" : [ ],
      "decisionStrategy" : "UNANIMOUS"
    }
...
```

=> This ensure imported