# kong_schema

Configure [Kong](https://getkong.org) using YAML or JSON source files.

This package is intended for use by programmers in development environments and
may not be optimal for admins since it does not attempt to expose the full
power of Kong's REST API.

Use of this package requires no knowledge of [Kong's REST
API](https://getkong.org/docs/0.11.x/admin-api/) - it is meant to abstract it
away from the user.

## Installation

The package requires a recent version of Ruby.

```shell
gem install kong_schema
```

If you're using Bundler, add it to your Gemfile instead:

```ruby
group :development do
  gem 'kong_schema'
end
```

## Usage

Write your desired configuration for Kong in a file using either YAML or JSON.
The supported "directives" are described later in this document. Then you can
use the `kong_schema` binary to perform various actions.

Run `kong_schema --help` to see the available commands.

```shell
# apply configuration
kong_schema up [path/to/config.yml]

# reset configuration
kong_schema down [path/to/config.yml]
```

## Example

Let's assume we have such a config file:

```yaml
# file: config/kong.yml
kong:
  admin_host: localhost:8001
  apis:
    - name: application-api
      hosts:
        - api.application.dev
      preserve_host: true
      strip_uri: false
      upstream_url: http://application-api-lb
      uris:
        - /api/.+
        - /auth/.+
  upstreams:
    - name: application-api-lb
  targets:
    - upstream_id: application-api-lb
      target:      127.0.0.1:3000
```

Then if we run the following command:

```shell
kong_schema up config/kong.yml
```

kong_schema will read the directives ("schema") found in the `kong` dictionary
and prompt you with a list of changes it will apply to Kong through the REST
API.

```shell
+-----------------+------------------------------------------------+
| Change          | Parameters                                     |
+-----------------+------------------------------------------------+
| Create Api      | {                                              |
|                 |   "name": "application-api",                   |
|                 |   "hosts": [                                   |
|                 |     "api.application.dev"                      |
|                 |   ],                                           |
|                 |   "upstream_url": "http://application-api-lb", |
|                 |   "uris": [                                    |
|                 |     "/api/.+",                                 |
|                 |     "/auth/.+"                                 |
|                 |   ],                                           |
|                 |   "preserve_host": true                        |
|                 | }                                              |
| Create Upstream | {                                              |
|                 |   "name": "application-api-lb"                 |
|                 | }                                              |
| Create Target   | {                                              |
|                 |   "upstream_id": "application-api-lb",         |
|                 |   "target": "127.0.0.1:3000"                   |
|                 | }                                              |
+-----------------+------------------------------------------------+
Commit the changes to Kong? (y/N) 
```

If you agree and everything goes well, you should see an affirmative message:

```
✓ Kong has been reconfigured!
```

Running the command again should report that there are no changes to reflect:

```
✓ Nothing to update.
```

But if you _do_ change something it will result in an "update" operation and present you with the changes it perceives to have been made.

Let's add another `uri` to our API:

```yaml
# file: config/kong.yml
# ...
  apis:
    - name: application-api
      hosts:
        - api.application.dev
      upstream_url: http://application-api-lb
      uris:
        - /api/.+
        - /auth/.+
        - /oauth2/.+
```

And re-run `kong_schema up` as we did before:

```shell
+------------+-------------------------------------------------+
| Change     | Parameters                                      |
+------------+-------------------------------------------------+
| Update Api |  {                                              |
|            |    "name": "application-api",                   |
|            |    "hosts": [                                   |
|            |      "api.application.dev"                      |
|            |    ],                                           |
|            |    "upstream_url": "http://application-api-lb", |
|            |    "uris": [                                    |
|            |      "/api/.+",                                 |
|            | -    "/auth/.+"                                 |
|            | +    "/auth/.+",                                |
|            | +    "/oauth2/.+"                               |
|            |    ],                                           |
|            |    "preserve_host": true                        |
|            |  }                                              |
+------------+-------------------------------------------------+
```

Nice and easy!

## Configuration

As mentioned before, you can either use YAML or JSON to write your
configuration files. YAML tends to be more readable and easier to edit.
`kong_schema` will know which parser to use based on the file extension; they
have to end with either `.yml` or `.json` respectively.

For further convenience, the CLIs support reading the schema from a specific
"key" in that configuration file, which by default is set to `"kong"`. This
allows you to keep your Kong schema alongside other configuration items for
your application(s) in a single file.

If your Kong schema is the root property, just pass `--key ""` to CLI commands
to make them read the whole file as the schema.

### `admin_host: String`

Address at which Kong Admin is listening, like `127.0.0.1:9712`. This is the
value you specify in `admin_listen` of `kong.conf`.

### `apis: Array<Kong::Api>`

[Kong::Api](https://getkong.org/docs/0.11.x/admin-api/#add-api) configuration.

**Properties**

- name: String
- host: String
- methods: Array<String>
- preserve_host: Boolean
- strip_uri: Boolean
- upstream_url: String
- uris: Array<String>

### `plugins: Array<Kong::Plugin>`

[Kong::Plugin](https://getkong.org/docs/0.11.x/admin-api/#add-plugin) configuration.

Setting `enabled: false` will delete the plugin.

**Properties**

- name: String
- enabled: Boolean
- api_id: String
- config: Object
- consumer_id: String

### `upstreams: Array<Kong::Upstream>`

[Kong::Upstream](https://getkong.org/docs/0.11.x/admin-api/#add-upstream)
configuration.

**Properties**

- name: String
- slots: Number
- orderlist: Array<Number>

### `targets: Array<Kong::Target>`

[Kong::Target](https://getkong.org/docs/0.11.x/admin-api/#add-target)
configuration.

**Properties**

- upstream_id: String
- target: String
- weight: Number

## TODO

Add support for the remaining Kong API objects:

- [consumers](https://getkong.org/docs/0.11.x/admin-api/#create-consumer)
- [certificates](https://getkong.org/docs/0.11.x/admin-api/#add-certificate)
- [snis](https://getkong.org/docs/0.11.x/admin-api/#add-sni)

## Gotchas

Beware of removing keys that were previously defined in your configuration.
`kong_schema` does not know the default values of options nor does it attempt
to assign them, so when you omit an option that was previously defined, it can
not detect that change and it will not be reflected in the API.

This symptom may be addressed in the future by changing the implementation so
that it wipes out Kong's configuration before each application (e.g.
`kong_schema up`) but for now you have two options to deal with this:

1) Reset the database prior to applying the schema:

```shell
kong_schema down [file] # database reset
kong_schema up [file]   # database now 100% reflecting config file
```

2) Set the values to `null` or an empty property. For example, if we were to no
   longer use the `hosts` property of an Api object, we'd just clear it instead
   of omitting it:

```yaml
kong:
  apis:
    - name: some-api
      # just clear this, don't omit it
      hosts:
```

## Tests

**WARNING: RUNNING THE TESTS WILL CLEAR THE KONG DATABASE!!!**

A running Kong instance is required to run the tests. By default the admin API
is expected to be running on `127.0.0.1:9712` but you can change that by 
setting the environment variable `KONG_URI`.

Then running the tests is as simple as:

    COVERAGE=1 bundle exec rspec

## License

Copyright (C) 2017 Instructure, INC.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see http://www.gnu.org/licenses/.