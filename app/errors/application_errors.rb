class AuthorizationError < StandardError; end
class NotFoundError < StandardError; end
class ValidationError < StandardError
  attr_reader :errors

  def initialize(errors)
    @errors = errors
    super('Validation failed')
  end
end
