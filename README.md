# letsencrypt-service

Docker image that creates [Let's Encrypt][2] certificates and checks them
daily. Implemented using [dehydrated][1] with [lexicon][3] for DNS
verification.

### Environment

* `STAGING`: If `true`, use the letsencrypt staging endpoints.
* `LEXICON_ENV`: The path to the environment file containing [lexicon][3]
  secrets. Default: `/run/secrets/lexicon_env`
* `OUTDIR`: The path to the output directory for certificates. Default:
  `/etc/ssl/private`

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

[1]: https://dehydrated.io/
[2]: https://letsencrypt.org/
[3]: https://github.com/AnalogJ/lexicon
[4]: https://github.com/dehydrated-io/dehydrated/blob/master/docs/domains_txt.md
[5]: https://github.com/AnalogJ/lexicon#environmental-variables
