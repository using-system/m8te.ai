using COB.Scheduler.Jobs;

namespace COB.Scheduler;

public class SchedulerService(IEnumerable<JobBase> jobs, ILogger<SchedulerService> logger) : BackgroundService
{
    protected async override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var jobTasks = jobs.Select(async job =>
        {
            logger.LogInformation("Starting job {jobName}", job.GetType().Name);
            await job.StartAsync(stoppingToken);
        });

        await Task.WhenAll(jobTasks);
    }
}
