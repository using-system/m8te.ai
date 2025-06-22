using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text;
using System.Security.Claims;

namespace accountms.Services;

public interface IKeycloakService
{
    Task<List<KeycloakClient>> GetClientsAsync(string? userId = null);
    Task<string> CreateClientAsync(string name, string userId, string? description = null);
    Task<string> GetClientSecretAsync(string clientId, string? userId = null);
}

public class KeycloakService : IKeycloakService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _config;
    private readonly JsonSerializerContext _jsonContext;
    private readonly string _keycloakUrl;
    private readonly string _realm;

    public KeycloakService(HttpClient httpClient, IConfiguration config, JsonSerializerContext jsonContext)
    {
        _httpClient = httpClient;
        _config = config;
        _jsonContext = jsonContext;
        _keycloakUrl = _config["KEYCLOAK_URL"] ?? "https://dev-connect.m8te.ai";
        _realm = _config["KEYCLOAK_REALM"] ?? "m8t";
    }

    public async Task<List<KeycloakClient>> GetClientsAsync(string? userId = null)
    {
        await SetAuthorizationHeaderAsync();

        var response = await _httpClient.GetAsync($"{_keycloakUrl}/admin/realms/{_realm}/clients?clientId=api-*");

        if (!response.IsSuccessStatusCode)
            return new List<KeycloakClient>();

        var json = await response.Content.ReadAsStringAsync();
        var allClients = JsonSerializer.Deserialize(json, typeof(List<KeycloakClient>), _jsonContext) as List<KeycloakClient>
               ?? new List<KeycloakClient>();

        // Filter by owner if userId is provided
        if (!string.IsNullOrEmpty(userId))
        {
            return allClients.Where(c => c.attributes?.ContainsKey("owner") == true &&
                                        c.attributes["owner"].FirstOrDefault() == userId).ToList();
        }

        return allClients;
    }

    public async Task<string> CreateClientAsync(string name, string userId, string? description = null)
    {
        await SetAuthorizationHeaderAsync();

        var clientId = $"api-{userId}-{Guid.NewGuid():N}";
        var client = new
        {
            clientId = clientId,
            name = name,
            description = description,
            enabled = true,
            serviceAccountsEnabled = true,
            standardFlowEnabled = false,
            implicitFlowEnabled = false,
            directAccessGrantsEnabled = false,
            protocol = "openid-connect",
            attributes = new Dictionary<string, string>
            {
                { "owner", userId }
            }
        };

        var json = JsonSerializer.Serialize(client, typeof(object), _jsonContext);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _httpClient.PostAsync($"{_keycloakUrl}/admin/realms/{_realm}/clients", content);

        return response.IsSuccessStatusCode ? clientId : string.Empty;
    }

    public async Task<string> GetClientSecretAsync(string clientId, string? userId = null)
    {
        var clients = await GetClientsAsync(userId);
        var client = clients.FirstOrDefault(c => c.clientId == clientId);
        if (client == null) return string.Empty;

        await SetAuthorizationHeaderAsync();

        var response = await _httpClient.GetAsync($"{_keycloakUrl}/admin/realms/{_realm}/clients/{client.id}/client-secret");

        if (!response.IsSuccessStatusCode)
            return string.Empty;

        var json = await response.Content.ReadAsStringAsync();
        var secretResponse = JsonSerializer.Deserialize(json, typeof(JsonElement), _jsonContext);

        if (secretResponse is JsonElement element)
            return element.TryGetProperty("value", out var value) ? value.GetString() ?? string.Empty : string.Empty;

        return string.Empty;
    }

    private async Task SetAuthorizationHeaderAsync()
    {
        var token = await GetServiceAccountTokenAsync();
        _httpClient.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
    }

    private async Task<string> GetServiceAccountTokenAsync()
    {
        var clientId = _config["KEYCLOAK_CLIENT_ID"]
            ?? throw new InvalidOperationException("Keycloak client ID not configured");
        var clientSecret = _config["KEYCLOAK_CLIENT_SECRET"]
            ?? throw new InvalidOperationException("Keycloak client secret not configured");

        var tokenRequest = new FormUrlEncodedContent(new[]
        {
            new KeyValuePair<string, string>("grant_type", "client_credentials"),
            new KeyValuePair<string, string>("client_id", clientId),
            new KeyValuePair<string, string>("client_secret", clientSecret)
        });

        var response = await _httpClient.PostAsync($"{_keycloakUrl}/realms/{_realm}/protocol/openid-connect/token", tokenRequest);

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException("Failed to authenticate with Keycloak service account");

        var json = await response.Content.ReadAsStringAsync();
        var tokenResponse = JsonSerializer.Deserialize(json, typeof(JsonElement), _jsonContext);

        if (tokenResponse is JsonElement element)
            return element.TryGetProperty("access_token", out var token)
                ? token.GetString() ?? string.Empty
                : string.Empty;

        return string.Empty;
    }

}

public record KeycloakClient(
    string id,
    string clientId,
    string? name,
    string? description,
    Dictionary<string, string[]>? attributes
);
