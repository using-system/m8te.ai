namespace COB.Domain.Reports;

public interface IReportRepository : IDocumentRepository<ReportDocument>
{
    IQueryable<ReportDocument> QueryReports(double latitude, double longitude, double radius);
}
