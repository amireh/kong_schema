# 1.0.1

- Fixed a bug where an empty array of "hosts", "uris", or "methods" in "apis"
  would raise an exception.
- An error will now be raised if `admin_host` is not defined in config (and a
  connection to Kong admin can not be established)

# 1.0.0

Initial release with support for the following Kong objects:

- [Apis](https://getkong.org/docs/0.11.x/admin-api/#add-api)
- [Upstreams](https://getkong.org/docs/0.11.x/admin-api/#add-upstream)
- [Targets](https://getkong.org/docs/0.11.x/admin-api/#add-target)