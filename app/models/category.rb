class Category < ApplicationRecord
  include HasExternalId
  belongs_to :parent, class_name: 'Category', optional: true
  has_many   :children, class_name: 'Category', foreign_key: :parent_id, dependent: :nullify
  has_many   :categorizations, dependent: :destroy

  enum facet: {
    domain:    0,   # Windchill, Creo, Arena, SAP, General PLM
    format:    1,   # conference, user group, training, meetup, trade show, convention
    geography: 2,   # Pacific Northwest, Virtual, International
    fandom:    3,   # anime, gaming, comic, pop culture
    audience:  4    # engineers, managers, IT, executives, other
  }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :facet, presence: true
  validate  :parent_must_share_facet
  validate  :no_deep_nesting

  scope :active,      -> { where(active: true) }
  scope :roots,       -> { where(parent_id: nil) }
  scope :ordered,     -> { order(:position, :name) }
  scope :for_facet,   ->(f) { where(facet: f) }

  before_validation :generate_slug

  def full_name
    parent ? "#{parent.name} > #{name}" : name
  end

  def root?
    parent_id.nil?
  end

  # For select dropdowns — grouped by facet
  def self.grouped_for_select
    active.ordered.group_by(&:facet).transform_values do |cats|
      cats.map { |c| [c.full_name, c.id] }
    end
  end

  private

  def generate_slug
    return if slug.present?
    base = name.to_s.parameterize
    base = "#{parent.slug}-#{base}" if parent.present?
    candidate = base
    n = 2
    while Category.where(slug: candidate).where.not(id: id).exists?
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end

  def parent_must_share_facet
    return unless parent.present?
    unless parent.facet == facet
      errors.add(:parent, 'must belong to the same facet')
    end
  end

  def no_deep_nesting
    return unless parent.present?
    if parent.parent_id.present?
      errors.add(:parent, 'only one level of hierarchy is supported')
    end
  end
end
