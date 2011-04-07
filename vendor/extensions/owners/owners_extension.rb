class OwnersExtension < Radiant::Extension
  version "0.5"
  description "Tracks who owns the content on each page"
  url "http://github.com/mlanza/radiant-owners-extension"

  def activate
    admin.page.index.add :sitemap_head, 'owner_th'
    admin.page.index.add :node, 'owner_td'
  end

  def deactivate
  end
end

