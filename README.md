# Kashing

Simple Forex monitoring in a small bash script (`kashing.sh`).

Queries [1Forge](https://1forge.com) every 5min (defined in `cron/root`) for prices on currency pairs defined in `FOREX` (env var) and alerts you by SMS and/or email when the price is smaller or higher than your min/max values defined in `FOREX` (env var).

Supports the currency pairs defined in `supportedCurrencyPairs.txt`.

## Env vars
`FOREX` (required) - Contains the currency pairs, min and max price values in the following pattern:
- `<currencyPair>|<minVal>|<maxVal>`
  - e.g. single pair: `GBPEUR|1.115|1.150`
  - e.g. multiple pairs: `GBPEUR|1.115|1.150;AUDUSD|0.60|0.95`

`ONEFORGE_API_KEY` (required) - [1Forge](https://1forge.com) API Key

For SMS alerts (optional):
<br>`NEXMO_API_KEY` - [Nexmo](https://www.nexmo.com/) API Key
<br>`NEXMO_API_SECRET` - [Nexmo](https://www.nexmo.com/) API Secret
<br>`PHONE_NO` - Your phone number. Format is `<countryCode><phone number excluding 0>` (e.g. `447712345678`)

For email alerts (optional):
<br>`SENDGRID_KEY` - [SendGrid](https://sendgrid.com) API Key
<br>`EMAIL` - Your email address

## Run

```
docker run -d -e FOREX="GBPEUR|1.115|1.150" \
  -e ONEFORGE_API_KEY="<API_KEY>" \
  -e NEXMO_API_KEY="<API_KEY>" \
  -e NEXMO_API_SECRET="<API_SECRET>" \
  -e PHONE_NO="<PHONE_NO>" \
  -e SENDGRID_KEY="<API_KEY>" \
  -e EMAIL="<EMAIL>" \
  adrianchifor/kashing
```

## License

Copyright &copy; 2017 Adrian Chifor

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
