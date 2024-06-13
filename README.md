# "Check Please"

DLST app for performing fixity checks on cloud storage files.

## Development

### First-Time Setup

Clone the repository.
`git clone git@github.com:cul/check_please.git`

Install gem dependencies.
`bundle install`

Set up config files.
`bundle exec rake check_please:setup:config_files`

Run database migrations.
`bundle exec rake db:migrate`

Start the application using `bundle exec rails server`.
`bundle exec rails s -p 3000`

## Testing

Run: `bundle exec rspec`

## Deployment

Run: `bundle exec cap [env] deploy`

NOTE: Only the `dev` environment deploy target is fully set up at this time.
