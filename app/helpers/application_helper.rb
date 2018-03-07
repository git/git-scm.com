require 'iso8601'

module ApplicationHelper

  def sidebar_link_options(section)
    if %w( about documentation reference book videos
           external-links downloads guis logos community
          ).include?(@section) && @section == section
      {class: "active"}
    else
      {}
    end
  end

  def partial(part)
    render part
  end

  def random_tagline
    content_tag(:em, '-' * 2) + Gitscm::TAGLINES.sample
  end

  def latest_version
    begin
    @version ||= Version.latest_version
    @version.name
    rescue
      ""
    end
  end

  def latest_mac_installer
    @mac_installer ||= Download.latest_for 'mac'
    @mac_installer ? @mac_installer.version.name : ''
  end

  def latest_win_installer
    @win_installer ||= Download.latest_for 'windows32'
    @win_installer ? @win_installer.version.name : ''
  end

  def latest_release_date
    begin
    @version ||= Version.latest_version
    '(' + @version.committed.strftime("%Y-%m-%d") + ')'
    rescue
      ""
    end
  end

  def latest_relnote_url
    "https://raw.github.com/git/git/master/Documentation/RelNotes/#{self.latest_version}.txt"
  end

  # overriding this because we're not using asset pipeline for images,
  # but jason is using image_tag
  def image_tag(image, options = {})
    out = "<img src='/images/" + image + "'"
    out += " width='" + options[:width].to_s + "'" if options[:width]
    out += " height='" + options[:height].to_s + "'" if options[:height]
    out += " />"
    raw out
  end

  def banner(id, options = {}, &content)
    dismissible = options.fetch(:dismissible, false)
    duration = options.fetch(:duration, '')
    class_name = options.fetch(class_name, '')

    if dismissible and not duration.empty?
      begin
        duration = ISO8601::Duration.new(duration).to_seconds.round * 1000
      rescue
        duration = ''
      end
    end

    config = {
      :id => "banner-#{id}",
      :duration => duration
    }

    out = "<div class=\"banner-message #{class_name}\" id=\"#{config[:id]}\">"
    out += capture(&content)

    if dismissible
      js = <<-END_JS
      <script>
        (function(config) {
          var banner = document.getElementById(config.id);
          var button = banner.querySelector('.dismiss');
          var dismissed = parseInt(localStorage.getItem(config.id),10);
          var duration = config.duration;

          if (dismissed && (!duration || (dismissed > Date.now() - duration))) {
            return banner.parentElement.removeChild(banner);
          }

          button && button.addEventListener('click', function() {
            localStorage.setItem(config.id, Date.now());
            return banner.parentElement.removeChild(banner);
          });
        })(#{JSON.generate(config)});
      </script>
      END_JS

      label = "Dismiss this message"
      button = <<-END_BUTTON
        <button type="button"
                class="dismiss"
                aria-controls="#{config[:id]}"
                aria-label="#{label}">&times;</button>
      END_BUTTON
      out += button
      out += js
    end

    out += "</div>"

    raw out
  end

end
