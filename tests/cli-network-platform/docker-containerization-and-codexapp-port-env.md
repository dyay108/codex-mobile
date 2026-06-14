### Feature: Docker containerization, schema-backed build, and CODEXAPP_PORT default

#### Prerequisites
- Docker is running.
- Port `18923` is available.
- A disposable host directory is available for `CODEX_HOME` and workspace mounts.

#### Steps
1. Run `docker build -t codexapp-local .`.
2. Confirm the frontend typecheck completes without missing-module errors for `documentation/app-server-schemas/typescript`.
3. Start the image with `docker run --rm -d --name codexapp-local -p 18923:18923 -v <codex-home>:/home/node/.codex -v <workspace>:/workspace codexapp-local`.
4. Run `docker inspect --format '{{.State.Health.Status}}' codexapp-local` until it reports `healthy`.
5. Open `http://localhost:18923/` and verify the app loads.
6. Run `docker exec codexapp-local sh -lc 'id -u; printf "%s\n" "$CODEX_HOME" "$CODEXAPP_PORT"'`.
7. Stop the container, then start the built CLI outside Docker with `CODEXAPP_PORT=5997 node dist-cli/index.js --no-open --no-tunnel --no-login --no-password`.
8. Start it again with `CODEXAPP_PORT=5997 node dist-cli/index.js --port 5998 --no-open --no-tunnel --no-login --no-password`.

#### Expected Results
- The image builds with the required schema types in its build context, the healthcheck becomes healthy, and the app responds on port `18923`.
- The container process runs with a non-zero user ID.
- `CODEX_HOME` is `/home/node/.codex` and `CODEXAPP_PORT` is `18923`.
- The CLI uses port `5997` when only `CODEXAPP_PORT` is set.
- Explicit `--port 5998` overrides `CODEXAPP_PORT`.

#### Rollback/Cleanup
- Run `docker rm -f codexapp-local` if it is still running.
- Remove the disposable Codex home/workspace directories and image with `docker image rm codexapp-local`.
