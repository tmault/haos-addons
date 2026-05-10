# Dashy Latest

Runs Dashy inside Home Assistant OS using the current public
`lissy93/dashy:latest` Docker image.

The add-on stores Dashy's `conf.yml` and related user assets in the Home
Assistant add-on config directory. On first start, it copies Dashy's bundled
default `conf.yml` if no config exists yet.

## Ports

The default host port is `8080`.

## Updating Dashy

Because this wrapper builds from `lissy93/dashy:latest`, rebuild the add-on when
you want to pull the current Dashy image:

```shell
ha apps rebuild <addon_slug>
```

For an installed repository add-on, use the slug shown by Home Assistant.
