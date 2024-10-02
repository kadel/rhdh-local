# Test Red Hat Developer Hub locally

Welcome to RHDH local - the simplest way to run red Hat Developer Hub on your PC.

RHDH local is ideal for trying some basic features of RHDH (like Software Catalogs or TechDocs) but it's also great for testing dynamic plugins and their configuration settings.

RHDH is not a substitute for red Hat Developer Hub. It's designed for individuals to test with. It's not designed to scale and it's not suitable for use by teams.

## What You'll Need Before You Get Started

To use RHDH Local you'll need a few things:

1. A PC based on an x86 (AMD64) architecture
1. Docker or Podman installed with adequate resources available
1. An internet connection for downloading container images, plugins, etc.
1. (Optional) A GitHub account if you want to integrate GitHub
1. (Optional) The node `npx` tool if you intend to use GitHub authentication 

## Getting Started With RHDH Local

1. Clone this repository to a location on your PC

   ```sh
   git clone https://github.com/kadel/rhdh-local.git
   ```

1. Move to the `rhdh-local` folder.

   ```sh
   cd rhdh-local
   ```

1. Create your own local `.env` file by using a copy of the `env.sample` provided.

   ```sh
   cp env.sample .env
   ```

   In most cases, when you you don't need GitHub Auth or testing different releases you
   can leave it as it is and it should work.

1. (Optional) Update `configs/app-config.local.yaml`.
   If you need fetching files form from GitHub you should configure `integrations.github`.
   The recommended way is to use GitHub Apps. You can find hints on how to configure it in [github-app-credentials.example.yaml](configs/github-app-credentials.example.yaml) or mode detailed instruction in [Backstage documentation](https://backstage.io/docs/integrations/github/github-apps).

1. Start RHDH Local.
   This repository should work with either `docker compose` using Docker Engine or `podman-compose` using Podman. When using Podman there are some exceptions. Check [Known Issues when using Podman Compose](#known-issues-when-using-podman-compose) for more info.

   ```sh
   podman-compose up -d
   ```

   If you prefer `docker compose` you can just replace `podman-compose` with `docker compose`

   ```sh
   docker compose up -d
   ```

## Changing Your Configuration

When you change `app-config.local.yaml` you can just restart `rhdh` to load RHDH with new configuration.

```sh
podman-compose stop rhdh && podman-compose start rhdh
```

When you change `dynamic-plugins.yaml` you need to re-run `install-dynamic-plugins` container and than restart RHDH instance.

```sh
podman-compose run install-dynamic-plugins
podman-compose stop rhdh && podman-compose start rhdh
```

## Loading dynamic plugins from a local directory

The `local-plugins` directory is mounted into the `install-dynamic-plugins` container into `/opt/app-root/src/local-plugins`.
You can leverage this install dynamic plugins from your local machine.

1. Copy the dynamic plugin binary file into the `local-plugins` directory.
2. Make sure that the permissions are set to allow container to read files (quick and dirty solution is `chmod -R 777 local-plugins`)
3. Configure your dynamic plugin in `dynamic-plugins.yaml`. See commented out examples in that file for examples.
4. See [Changing Your Configuration](#changing-your-configuration) section for more information about how to change and load new configuration.


## Cleanup

To reset RHDH Local you can use the following command. this will clean up any attached volumes, but your configuration changes will remain.

```sh
podman-compose down --volumes
```

To reset everything, including any configuration changes you've made you could try:

```sh
git reset --hard
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

## Using PostgreSQL database

By default in-memory db is used.
If you want to use PostgreSQL with RHDH, here are the steps:

1. Uncomment the `db` service block in [compose.yaml](compose.yaml) file

   ```yaml
   db:
      image: "registry.access.redhat.com/rhel8/postgresql-16:latest"
      volumes:
         - "/var/lib/pgsql/data"
      env_file:
         - path: "./.env"
            required: true
      environment:
         - POSTGRESQL_ADMIN_PASSWORD=${POSTGRES_PASSWORD}
      healthcheck:
         test: ["CMD", "pg_isready", "-U", "postgres"]
         interval: 5s
         timeout: 5s
         retries: 5
   ```

2. Uncomment the `db` section in the `depends_on` section of `rhdh` service in [compose.yaml](compose.yaml)

   ```yaml
   depends_on:
      install-dynamic-plugins:
         condition: service_completed_successfully
      db:
         condition: service_healthy
   ```

3. Comment out the SQLite in-memory configuration in [`app-config.local.yaml`](configs/app-config.local.yaml)

   ```yaml
   # database:
   #   client: better-sqlite3
   #   connection: ':memory:'
   ```
