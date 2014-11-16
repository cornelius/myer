require "net/http"
require "json"
require "xdg"
require "open3"
require "tempfile"
require "securerandom"

def require_myer(file)
  require_relative("myer/#{file}")
end

require_myer "version"

require_myer "exceptions"
require_myer "config"
require_myer "xinput_parser"
require_myer "cli_controller"
require_myer "admin_cli_controller"
require_myer "crypto"
require_myer "ticket"
require_myer "ticket_store"
require_myer "proc_net_parser"
require_myer "content"
require_myer "plot"
require_myer "api"
