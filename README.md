# letsencrypt-service

Docker image that creates [Let's Encrypt][2] certificates and checks them
daily. Implemented using [dehydrated][1] with [lexicon][3] for DNS
verification.

### Environment

* `STAGING`: If `true`, use the letsencrypt staging endpoints.
* `LEXICON_ENV`: The path to the environment file containing [lexicon][3]
  secrets. Default: `/run/secrets/lexicon_env`
* `BASEDIR`: The path to the dehydrated working directory. Default:
  `/var/lib/dehydrated`
* `OUTDIR`: The path to the output directory for certificates. Default:
  `/etc/ssl/private`

### Volumes

In swarm mode, these volumes should not be shared across nodes. See the
[FAQ](#what-is-the-recommended-service-configuration).

* `/var/lib/dehydrated` (`$BASEDIR`)

  Ensures Let's Encrypt accounts and CA chains are maintained across
  containers.

* `/etc/ssl/private` (`$OUTDIR`):

  Contains the produced certificates and private keys. As certificates approach
  expiration, new ones will be generated. The active certificate and key will
  always be symlinked to:

  ```bash
  /etc/ssl/private/$cert/fullchain.pem
  /etc/ssl/private/$cert/privkey.pem
  ```

### Lexicon Secrets

The file pointed at by `$LEXICON_ENV` variable must define (and export) the
[environment variables][5] needed for authenticating with your DNS provider.
For example:

```bash
export PROVIDER=cloudflare
export LEXICON_CLOUDFLARE_USERNAME=...
export LEXICON_CLOUDFLARE_TOKEN=...
```

### Certificates

#### Via domains.txt

If you prefer to provide your own [domains.txt][4] file, copy or mount it into
`/etc/dehydrated/domains.txt`. If that file exists, it is used, otherwise
certificates must be configured by environment variables.

#### Via Environment Variables

Each certificate must be given an alias, which will used as the subdirectory
under `$OUTDIR`. The list of aliases goes in the `$CERTS` environment variable:

```bash
CERTS='mail www'
```

This will produce two certificates, stored in `$OUTDIR/mail/` and
`$OUTDIR/www/`. Use environment variables prefixed with `DOMAIN_` to declare
the primary hostname for each certificate alias:

```bash
DOMAIN_mail='mail.example.com'
DOMAIN_www='example.com'
```

Use environment variables prefixed with `ALTS_` to declare alternate hostnames
as needed:

```bash
ALTS_www='www.example.com www2.example.com'
```

*Note:* Because the `$DOMAIN_xxx` environment variable is required, the
certificate alias _must not_ contain characters that are invalid in environment
variable names.

## FAQ

### How do I use the hostname of my swarm node in my certificate?

Because environment variables allow [Go templates][6], your
`docker-compose.yml` can pass in the node hostname to the container:

```yaml
    environment:
      CERTS: mx
      DOMAIN_mx: {{ .Node.Hostname }}.example.com
      ALTS_mx: mx1.example.com mx2.example.com
```

### What is the recommended service configuration?

This service should run in `global` mode, so that each swarm node produces its
own certificates and private keys. Additionally, in case of failure, it's best
to delay restart on failure to avoid hammering ACME services. Here is a good
starting point:

```yaml
    deploy:
      mode: global
      restart_policy:
        delay: 10m
```

The `$LEXICON_ENV` file, which defaults to `/run/secrets/lexicon_env`, is
designed to be used with a docker secret configuration:

```yaml
    secrets:
      - lexicon_env

# later in the file
secrets:
  lexicon_env:
    file: $HOME/.docker-secrets/lexicon.env
```

[1]: https://dehydrated.io/
[2]: https://letsencrypt.org/
[3]: https://github.com/AnalogJ/lexicon
[4]: https://github.com/dehydrated-io/dehydrated/blob/master/docs/domains_txt.md
[5]: https://github.com/AnalogJ/lexicon#environmental-variables
[6]: //docs.docker.com/engine/reference/commandline/service_create/#create-services-using-templates
