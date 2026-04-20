class FixSakuraconDoubleYearSlug < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE events SET slug = 'sakuracon-2026' WHERE slug = 'sakuracon-2026-2026'"
  end

  def down
    execute "UPDATE events SET slug = 'sakuracon-2026-2026' WHERE slug = 'sakuracon-2026'"
  end
end
