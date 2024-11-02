using COB.Scheduler;
using COB.Application.Extensions;
using COB.Scheduler.Jobs;
using System.Reflection;
using COB.Domain.Configuration;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.Configure<MongoSettings>(builder.Configuration.GetSection(nameof(MongoSettings)));
builder.Services.AddCobServices();
builder.Services.AddHttpClient();

var jobTypes = Assembly.GetExecutingAssembly()
                           .GetTypes()
                           .Where(t => t.IsSubclassOf(typeof(JobBase)) && !t.IsAbstract);

// Enregistre chaque type de JobBase comme service
foreach (var jobType in jobTypes)
{
    builder.Services.AddSingleton(typeof(JobBase), jobType);
}
builder.Services.AddHostedService<SchedulerService>();

var host = builder.Build();
host.Services.UseCobServices();
host.Run();
