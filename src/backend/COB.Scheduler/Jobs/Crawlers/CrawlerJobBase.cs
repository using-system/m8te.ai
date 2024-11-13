using COB.Domain.Reports;

namespace COB.Scheduler.Jobs.Crawlers;

public abstract class CrawlerJobBase(IServiceScopeFactory serviceScopeFactory, ILogger<DansMaRueCrawlerJob> logger) 
    : JobBase(serviceScopeFactory, logger)
{
    protected abstract ReportSource Source { get; }

    protected abstract string ExternalIdPrefix { get; }
}
