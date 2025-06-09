using accountms.Model.v1;

namespace accountms.Extensions.Controllers.v1;

public static class ApiKeysControllerExtensions
{
    public static void MapApiKeysControllerV1(this WebApplication app)
    {
        var apiKeys = new List<ApiKey>
        {
            new ApiKey("Test Key", "client1", "secret1", DateTimeOffset.UtcNow.AddYears(1))
        };

        var api = app.MapGroup("/api/v1/apikeys");

        api.MapGet("/", () => Results.Ok(apiKeys));

        api.MapGet("/{clientId}", (string clientId) =>
        {
            var key = apiKeys.FirstOrDefault(k => k.ClientId == clientId);
            return key is null ? Results.NotFound() : Results.Ok(key);
        });

        api.MapPost("/", (ApiKey newKey) =>
        {
            var maxId = apiKeys
                .Select(k => int.TryParse(k.ClientId, out var id) ? id : 0)
                .DefaultIfEmpty(0)
                .Max();
            var createdKey = new ApiKey(newKey.Name, (maxId + 1).ToString(), newKey.ClientSecret, newKey.Expiration);
            apiKeys.Add(createdKey);
            return Results.Created($"/api/v1/apikeys/{createdKey.ClientId}", createdKey);
        });

        api.MapDelete("/{clientId}", (string clientId) =>
        {
            var key = apiKeys.FirstOrDefault(k => k.ClientId == clientId);
            if (key is null) return Results.NotFound();
            apiKeys.Remove(key);
            return Results.NoContent();
        });
    }
}
