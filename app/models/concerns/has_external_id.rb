module HasExternalId
  extend ActiveSupport::Concern

  included do
    before_create :assign_external_id
  end

  private

  def assign_external_id
    self.external_id ||= SecureRandom.uuid
  end
end
