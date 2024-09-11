# Test Red Hat Developer Hub locally

## Getting started

1. Create `.env` file using `env.sample`.

   ```sh
   cp env.sample .env
   ```

   In most cases, when you you don't need GitHub Auth or testing different releases you
   can leave it as it is and it should work.
1. Update `configs/app-config.local.yaml`.
   If you need fetching files form from GitHub you should configure `integrations.github`.
   The recommended way is to use GitHub Apps. You can find hints on how to configure it in [github-app-credentials.example.yaml](configs/github-app-credentials.example.yaml) or mode tailed instruction in [Backstage documentation](https://backstage.io/docs/integrations/github/github-apps)
1. Start testing environment.
   This repository should work with either `docker compose` using Docker Engine or `podman-compose` using Podman. When using Podman there are some exceptions. Check [Known Issues when using Podman Compose](#known-issues-when-using-podman-compose) for more info.

   If you prefer  `docker compose` you can just replace `podman-compose` with `docker compose`

   ```sh
   podman-compose up -d
   ```

## Updating configuration

When you change `app-config.local.yaml` you can just restart `rhdh` to load RHDH with new configuration.

```sh
podman-compose stop rhdh && podman-compose start rhdh
```

When you change `dynamic-plugins.yaml` you need to re-run `install-dynamic-plugins` container and than restart RHDH instance.

```sh
podman-compose run install-dynamic-plugins
podman-compose stop rhdh && podman-compose start rhdh
```

## Cleanup

To tear down the environment to start next time fresh

```
podman-compose down --volumes
```

### Known Issues when using Podman Compose

Works with `podman-compose` only with image that include this following fix https://github.com/janus-idp/backstage-showcase/pull/1585

Older images doesn't work in combination with  `podman-compose`.
This is due to https://issues.redhat.com/browse/RHIDP-3939. RHDH images currently populate dynamic-plugins-root directory with all plugins that are  packaged inside the image.
Before podman mounts volume over `dynamic-plugins-root` directory it copies all existing files into the volume. When the plugins are installed using `install-dynamic-plugins.sh` script it create duplicate installations of some plugins, this situation than prevents Backstage to start.

This also doesn't work with `podman compose` when using `docker-compose` as external compose provider on MacOs
It fails with
```
install-dynamic-plugins-1  | Traceback (most recent call last):
install-dynamic-plugins-1  |   File "/opt/app-root/src/install-dynamic-plugins.py", line 429, in <module>
install-dynamic-plugins-1  |     main()
install-dynamic-plugins-1  |   File "/opt/app-root/src/install-dynamic-plugins.py", line 206, in main
install-dynamic-plugins-1  |     with open(dynamicPluginsFile, 'r') as file:
install-dynamic-plugins-1  | PermissionError: [Errno 13] Permission denied: 'dynamic-plugins.yaml'
```
It looks like docker-compose when used with podman doesn't correctly propagete `Z` SElinux label.