using gateway.host;
using Ocelot.DependencyInjection;
using Ocelot.Middleware;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Configure JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer("Bearer", options =>
    {
        var keycloakUrl = builder.Configuration["KEYCLOAK_URL"]
            ?? throw new ArgumentException("KEYCLOAK_URL environment variable is required");
        var realm = builder.Configuration["KEYCLOAK_REALM"]
            ?? throw new ArgumentException("KEYCLOAK_REALM environment variable is required");

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

builder.Services.AddOpenTelemetry()
    .WithMetrics(metrics =>
    {
        metrics
            .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(Constants.SERVICE_NAME))
            .AddAspNetCoreInstrumentation()
            .AddRuntimeInstrumentation()
            .AddProcessInstrumentation()
            .AddOtlpExporter(opt =>
            {
                opt.Endpoint = new Uri(Constants.OTLP_ENDPOINT_URL);
                opt.Protocol = OpenTelemetry.Exporter.OtlpExportProtocol.Grpc;
            });
    })
    .WithTracing(tracing =>
    {
        tracing
            .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(Constants.SERVICE_NAME))
            .AddAspNetCoreInstrumentation()
            .AddOtlpExporter(opt =>
            {
                opt.Endpoint = new Uri(Constants.OTLP_ENDPOINT_URL);
                opt.Protocol = OpenTelemetry.Exporter.OtlpExportProtocol.Grpc;
            });
    });

builder.Configuration
    .SetBasePath(builder.Environment.ContentRootPath)
    .AddOcelot();
builder.Services
    .AddOcelot(builder.Configuration);

var app = builder.Build();

// Enable authentication & authorization
app.UseAuthentication();
app.UseAuthorization();

await app.UseOcelot();
await app.RunAsync();