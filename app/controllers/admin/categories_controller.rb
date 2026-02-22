class Admin::CategoriesController < Admin::BaseController
  before_action :ensure_super_admin!
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
    @categories_by_facet = Category.active
                                   .includes(:parent, :children)
                                   .ordered
                                   .group_by(&:facet)
  end

  def new
    @category = Category.new
    @category.facet = params[:facet] if params[:facet].present?
    @parents = parent_options_for(@category)
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to admin_categories_path, notice: "#{@category.full_name} created."
    else
      @parents = parent_options_for(@category)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @parents = parent_options_for(@category)
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: "#{@category.full_name} updated."
    else
      @parents = parent_options_for(@category)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.children.any?
      redirect_to admin_categories_path,
                  alert: "Cannot delete #{@category.name} — it has subcategories."
    elsif @category.categorizations.any?
      @category.update!(active: false)
      redirect_to admin_categories_path,
                  notice: "#{@category.name} deactivated (in use by #{@category.categorizations.count} records)."
    else
      @category.destroy
      redirect_to admin_categories_path, notice: "#{@category.name} deleted."
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :slug, :facet, :parent_id, :description, :position, :active)
  end

  def parent_options_for(category)
    return [] unless category.facet.present?
    Category.active
            .for_facet(category.facet)
            .roots
            .where.not(id: category.id)
            .ordered
  end
end
