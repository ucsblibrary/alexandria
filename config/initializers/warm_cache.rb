if Rails.env.production?
  AdminPolicy.ensure_admin_policy_exists
  AdminPolicy.all
end
