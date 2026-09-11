# MCP server for MCP directories (Glama, Smithery): starts over stdio and answers introspection.
# The server reads Claude Code transcripts from ~/.claude*/projects; in an empty container it reports zero sessions.
FROM python:3.12-slim
RUN pip install --no-cache-dir contextburn==0.2.1
ENTRYPOINT ["contextburn", "mcp"]
