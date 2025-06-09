using accountms.Services;
using System.Security.Claims;

namespace accountms.Extensions.Controllers.v1;

public static class ApiKeysControllerExtensions
{
    public static void MapApiKeysControllerV1(this WebApplication app)
    {
        var api = app.MapGroup("/api/v1/apikeys").RequireAuthorization();

        api.MapGet("/", async (ClaimsPrincipal user, IKeycloakService keycloakService) =>
        {
            var userId = GetUserIdFromClaims(user);
            if (string.IsNullOrEmpty(userId))
                return Results.Unauthorized();

            var clients = await keycloakService.GetClientsAsync(userId);

            var apiKeys = clients.Select(c => new ApiKey(
                c.name ?? c.clientId,
                c.clientId,
                "***",
                null
            )).ToList();

            return Results.Ok(apiKeys);
        });

        api.MapGet("/{clientId}", async (string clientId, ClaimsPrincipal user, IKeycloakService keycloakService) =>
        {
            var userId = GetUserIdFromClaims(user);
            if (string.IsNullOrEmpty(userId))
                return Results.Unauthorized();

            var client = await keycloakService.GetClientAsync(clientId, userId);

            if (client == null)
                return Results.NotFound();

            var apiKey = new ApiKey(
                client.name ?? client.clientId,
                client.clientId,
                "***",
                null
            );

            return Results.Ok(apiKey);
        });

        api.MapPost("/", async (ApiKeyCreateRequest request, ClaimsPrincipal user, IKeycloakService keycloakService) =>
        {
            var userId = GetUserIdFromClaims(user);
            if (string.IsNullOrEmpty(userId))
                return Results.Unauthorized();

            var clientId = await keycloakService.CreateClientAsync(request.name, userId, request.description);

            if (string.IsNullOrEmpty(clientId))
                return Results.BadRequest("Failed to create API key");

            var secret = await keycloakService.GetClientSecretAsync(clientId, userId);

            var apiKey = new ApiKey(request.name, clientId, secret, null);
            return Results.Created($"/api/v1/apikeys/{clientId}", apiKey);
        });

        api.MapDelete("/{clientId}", async (string clientId, ClaimsPrincipal user, IKeycloakService keycloakService) =>
        {
            var userId = GetUserIdFromClaims(user);
            if (string.IsNullOrEmpty(userId))
                return Results.Unauthorized();

            var success = await keycloakService.DeleteClientAsync(clientId, userId);
            return success ? Results.NoContent() : Results.NotFound();
        });
    }

    private static string? GetUserIdFromClaims(ClaimsPrincipal user)
    {
        return user.FindFirst("sub")?.Value ??
               user.FindFirst(ClaimTypes.NameIdentifier)?.Value ??
               user.FindFirst("preferred_username")?.Value;
    }
}

public record ApiKeyCreateRequest(string name, string? description);

public record ApiKey(
    string name,
    string clientId,
    string clientSecret,
    DateTimeOffset? expiration
);

