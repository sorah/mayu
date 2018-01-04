# Mayu: Rack app to locate employees in an office by Wi-Fi MAC address and WLC association data

__UNDER DEVELOPMENT, just API works__

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mayu'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mayu

## Set up

### Components

1. Associaton collector: Collecting pair of MAC address => AP name
2. User collector: Collecting pair of MAC address => user information
3. Frontend: Web API and Frontend

This gem includes (1) for Cisco WLC and (3). About (2), you have to write your own script to generate JSON.

All data is stored in Amazon S3.

### Running associaton collector

```
bundle exec mayu-association-collector
```

- `--interval` (default: 60, env: `$MAYU_ASSOC_INTERVAL`): Interval in seconds to run updating.
- `--ttl` (default: 300, env: `$MAYU_ASSOC_TTL`): seconds to remove disappeared devices from list.
- `--wlc` (required, env: `$MAYU_ASSOC_WLC`): Address of WLC for SNMP communication
- `--community` (required, env: `$MAYU_ASSOC_WLC_COMMUNITY`): SNMP community of WLC
- `--use-ap-mac-for-key` (env: `$MAYU_ASSOC_AP_MAC_KEY`): Use MAC address of AP for identifying APs, instead of its name
- `--use-wlc-user` (env: `$MAYU_ASSOC_USE_WLC_USER`): Use username assigned by WLC for identifying user
- Choose either:
  - File:
    - `--output` (required, env: `$MAYU_ASSOC_FILE`)
  - S3:
    - `--s3-region` (required, env: `$MAYU_ASSOC_S3_REGION`)
    - `--s3-bucket` (required, env: `$MAYU_ASSOC_S3_BUCKET`)
    - `--s3-key` (required, env: `$MAYU_ASSOC_S3_KEY`)

### Running user collector

Write your own logic to collect your employees' device MAC addresses.

See [Internal](#internal) and place a properly formatted JSON file in S3.

### Running web frontend

```
bundle exec rackup
```

Run as a Rack app. Refer the bundled [config.ru](./config.ru)

The bundled config.ru accepts:

- `$MAYU_WEB_RELOAD_INTERVAL` (default: 60)
- `$MAYU_ASSOC_S3_REGION`
- `$MAYU_ASSOC_S3_BUCKET`
- `$MAYU_ASSOC_S3_KEY`
- `$MAYU_USER_S3_REGION`
- `$MAYU_USER_S3_BUCKET`
- `$MAYU_USER_S3_KEY`

Also, this app needs a list of APs for displaying a map.

- `$MAYU_AP_S3_REGION`
- `$MAYU_AP_S3_BUCKET`
- `$MAYU_AP_S3_KEY`

This JSON file should be formatted with a format in [Internal](#internal)

## Internal

### Formats

- All datetimes in a JSON should be formatted in ISO8601.
- MAC addresses should be formatted like `00:00:5e:00:53:a1` (hex, `:` separated, all lower case)

#### Association

``` json
{
  "associations": [
    {
      "mac": "DEVICE_MAC",
      "user_key": "USER",
      "ap_key": "AP_KEY",
      "updated_at": "UPDATED_AT",
      "appeared_at": "APPEARED_AT",
      "disappeared_at": "DISAPPEARED_AT"
    }
  ]
}
```

- `DEVICE_MAC`: MAC address
- `USER` (optional): User key, if a user is determinable by an association. Otherwise user will be looked up from device MAC.
- `AP_KEY`: AP key (name, MAC address or anything. Key should be consistent among all other JSON files)
- `UPDATED_AT`: Time that this association updated.
- `APPEARED_AT`: Time that this association appeared.
- `DISAPPEARED_AT` (optional): Time that this association disappeared.

#### Users

``` json
{
  "users": [
    {
      "key": "KEY",
      "name": "NAME",
      "aliases": ["ALIAS"],
      "gravatar_email": "GRAVATAR_EMAIL"
    }
  ],
  "devices": [
    {
      "user_key": "USER_KEY",
      "key": "DEVICE_KEY",
      "mac": "DEVICE_MAC",
      "kind": "DEVICE_KIND"
    }
  ]
}
```

- `KEY`: Key (should be consistent among all other JSONs)
- `NAME`: Name
- `ALIAS` (optional): Alias (username, email, etc)
- `GRAVATAR_EMAIL` (optional): Gravatar email
- `DEVICE_MAC`: Device Wi-Fi MAC address that user owns.
- `DEVICE_KIND` (default: `other`): Kind of device (`pc`, `phone`, `tablet`, `other`)

#### APs

``` json
{
  "maps": {
    "MAP_KEY": {
      "name": "MAP_NAME",
      "url": "MAP_IMAGE_URL",
      "fg_color": "HI_COLOR",
      "bg_color": "HI_COLOR",
      "highlight_color": "HI_COLOR"
    }
  },
  "aps": {
    "AP_KEY": {
      "name": "AP_NAME",
      "description": "AP_DESCRIPTION",
      "map_key": "AP_MAP_KEY",
      "map_x": "AP_MAP_X",
      "map_y": "AP_MAP_Y"
    }
  }
}
```

- `MAP_KEY`: Key of map (should be consistent among other JSON files)
- `MAP_NAME`: Name of map (Floor name, etc)
- `MAP_IMAGE_URL`: Image URL
- `MAP_HI_COLOR`: Color for highlighting
- `AP_KEY`: AP key
- `AP_NAME`: Name of AP
- `AP_DESCRIPTION`: Description of AP (location information for human, etc)
- `AP_MAP_KEY`: Map corresponding for AP
- `AP_MAP_X`: X position of AP in map
- `AP_MAP_Y`: Y position of AP in map

### Relations

- user
  - devices
    - association
- association
  - ap
  - device
- map
  - aps
    - associations

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sorah/mayu.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
