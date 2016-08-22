class NoModelError < RuntimeError
  def initialize
    super 'No model was specified'
  end
end
