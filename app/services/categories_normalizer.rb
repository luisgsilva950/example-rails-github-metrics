# frozen_string_literal: true

# Normalizes JIRA bug categories by applying prefix/project rules.
# Returns a hash with :normalized (final labels), :added, and :removed arrays.
class CategoriesNormalizer
  def initialize(categories)
    @categories = Array(categories)
    @labels_to_add = []
    @labels_to_remove = []
  end

  def call
    apply_per_category_rules
    apply_project_rules
    apply_label_replacements

    merged = (@categories - @labels_to_remove + @labels_to_add).uniq
    merged = fix_duplicated_prefixes(merged)

    {
      normalized: merged,
      added: @labels_to_add.uniq,
      removed: @labels_to_remove.uniq,
      changed?: @labels_to_add.any? || @labels_to_remove.any?
    }
  end

  private

  def apply_per_category_rules
    @categories.each do |cat|
      # cw_elements_ -> mfe:cw_elements_*
      if cat.start_with?("cw_elements_")
        mfe_label = "mfe:#{cat}"
        unless @categories.include?(mfe_label)
          @labels_to_remove << cat
          @labels_to_add << mfe_label
        end
      end

      # *_api (without feature: prefix) -> feature:*_api
      if cat.end_with?("_api") && !cat.start_with?("feature:")
        feature_label = "feature:#{cat}"
        unless @categories.include?(feature_label)
          @labels_to_remove << cat
          @labels_to_add << feature_label
        end
      end

      # data_integrity_* -> data_integrity_reason:*
      if cat.start_with?("data_integrity_") && !cat.start_with?("data_integrity_reason:")
        suffix = cat.sub("data_integrity_", "")
        new_label = "data_integrity_reason:#{suffix}"
        unless @categories.include?(new_label)
          @labels_to_remove << cat
          @labels_to_add << new_label
        end
      end

      # map_integrator* (without feature: prefix) -> feature:map_integrator*
      if cat.start_with?("map_integrator") && !cat.start_with?("feature:")
        feature_label = "feature:#{cat}"
        unless @categories.include?(feature_label)
          @labels_to_remove << cat
          @labels_to_add << feature_label
        end
      end

      # cw_farm_settings* (without feature: prefix) -> feature:cw_farm_settings*
      if cat.start_with?("cw_farm_settings") && !cat.start_with?("feature:")
        feature_label = "feature:#{cat}"
        unless @categories.include?(feature_label)
          @labels_to_remove << cat
          @labels_to_add << feature_label
        end
      end
    end
  end

  def apply_project_rules
    # cw_elements -> project:cw_elements
    if @categories.any? { |c| c.start_with?("cw_elements") } && !@categories.include?("project:cw_elements")
      @labels_to_add << "project:cw_elements"
    end

    # project:cw-elements -> project:cw_elements
    if @categories.include?("project:cw-elements")
      @labels_to_remove << "project:cw-elements"
      @labels_to_add << "project:cw_elements"
    end

    # cw_farm_settings -> project:cw_farm_settings
    if @categories.any? { |c| c.start_with?("cw_farm_settings") } && !@categories.include?("project:cw_farm_settings")
      @labels_to_add << "project:cw_farm_settings"
    end

    # map_integrator or feature:map_integrator -> project:map_integrator
    if @categories.any? { |c| c.start_with?("map_integrator") || c.start_with?("feature:map_integrator") } && !@categories.include?("project:map_integrator")
      @labels_to_add << "project:map_integrator"
    end
  end

  def apply_label_replacements
    # Strix -> project:strix
    if @categories.include?("Strix") && !@categories.include?("project:strix")
      @labels_to_remove << "Strix"
      @labels_to_add << "project:strix"
    end

    # cup -> project:cup
    if @categories.include?("cup") && !@categories.include?("project:cup")
      @labels_to_remove << "cup"
      @labels_to_add << "project:cup"
    end
  end

  def fix_duplicated_prefixes(labels)
    labels.map! do |label|
      if label.match?(/\A(feature:){2,}/)
        label.gsub(/\A(feature:)+/, "feature:")
      else
        label
      end
    end
    labels.uniq!
    labels
  end
end
