# SETUP KEYCLOAK

Configuring Keycloak docs: `https://www.keycloak.org/server/configuration`

other docs:
`https://www.keycloak.org/server/importExport#_importing_a_realm_during_startup`

## Starting Keycloak

refs: `https://www.keycloak.org/server/configuration#_starting_keycloak`

### Development mode

`bin/kc.[sh|bat] start-dev`

### Production mode

`bin/kc.[sh|bat] start`

## Command options explain

`start-dev`
Description: Start development mode

`--import-realm`
Description: Import realm configuration files from `/opt/keycloak/data/import` directory during startup

## Admin User Setup

### Development Mode (start-dev)

In development mode, you can create the initial admin user using environment variables:

```yaml
environment:
  - KEYCLOAK_ADMIN=admin
  - KEYCLOAK_ADMIN_PASSWORD=admin
```

**Default credentials** (if not set):
- Username: `admin`
- Password: `admin`

### Alternative Methods

1. **Via localhost** (as shown in the UI):
   - Access Keycloak from `http://localhost:8080`
   - The admin user creation form will appear

2. **Via bootstrap command**:
   ```bash
   docker exec -it exp.keycloak.server /opt/keycloak/bin/kc.sh bootstrap-admin
   ```

3. **Via environment variables** (recommended for automation):
   ```yaml
   - KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN:-admin}
   - KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD:-admin}
   ```

## Troubleshooting

### "Local access required" Message

This appears when:
- Keycloak is running but no admin user exists
- You're accessing from a non-localhost address

**Solutions:**
1. Access via `http://localhost:8080` (not `127.0.0.1` or IP address)
2. Set `KEYCLOAK_ADMIN` and `KEYCLOAK_ADMIN_PASSWORD` environment variables
3. Use the bootstrap-admin command inside the container