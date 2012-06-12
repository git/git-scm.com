module ApplicationHelper

  TAGLINES = %w{
    fast-version-control
    everything-is-local
    distributed-even-if-your-workflow-isnt
    local-branching-on-the-cheap
    distributed-is-the-new-centralized
  }

  def partial(part)
    render part
  end

  def random_tagline
    content_tag(:em, '-' * 2) + TAGLINES.sample
  end

  def latest_version
    @version ||= Version.latest_version
    @version.name
  end

  def latest_release_date
    @version ||= Version.latest_version
    '(' + @version.committed.strftime("%Y-%m-%d") + ')'
  end

  def latest_relnote_url
    "https://raw.github.com/git/git/master/Documentation/RelNotes/#{self.latest_version}.txt"
  end

  # overriding this because we're not using asset pipeline for images,
  # but jason is using image_tag
  #def image_tag(image)
  #  raw "<img src=\"/images/" + image  + "\"/>"
  #end

end
