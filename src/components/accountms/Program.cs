using System.Text.Json.Serialization;
using accountms.Extensions.Controllers.v1;

var builder = WebApplication.CreateSlimBuilder(args);

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default);
});

var app = builder.Build();

app.MapApiKeysControllerV1();

app.MapGet("/health", () => Results.Ok(new accountms.Model.HealthStatus("ok", DateTimeOffset.UtcNow)))
   .WithName("HealthCheck");

app.Run();

[JsonSerializable(typeof(accountms.Model.v1.ApiKey[]))]
[JsonSerializable(typeof(accountms.Model.v1.ApiKey))]
[JsonSerializable(typeof(accountms.Model.HealthStatus))]
internal partial class AppJsonSerializerContext : JsonSerializerContext
{

}
