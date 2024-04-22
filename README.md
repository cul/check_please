# "Check Please"

DLST app for performing fixity checks on cloud storage files.


**First-Time Setup (for developers)**
Clone the repository.
`git clone git@github.com:cul/check_please.git`

Install gem dependencies.
`bundle install`

Set up config files.
`bundle exec rake check_please:setup:config_files`

Run database migrations.
`bundle exec rake db:migrate`

Seed the database with necessary values for operation.
`rails db:seed`

Start the application using `rails server`.
`rails s -p 3000`
