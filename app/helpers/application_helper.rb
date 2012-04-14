module ApplicationHelper

  def partial(part)
    render part
  end

  def random_tagline
    tags = ['fast-version-control',
     'everything-is-local',
     'distributed-even-if-your-workflow-isnt',
     'local-branching-on-the-cheap',
     'not-your-daddys-version-control',
     'distributed-is-the-new-centralized' ]
    mtag = tags[rand(tags.length)]
    "<em>--</em>#{mtag}"
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

end
