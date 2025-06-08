using System.Text.Json.Serialization;

var builder = WebApplication.CreateSlimBuilder(args);

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default);
});
builder.Services.AddControllers();

var app = builder.Build();

app.MapControllers();

app.Run();

[JsonSerializable(typeof(ApiKey[]))]
[JsonSerializable(typeof(ApiKey))]
internal partial class AppJsonSerializerContext : JsonSerializerContext
{

}
