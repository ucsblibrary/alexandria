if Rails.env.production?
  Rails.logger.info "Warming the cache"
  AdminPolicy.all
end
