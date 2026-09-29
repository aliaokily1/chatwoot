# Elkheta: brand the installation as "Elkheta Class" (browser title, emails, login page).
# Only replaces the stock "Chatwoot" value, so a name set later from Super Admin is kept.
class SetElkhetaInstallationName < ActiveRecord::Migration[7.1]
  def up
    config = InstallationConfig.find_by(name: 'INSTALLATION_NAME')
    return if config.blank? || config.value != 'Chatwoot'

    config.update!(value: 'Elkheta Class')
    GlobalConfig.clear_cache
  end

  def down; end
end
