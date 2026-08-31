class Rack::Attack
  throttle('api/locations', limit: 120, period: 60) do |req|
    req.ip if req.path =~ %r{/api/v1/rides/[^/]+/locations} && req.post?
  end

  throttle('api/general', limit: 300, period: 60) do |req|
    req.env['HTTP_AUTHORIZATION'].presence || req.ip if req.path.start_with?('/api/')
  end

  self.throttled_responder = lambda do |_env|
    [429, { 'Content-Type' => 'application/json' },
     [{ error: 'Too many requests', retry_after: 60 }.to_json]]
  end
end
