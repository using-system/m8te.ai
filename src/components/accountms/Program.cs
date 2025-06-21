using System.Text.Json;
using System.Text.Json.Serialization;
using accountms.Extensions.Controllers.v1;
using accountms.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateSlimBuilder(args);

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default);
});

// Register services
builder.Services.AddSingleton<JsonSerializerContext>(AppJsonSerializerContext.Default);
builder.Services.AddHttpClient<IKeycloakService, KeycloakService>();
builder.Services.AddScoped<IKeycloakService, KeycloakService>();

// Configure JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var keycloakUrl = builder.Configuration["KEYCLOAK_URL"] ?? "https://dev-connect.m8te.ai";
        var realm = builder.Configuration["KEYCLOAK_REALM"] ?? "m8t";

        options.Authority = $"{keycloakUrl}/realms/{realm}";
        options.Audience = "account";
        options.RequireHttpsMetadata = true;

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = false,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(5)
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

// Enable authentication & authorization
app.UseAuthentication();
app.UseAuthorization();

app.MapApiKeyControllerV1();

app.MapGet("/health", () => Results.Ok(new HealthStatus("ok", DateTimeOffset.UtcNow)))
   .WithName("HealthCheck");

app.Run();

[JsonSerializable(typeof(accountms.Extensions.Controllers.v1.ApiKey[]))]
[JsonSerializable(typeof(accountms.Extensions.Controllers.v1.ApiKey))]
[JsonSerializable(typeof(HealthStatus))]
[JsonSerializable(typeof(accountms.Services.KeycloakClient))]
[JsonSerializable(typeof(accountms.Services.KeycloakClient[]))]
[JsonSerializable(typeof(List<accountms.Services.KeycloakClient>))]
[JsonSerializable(typeof(JsonElement))]
[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
internal partial class AppJsonSerializerContext : JsonSerializerContext
{

}

public record HealthStatus(string status, DateTimeOffset utc);