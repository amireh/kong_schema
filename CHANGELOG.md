## 1.3.5

- Fixed an issue that caused the reporter to fail when an Api object's
  "methods" attribute was an array and not a comma-delimited string

## 1.3.4

- Fixed an issue that was causing Api objects to appear empty in a diff when in
  fact there were changed attributes
- Fixed another issue in reporting diffs of Api objects where the "methods"
  property was reported to be changed when in fact, it won't

## 1.3.3

- Fixing bad release 1.3.2 ...

## 1.3.2

- Fixed missing dependency on "json" in gemspec

## 1.3.1

- Fixed an issue that was preventing Kong::Plugin objects from being created
  without an api

## 1.3.0

- Added support for Kong::Plugin objects.
- Renamed the CLI command `kong_schema reset` to `kong_schema down` for
  consistency.
- All CLI commands now accept `-c` or `--config` to point to the config file in
  place of the first argument. This makes it consistent with Kong's binaries
  for user convenience.

## 1.2.0

- Added a new CLI command: `kong_schema reset` for wiping out the Kong database
  (still through its API)

## 1.1.1

- Fixed an issue assigning the "methods" attribute of Kong::Api objects
- Empty array values (like "hosts" and "methods") will no longer display
  as having changed if their API value is "null"
- CLI command `kong_schema up` will now print an error message if the required
  argument was not passed

## 1.1.0

- Added a CLI binary: `kong_schema`

## 1.0.1

- Fixed a bug where an empty array of "hosts", "uris", or "methods" in "apis"
  would raise an exception.
- An error will now be raised if `admin_host` is not defined in config (and a
  connection to Kong admin can not be established)

## 1.0.0

Initial release with support for the following Kong objects:

- [Apis](https://getkong.org/docs/0.11.x/admin-api/#add-api)
- [Upstreams](https://getkong.org/docs/0.11.x/admin-api/#add-upstream)
- [Targets](https://getkong.org/docs/0.11.x/admin-api/#add-target)
