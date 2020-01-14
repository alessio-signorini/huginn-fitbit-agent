# Create events from Fitbit activities

OAUTHv2 client and secret can be specified in the configuration of the
  agent or globally using `ENV['FITBIT_OAUTH2_CLIENT']` and
  `ENV['FITBIT_OAUTH2_SECRET']`.

The agent will remember some (`loopback`=50) activities so it can update
  them instead of creating new ones.

Refer to [this page](https://dev.fitbit.com/build/reference/web-api/activity/#get-activity-logs-list)
  for a list of properties of the events created.

After the agent is created go into its description to complete the OAUTHv2
  flow and authorize it to read your Fitbit data.
