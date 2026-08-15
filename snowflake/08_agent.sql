-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Sukuk Portfolio Analytics
-- ============================================================================
USE DATABASE ISLAMIC_SUKUK_PORTFOLIO;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.SUKUK_PORTFOLIO_AGENT
  COMMENT = 'Sukuk Portfolio Analytics AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'ISLAMIC_SUKUK_PORTFOLIO.APP.SUKUK_PORTFOLIO_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'ISLAMIC_SUKUK_PORTFOLIO.SEARCH.PORTFOLIO_DOCS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Islamic Finance information')
  )
  SYSTEM_PROMPT = 'You are the Sukuk Portfolio Intelligence Agent for a Malaysian Islamic fund managing RM 2.3B in Sukuk holdings across 4 structures.';
