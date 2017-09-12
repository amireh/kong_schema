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
The supported "directives" are described later in this document.

For now we'll assume we have such a config file:

```yaml
# file: config/kong.yml
kong:
  admin_host: localhost:8001
  apis:
    - name: application-api
      hosts:
        - api.application.dev
      upstream_url: http://application-api-lb
      uris:
        - /api/.+
        - /auth/.+
      preserve_host: true
  upstreams:
    - name: application-api-lb
  targets:
    - upstream_id: application-api-lb
      target:      127.0.0.1:3000
```

Then if we run the following command:

```shell
bundle exec kong_schema up -c config/kong.yml --key "kong"
```

kong_schema will read the directives found under the `kong` dictionary and
prompt you with a list of changes it will apply to Kong through the REST API.

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

### `admin_host: String`

### `apis: Array<Kong::Api>`

[Kong::Api](https://getkong.org/docs/0.11.x/admin-api/#add-api) configuration:

- name: String
- host: String
- upstream_url: String
- uris: Array<String>
- preserve_host: Boolean

### `upstreams: Array<Kong::Upstream>`

[Kong::Upstream](https://getkong.org/docs/0.11.x/admin-api/#add-upstream)
configuration:

- name: String
- ?slots: Number
- ?orderlist: Array<Number>

### `targets: Array<Kong::Target>`

[Kong::Target](https://getkong.org/docs/0.11.x/admin-api/#add-target)
configuration:

- upstream_id: String
- target: String
- ?weight: Number

## TODO

Add support for the remaining Kong API objects:

- [consumers](https://getkong.org/docs/0.11.x/admin-api/#create-consumer)
- [plugins](https://getkong.org/docs/0.11.x/admin-api/#add-plugin)
- [certificates](https://getkong.org/docs/0.11.x/admin-api/#add-certificate)
- [snis](https://getkong.org/docs/0.11.x/admin-api/#add-sni)

## License

Copyright (C) 2017 Instructure, INC.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see http://www.gnu.org/licenses/.