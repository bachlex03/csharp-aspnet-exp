
reference docs: 

## Prerequisite

- Client ID which generate token and in charge of authorization (resources, policies, permissions,...)
example: **exp-keycloak-client** in this case

## Step by step to custom JWT Claims

Steps:
1. At root Keycloak UI -> At "Configure" section -> Realm settings
2. "User profile" tab -> "Create attribute" button
- Attribute [Name] *: "tenantId" (custom JWT claim add to user attributes so we can edit in UI)
- Display name: "${tenantId}"
- Who can edit?: Admin
- Who can view?: User Admin

3. At "Manage" section -> view any user or create new user => view Tenant ID input then type example: "test_tenant"
Note: At this time tenant_id claim is not add to JWT access token -> continue to step 4.
4. At root Keycloak UI -> Clients -> Client ID (`exp-keycloak-client`)
5. At Client scopes' tab -> {Client Id}-dedicated (`exp-keycloak-client-dedicated`)
6. Create protocol mapper: "Configure a new mapper" or "Add mapper" -> By Configuration -> Name "User Attribute"
- Name *: "tenant id"
- User Attribute: [from step 2]
Token Claim Name: "tenant_id"

Result: `eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI4T2h5WHVKQzgyQTVMUGE5aERWYVZSeC02elhyTGxvQTZMZjFPOHNtV2RvIn0.eyJleHAiOjE3NjY2Nzg3NjAsImlhdCI6MTc2NjY3ODQ2MCwianRpIjoib25ydHJvOmJlMDk1ZTRkLTIyOTAtNDNmYi01MGE0LTExYTBkYjZkNDc1NCIsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6ODA4MC9yZWFsbXMvZXhwLWtleWNsb2FrIiwiYXVkIjoiYWNjb3VudCIsInN1YiI6IjFkOTAwZThmLTdhZDgtNGQ5Zi1iMzRiLTRkMmQ4NjllYzc4ZSIsInR5cCI6IkJlYXJlciIsImF6cCI6ImV4cC1rZXljbG9hay1jbGllbnQiLCJzaWQiOiJmODA1N2EzMi1kMGFkLTRhNjctYjMzMi0wZWZmODg5YjhkYzIiLCJhY3IiOiIxIiwiYWxsb3dlZC1vcmlnaW5zIjpbIi8qIl0sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemF0aW9uIiwiZGVmYXVsdC1yb2xlcy1leHAta2V5Y2xvYWsiXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6ImVtYWlsIHByb2ZpbGUiLCJ0ZW5hbnRfaWQiOiJ0ZXN0X3RlbmFudCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJuYW1lIjoidGVzdCB0ZXN0IiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlckBnbWFpbC5jb20iLCJnaXZlbl9uYW1lIjoidGVzdCIsImZhbWlseV9uYW1lIjoidGVzdCIsImVtYWlsIjoidXNlckBnbWFpbC5jb20ifQ.FF72DRxMqkZEc09Vn9LntpJjqo9u2ND486gI2tyAYS1u1kZB3GGM-rVP47aHKCvVD4qvENuXfhompb3irthR01iS0-ZZ3DaEM5whXvhEkonYaO986jJRQTOevtmCLSP8vlKLcLntxQqGRMEDXs8cnWWCCq95ABhjGApbmTkQt5jDk_9X32VJTzwy0btXBn1nZpqtUIMTARyuv_Ebrls_YBz5MA6bT2AU-sKDnJH4R_FRU22oK_X5iRKKsp9sTtKKrf9IzwO0vUlrvPcGrvUu_CsPlXdlDOBoxIddfMQP_QvqVgIK9QlKbuaIMVVt2oPWceIOgLTcwM0pyg67NKREgA`

Decoded JWT:

```json
{
  "exp": 1766678760,
  "iat": 1766678460,
  "jti": "onrtro:be095e4d-2290-43fb-50a4-11a0db6d4754",
  "iss": "http://localhost:8080/realms/exp-keycloak",
  "aud": "account",
  "sub": "1d900e8f-7ad8-4d9f-b34b-4d2d869ec78e",
  "typ": "Bearer",
  "azp": "exp-keycloak-client",
  "sid": "f8057a32-d0ad-4a67-b332-0eff889b8dc2",
  "acr": "1",
  "allowed-origins": [
    "/*"
  ],
  "realm_access": {
    "roles": [
      "offline_access",
      "uma_authorization",
      "default-roles-exp-keycloak"
    ]
  },
  "resource_access": {
    "account": {
      "roles": [
        "manage-account",
        "manage-account-links",
        "view-profile"
      ]
    }
  },
  "scope": "email profile",
  "tenant_id": "test_tenant",
  "email_verified": true,
  "name": "test test",
  "preferred_username": "user@gmail.com",
  "given_name": "test",
  "family_name": "test",
  "email": "user@gmail.com"
}
```