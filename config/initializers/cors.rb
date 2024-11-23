# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins  "http://localhost:4200"
#     resource "*",
#       headers: :any,
#       methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
#       credentials: true,
#       expose: [ "Authorization" ]
#   end
# end
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://instascribe.revcat.cloud", "http://34.72.37.133:8006", "https://www.instascribe.revcat.cloud"
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ["Authorization"]
  end
end
