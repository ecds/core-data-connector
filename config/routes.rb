require_relative 'routes/admin'
require_relative 'routes/public/v1'

CoreDataConnector::Engine.routes.draw do
  mount JwtAuth::Engine => '/auth'

  extend Admin
  extend Public::V1
end
