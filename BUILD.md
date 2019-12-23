`git clone https://github.com/huginn/huginn.git`

`bundle install`

An error occurred while installing mini_racer (0.2.4)
`gem uninstall libv8`

An error occurred while installing mysql2 (0.5.2)
`apt-get install libmysqlclient-dev`

Create DB user and specify `huginn_development` as password
```
sudo su postgres
createuser -dlP huginn_development
```

Get the secret
`rake secret`

Copy `.env.example` to `.env` and update:
* `DATABASE_ADAPTER` with `postgresql`
* `APP_SECRET_TOKEN` with what was returned by `rake secret`
* `DATABASE_USERNAME` with `huginn_development`
* `DATABASE_PASSWORD` with `huginn_development`
* `DATABASE_HOST` with `localhost`

Run `rake db:create db:migrate db:seed`

Run `gem install huginn_agent`
