module SonarHelper
  def render_rating(value)
    return "—" if value.blank?

    css_class = "sonar-rating sonar-rating--#{value.downcase}"
    tag.span(value, class: css_class)
  end
end
