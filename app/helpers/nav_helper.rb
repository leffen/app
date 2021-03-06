module NavHelper
  def active_nav?(nav = "home")
    return "active" if nav == @active_nav
  end

  def hide_nav?(nav = "home")
    return "hide" if nav == @active_nav
  end

  def back_path(fallback)
    if request.referer.blank?
      fallback
    else
      :back
    end
  end
end
