-- jdtls needs a recent JDK (config/jdk.lua: JDTLS_MIN). Keep the machine's default `java` untouched
-- and point only jdtls at a suitable JDK: $JDTLS_JAVA_HOME first, then the usual install locations.
return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local jdk = require("config.jdk")
      local default = jdk.default()
      if default ~= "" and jdk.major(default) >= jdk.JDTLS_MIN then
        return
      end
      local java = jdk.find_for_jdtls()
      if java then
        opts.cmd = opts.cmd or {}
        table.insert(opts.cmd, "--java-executable=" .. java)
      else
        vim.schedule(function()
          vim.notify(
            string.format(
              "jdtls needs JDK %d or newer: install one (README) or set $JDTLS_JAVA_HOME",
              jdk.JDTLS_MIN
            ),
            vim.log.levels.WARN
          )
        end)
      end
    end,
  },
}
