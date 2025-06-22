using accountms.Services;
using System.Security.Claims;

namespace accountms.Extensions.Controllers.v1;

public static class ApiKeyControllerExtensions
{
    public static void MapApiKeyControllerV1(this WebApplication app)
    {
        var api = app.MapGroup("/api/v1/apikey").RequireAuthorization();

        api.MapGet("/", async (ClaimsPrincipal user, IKeycloakService keycloakService) =>
        {
            var userId = GetUserIdFromClaims(user);
            if (string.IsNullOrEmpty(userId))
                return Results.Unauthorized();

            // Check if user already has an API key
            var existingClients = await keycloakService.GetClientsAsync(userId);
            var existingClient = existingClients.FirstOrDefault();

            if (existingClient != null)
            {
                // Return existing API key
                var existingSecret = await keycloakService.GetClientSecretAsync(existingClient.clientId, userId);
                var existingApiKey = new ApiKey(
                    existingClient.name ?? "Default API Key",
                    existingClient.clientId,
                    existingSecret,
                    null
                );
                return Results.Ok(existingApiKey);
            }

            // Create a new API key
            var clientId = await keycloakService.CreateClientAsync("Default API Key", userId, "Auto-generated API key");

            if (string.IsNullOrEmpty(clientId))
                return Results.Problem("Failed to create API key");

            var secret = await keycloakService.GetClientSecretAsync(clientId, userId);
            var newApiKey = new ApiKey("Default API Key", clientId, secret, null);

            return Results.Ok(newApiKey);
        });
    }

    private static string? GetUserIdFromClaims(ClaimsPrincipal user)
    {
        return user.FindFirst("sub")?.Value ??
               user.FindFirst(ClaimTypes.NameIdentifier)?.Value ??
               user.FindFirst("preferred_username")?.Value;
    }
}

public record ApiKey(
    string name,
    string clientId,
    string clientSecret,
    DateTimeOffset? expiration
);

