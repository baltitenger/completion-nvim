local vim = vim
local validate = vim.validate
local api = vim.api
local util = require 'completion.util'
local M = {}

----------------------
--  signature help  --
----------------------
M.autoOpenSignatureHelp = function()
  local pos = api.nvim_win_get_cursor(0)
  local line = api.nvim_get_current_line()
  local line_to_cursor = line:sub(1, pos[2])
  if vim.lsp.buf_get_clients() == nil then return end

  local triggered
  for _, value in pairs(vim.lsp.buf_get_clients(0)) do
    if value.resolved_capabilities.signature_help == false or
      value.server_capabilities.signatureHelpProvider == nil then
      return
    end

    line_to_cursor = vim.trim(line_to_cursor)
    triggered = util.checkTriggerCharacter(line_to_cursor,
      value.server_capabilities.signatureHelpProvider.triggerCharacters)
  end

  if triggered then
    -- overwrite signature help here to disable "no signature help" message
    local params = vim.lsp.util.make_position_params()
    vim.lsp.buf_request(0, 'textDocument/signatureHelp', params,
        function(err, method, result, client_id, bufnr)
      local client = vim.lsp.get_client_by_id(client_id)
      local handler = client and client.handlers['textDocument/signatureHelp']
      if handler then
        handler(err, method, result, client_id, bufnr)
        return
      end
      if not (result and result.signatures and result.signatures[1]) then
        return
      end
      local lines = vim.lsp.util.convert_signature_help_to_markdown_lines(result)
      lines = vim.lsp.util.trim_empty_lines(lines)
      if vim.tbl_isempty(lines) then
        return
      end
      local syntax = api.nvim_buf_get_option(bufnr, 'syntax')
      local p_bufnr, _ = vim.lsp.util.focusable_preview(method, function()
        return lines, vim.lsp.util.try_trim_markdown_code_blocks(lines)
      end)
      api.nvim_buf_set_option(p_bufnr, 'syntax', syntax)
      -- setup a variable for floating window, fix #223
      vim.api.nvim_buf_set_var(p_bufnr, 'lsp_floating', true)
    end)
  end
end


return M
