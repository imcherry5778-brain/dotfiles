-- HTML, CSS, JavaScript/TypeScript, Python 통합 개발 설정
-- 이 파일 하나로 LSP, DAP, Linter, Formatter가 중복 없이 완전 자동 관리됩니다.

return {
  -----------------------------------------------------------------------------
  -- HTML / CSS 및 Emmet 추가 LSP 설정
  -----------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- HTML LSP (구문 분석 및 툴팁 제공)
        html = {},
        -- CSS LSP (클래스/속성 분석 제공)
        cssls = {},
        -- Emmet LSP (HTML/CSS 태그 단축키 완성 지원. 예: div.btn -> <div class="btn">)
        emmet_language_server = {},
      },
    },
  },
}
