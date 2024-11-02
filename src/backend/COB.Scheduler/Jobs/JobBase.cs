namespace COB.Scheduler.Jobs;

public abstract class JobBase(IServiceScopeFactory serviceScopeFactory, ILogger logger)
{
    public async Task StartAsync(CancellationToken stoppingToken)
    {
        while(!stoppingToken.IsCancellationRequested)
        {
            await this.InternalExecute();

            var dateNow = DateTime.Now.ToUniversalTime();
            var nextOccurrenceDate = Cronos.CronExpression.Parse(this.CronExpression).GetNextOccurrence(dateNow);

            if(nextOccurrenceDate == null)
            {
                await Task.Delay(60000);
                continue;
            }

            await Task.Delay((int)(nextOccurrenceDate.Value - dateNow).TotalMilliseconds);
        }
    }

    internal async Task InternalExecute()
    {
        try
        {
            using (var scope = serviceScopeFactory.CreateScope())
            {
                await this.ExecuteAsync(scope);
            }
        }
        catch (Exception exc)
        {
            logger.LogError(exc, exc.Message);
        }
    }

    protected abstract Task ExecuteAsync(IServiceScope scope);

    protected abstract string CronExpression { get; }
}
