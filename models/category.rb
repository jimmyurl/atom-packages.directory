# A Category can have packages associated via PackageCateorisations and through keywords
class Category
  include NoBrainer::Document
  include Permalink

  field :name,
        index: true,
        uniq: true,
        required: true

  field :description

  field :permalink,
        index: true,
        required: true,
        uniq: true

  field :packages_count,
        index: true,
        required: true,
        default: 0

  field :sub_categories_count,
        index: true,
        required: true,
        default: 0

  has_many :package_categorisations
  has_many :packages, through: :package_categorisations

  belongs_to :parent_category, class_name: Category
  has_many :sub_categories, class_name: Category, foreign_key: :parent_category_id

  before_validation do
    uniq_permalink_from(read_attribute(:name))
  end

  after_save do
    parent_category.update_counts if parent_category
  end

  scope :top, lambda {
    where(:parent_category.undefined => true)
      .where(:sub_categories_count.gt => 0)
  }

  def update_counts
    update(
      packages_count: packages.count,
      sub_categories_count: sub_categories.count
    )
  end

  def merge(other_category)
    Category.where(parent_category_id: other_category.id).update_all(parent_category_id: id)
    PackageCategorisation.where(category_id: other_category.id).update_all(category_id: id)
    other_category.destroy
  end
end
