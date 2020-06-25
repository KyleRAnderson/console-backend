module Api::V1::PaginationOrdering
  DEFAULT_PER_PAGE = 40

  # If key is provided, then the number of pages will be included in the return value
  # and the paginated models will be in the return value under the key.
  def paginated(models, key: nil)
    page = fix_num(params[:page], 1)
    per_page = fix_num(params[:per_page], DEFAULT_PER_PAGE)
    num_pages = (models.size.to_f / per_page.to_i).ceil if key
    paginated = models.paginate(page: page, per_page: per_page)
    { key => paginated, num_pages: num_pages } if key
  end

  # Key is the access point in the hash for the models. If no key provided
  # then it is assumed that models itself contains all the models.
  def ordered(models, key: nil)
    orders = ordering_params
    unless orders&.empty?
      if key
        models[key] = models[key].order(**ordering_params)
      else
        models = models.order(**ordering_params)
      end
    end
    models
  end

  def paginated_ordered(models, **kwargs)
    paginated(ordered(models), **kwargs)
  end

  private

  def fix_num(str, default)
    unless str&.match(/^[0-9]+$/)
      str = default
    end
    str
  end
end
