/// Configuration for the LangGraph Agent backend.
///
/// Uses environment variables passed via --dart-define for security.
/// Falls back to hardcoded values for development.
class AgentConfig {
  AgentConfig._();

  /// Agent backend base URL.
  ///
  /// Pass via: --dart-define=AGENT_BASE_URL=your_url
  static const String baseUrl = String.fromEnvironment(
    'AGENT_BASE_URL',
    defaultValue: 'https://smartchat-agent.onrender.com',
  );

  /// Full endpoint for the agent API.
  static String get agentEndpoint => '$baseUrl/agent';

  /// Returns true if using a custom URL (not the default).
  static bool get isConfigured {
    return baseUrl != 'https://smartchat-agent.onrender.com' ||
        const String.fromEnvironment('AGENT_BASE_URL').isNotEmpty;
  }
}
