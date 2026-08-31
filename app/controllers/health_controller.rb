class HealthController < ActionController::API
  def show
    render json: { status: 'ok', service: 'moto_ride_tracking' }
  end
end
