Factory.define :api_request do |f|
  f.association :api_key
  f.url "users"
  f.status "200"
  f.ip "127.0.0.1"
  f.api_version 1
end